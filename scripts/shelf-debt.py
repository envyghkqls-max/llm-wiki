#!/usr/bin/env python3
"""shelf-debt.py — 정제 부채 계량 (서가로 못 올라간 source 가시화).

raw가 쌓이는 속도 > 정제되는 속도(역피라미드)를 숫자로 드러낸다.
도메인별로 (1) orphan source(다른 wiki가 안 가리킴) (2) 어떤 MOC에도 없는 source
(3) 승급 비율(MOC 등재 / 전체)을 출력하고, 정제 대기 작업 큐(오래된 것부터)를 만든다.

사용:
  python3 scripts/shelf-debt.py                 # 요약 + 도메인별 worklist
  python3 scripts/shelf-debt.py --worklist 30   # 도메인별 큐 길이
  python3 scripts/shelf-debt.py --emit-grandfather  # 현재 orphan source 슬러그를
                                                    # scripts/orphan-grandfathered.txt 로 기록
                                                    # (止血 게이트가 기존 부채는 grandfather)

종료코드 0 (정보성). 순수 계산 — 파일 읽기만, vault 미수정.
규칙 정본: AI-Sessions/wiki/playbooks/domain-knowledge-pipeline.md
"""
import os, re, sys, glob

VAULT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WIKI = os.path.join(VAULT, "AI-Sessions", "wiki")
SOURCES = os.path.join(WIKI, "sources")
DOMAINS = ["design", "content", "dev", "research", "automation"]
GRANDFATHER = os.path.join(VAULT, "scripts", "orphan-grandfathered.txt")

LINK_RE = re.compile(r"\[\[([^\]]+)\]\]")
DOMAIN_RE = re.compile(r"domain/([a-z]+)")
DATE_RE = re.compile(r"(\d{4}-\d{2}-\d{2})")


def read(path):
    try:
        return open(path, encoding="utf-8").read()
    except OSError:
        return ""


def frontmatter(text):
    parts = text.split("---", 2)
    return parts[1] if len(parts) >= 3 and parts[0].strip() == "" else ""


def wiki_md_files():
    out = []
    for f in glob.glob(os.path.join(WIKI, "**", "*.md"), recursive=True):
        if "/legacy/" in f or "/_status/" in f:
            continue
        out.append(f)
    return out


def main():
    worklen = 20
    emit_gf = "--emit-grandfather" in sys.argv
    if "--worklist" in sys.argv:
        i = sys.argv.index("--worklist")
        if i + 1 < len(sys.argv):
            worklen = int(sys.argv[i + 1])

    files = wiki_md_files()

    # 1) 전 wiki에서 [[link]] -> 그 링크를 포함한 파일 stem 집합 (inbound 계산용)
    referenced_by = {}  # target_stem -> set(source_stem)
    for f in files:
        stem = os.path.basename(f)[:-3]
        for m in LINK_RE.findall(read(f)):
            tgt = m.split("|")[0].split("#")[0].strip()
            referenced_by.setdefault(tgt, set()).add(stem)

    # 2) MOC 본문 (도메인별)
    moc_text = {}
    for d in DOMAINS:
        moc_text[d] = read(os.path.join(WIKI, "synthesis", f"{d}-moc.md"))

    # 3) source 페이지 순회
    src_files = sorted(glob.glob(os.path.join(SOURCES, "*.md")))
    stats = {d: {"total": 0, "orphan": [], "not_in_moc": []} for d in DOMAINS}
    no_domain = []
    orphan_all = []

    for f in src_files:
        stem = os.path.basename(f)[:-3]
        fm = frontmatter(read(f))
        doms = set(DOMAIN_RE.findall(fm))
        inbound = referenced_by.get(stem, set()) - {stem}
        is_orphan = len(inbound) == 0
        if is_orphan:
            orphan_all.append(stem)
        if not doms:
            no_domain.append(stem)
        for d in doms:
            if d not in stats:
                continue
            stats[d]["total"] += 1
            if is_orphan:
                stats[d]["orphan"].append(stem)
            if f"[[{stem}]]" not in moc_text.get(d, ""):
                stats[d]["not_in_moc"].append(stem)

    if emit_gf:
        with open(GRANDFATHER, "w", encoding="utf-8") as fh:
            fh.write("# orphan-grandfathered.txt — 止血 게이트가 면제하는 기존 orphan source\n")
            fh.write("# (vault-lint 검사12). 정제로 de-orphan되면 자동으로 무관해진다.\n")
            fh.write("# 생성: shelf-debt.py --emit-grandfather. 신규 추가 금지(새 source는 링크 강제).\n")
            for s in sorted(orphan_all):
                fh.write(s + "\n")
        print(f"✅ grandfather 기록: {len(orphan_all)}건 → {os.path.relpath(GRANDFATHER, VAULT)}")
        return 0

    def oldest(slugs):
        def key(s):
            m = DATE_RE.search(s)
            return m.group(1) if m else "9999"
        return sorted(slugs, key=key)

    print("=== 정제 부채 (서가로 못 올라간 source) ===\n")
    print(f"{'도메인':<12}{'source':>8}{'orphan':>8}{'MOC밖':>8}{'승급률':>9}")
    print("-" * 45)
    for d in DOMAINS:
        s = stats[d]
        t = s["total"]
        in_moc = t - len(s["not_in_moc"])
        ratio = f"{(in_moc / t * 100):.0f}%" if t else "—"
        print(f"{d:<12}{t:>8}{len(s['orphan']):>8}{len(s['not_in_moc']):>8}{ratio:>9}")
    print("-" * 45)
    print(f"orphan source 합계: {len(orphan_all)} | 도메인 태그 없는 source: {len(no_domain)}\n")

    print(f"=== 정제 대기 큐 (도메인별 오래된 것부터 최대 {worklen}) ===")
    print("→ 각 항목: 기존 concept/synthesis에 append하여 de-orphan (신규 orphan 금지)\n")
    for d in DOMAINS:
        queue = oldest(stats[d]["not_in_moc"])[:worklen]
        if not queue:
            continue
        print(f"[{d}] {len(stats[d]['not_in_moc'])}건 대기:")
        for s in queue:
            tag = " (orphan)" if s in stats[d]["orphan"] else ""
            print(f"  - {s}{tag}")
        print()
    if no_domain:
        print(f"[도메인 태그 없음] {len(no_domain)}건 — 먼저 domain/<slug> 부여:")
        for s in oldest(no_domain)[:worklen]:
            print(f"  - {s}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
