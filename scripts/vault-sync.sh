#!/usr/bin/env bash
# vault-sync.sh — 옵시디언 vault의 git 동기화 단일 진입점 (다머신 맥락 공유).
#
# 왜 이 스크립트가 vault '안'에 있나:
#   git clone만 하면 이 스크립트도 따라온다. 즉 스킬/서브에이전트(운영 레이어)가
#   없는 깨끗한 머신에서도 `bash scripts/vault-sync.sh ...` 한 줄로 동기화된다.
#   raw-press / 옵시디언 저장 / 옵시디언 참조 / obsidian-curator 는 이 스크립트를 '호출만' 한다.
#   (로직은 한 곳, 나머지는 포인터 — 사본 드리프트 0)
#
# 동작:
#   pull              — 참조(reference) 전: 다른 머신 변경을 먼저 가져온다 (rebase+autostash).
#   push "<msg>" f... — 저장(save)/raw-press 후: 지정 파일만 스테이징 → 시크릿 게이트 → commit → pull --rebase → push.
#
# 보안 (1급 보안):
#   - `git add .` / `-A` 절대 안 함 — 호출자가 건드린 파일을 '명시'로만 스테이징.
#   - commit 전 staged diff를 '시크릿 값 패턴'으로 검사, 걸리면 commit 중단 + unstage.
#   - 토픽 단어(token/secret/key 등)는 이 지식 vault에서 정상 본문이라 게이트하지 않는다.
#     실제 '키 값 형태'만 차단한다(오탐 최소화, 진짜 유출만 차단).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || { echo "[vault-sync] vault 루트 진입 실패"; exit 1; }

has_origin() { git remote get-url origin >/dev/null 2>&1; }

# 시크릿 값 패턴 = 단일 정본(scripts/secret-patterns.sh)에서 source → 드리프트 0.
# FAIL-CLOSED: 패턴 정본이 없거나 비면 게이트가 무력화되므로 push를 막는다(조용한 통과=오염 금지).
if [ ! -f "$ROOT/scripts/secret-patterns.sh" ]; then
  echo "[vault-sync] ⛔ scripts/secret-patterns.sh 없음 — 시크릿 게이트 불가. 중단(fail-closed)."; exit 4
fi
. "$ROOT/scripts/secret-patterns.sh"
if [ -z "${SECRET_RE:-}" ]; then
  echo "[vault-sync] ⛔ SECRET_RE 미로드 — 시크릿 게이트 불가. 중단(fail-closed)."; exit 4
fi

cmd="${1:-}"; [ "$#" -gt 0 ] && shift

case "$cmd" in
  pull)
    if has_origin; then
      echo "[vault-sync] pull --rebase (다머신 변경 수신)…"
      git pull --rebase --autostash 2>&1 | tail -4
    else
      echo "[vault-sync] origin 없음 — pull 생략 (로컬 전용 상태)"
    fi
    ;;
  push)
    msg="${1:-chore: vault update}"; [ "$#" -gt 0 ] && shift
    if [ "$#" -eq 0 ]; then
      echo "[vault-sync] 스테이징할 파일을 명시하세요 (git add . 금지). 예: vault-sync.sh push \"msg\" index.md log.md"; exit 2
    fi
    git add -- "$@" 2>/dev/null
    if git diff --cached --quiet; then echo "[vault-sync] 변경 없음 — 종료"; exit 0; fi
    # 시크릿 값 게이트 — '추가(+) 라인'만 검사 (삭제/정리는 차단 안 함, diff 헤더 +++ 제외).
    if git diff --cached --text --no-color | grep -a '^+' | grep -av '^+++' | grep -aEi "$SECRET_RE" >/dev/null 2>&1; then
      echo "[vault-sync] ⚠️ staged diff에 '시크릿 값' 패턴 감지 — commit 중단."
      echo "             해당 파일을 확인하고 값 제거(환경변수 이름+위치만) 후 재시도하세요."
      git reset -q -- "$@" 2>/dev/null
      exit 3
    fi
    git commit -q -m "$msg" || { echo "[vault-sync] commit 실패"; exit 1; }
    echo "[vault-sync] commit: $msg"
    if has_origin; then
      git pull --rebase --autostash 2>&1 | tail -2
      if git push 2>&1 | tail -2; then echo "[vault-sync] push 완료 (원격 동기화)"; fi
    else
      echo "[vault-sync] origin 없음 — commit만 함 (레포 연결 후 자동 push). "
    fi
    ;;
  *)
    echo "usage: vault-sync.sh {pull | push \"<commit msg>\" <file>...}"; exit 2;;
esac
