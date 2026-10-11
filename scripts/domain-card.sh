#!/usr/bin/env bash
# domain-card.sh — 도메인 1개의 "압축 컨텍스트 카드"를 라이브로 출력.
# 목적: 참조 시 vault 전체·index.md 전체를 읽지 않고, 한 명령으로 해당 도메인의
#       MOC + 정제수 토픽 요약 + 하네스 버전을 ~한 화면으로 받는다(토큰 최적화).
# 모든 내용을 실제 파일에서 derive (저장 사본 없음 → stale/환각 0).
# 사용: bash scripts/domain-card.sh <design|content|dev|research|automation>
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
W="$ROOT/AI-Sessions/wiki"
D="${1:-}"
case "$D" in design|content|dev|research|automation) ;; *)
  echo "usage: domain-card.sh <design|content|dev|research|automation>"; exit 2;; esac

summ() { # 파일의 frontmatter title + 첫 본문 한 줄(>) 추출
  local f="$1" t fl
  t=$(grep -m1 '^title:' "$f" 2>/dev/null | sed "s/^title: *//;s/^['\"]//;s/['\"]$//")
  fl=$(grep -m1 '^> ' "$f" 2>/dev/null | sed 's/^> *//')
  echo "  - $(basename "$f" .md): ${t:-?} — ${fl:-}"
}

echo "===== DOMAIN CARD: $D (live, $(basename "$ROOT")) ====="
UNRES=$(grep -c '| Unresolved |' "$W/_status/contested.md" 2>/dev/null || true)
echo "[contested 게이트] ${UNRES:-?}건 미해결 — 걸린 주제는 정본화 금지"
echo ""
echo "[MOC] wiki/synthesis/$D-moc.md"
[ -f "$W/synthesis/$D-moc.md" ] && grep -m1 '^> ' "$W/synthesis/$D-moc.md" | sed 's/^> /  /' || echo "  (없음)"
echo ""
echo "[정제수 reference]"; for f in "$W/knowledge/$D"/reference/*.md; do [ -f "$f" ] && summ "$f"; done 2>/dev/null
echo "[정제수 judgment]";  for f in "$W/knowledge/$D"/judgment/*.md;  do [ -f "$f" ] && summ "$f"; done 2>/dev/null
echo "[게이트]"; for f in "$W/knowledge/$D"/*quality-rubric*.md; do [ -f "$f" ] && summ "$f"; done 2>/dev/null
echo ""
echo "[하네스] wiki/harnesses/$D.md"
if [ -f "$W/harnesses/$D.md" ]; then
  echo "  version: $(grep -m1 '^version:' "$W/harnesses/$D.md" | sed 's/^version: *//')"
  echo "  스킬: $(grep -oE '`[a-z0-9][a-z0-9-]{3,}`' "$W/harnesses/$D.md" | grep -vE 'knowledge|provenance|standards|updated|version|fed_by|domain|quality-rubric|moc' | sort -u | head -6 | tr '\n' ' ')"
fi
echo ""
echo "→ 다음: 위 요약에서 필요한 토픽 1~3개만 '## 핵심' 읽기. 전체 본문은 핵심 부족 시만."
