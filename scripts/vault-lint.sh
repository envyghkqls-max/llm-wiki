#!/usr/bin/env bash
# vault-lint.sh — Karpathy LLM Wiki 규약 자동 검증
#
# 사용: bash scripts/vault-lint.sh [--quiet]
# 종료 코드: 0 정합, 1 위반 발견
#
# 검사 항목:
#  0. Karpathy LLM Wiki 필수 구조
#  1. wiki 페이지 frontmatter 누락
#  2. index.md ↔ 디스크 정합 (누락·잉여·broken wikilink)
#  3. orphan 페이지 (inbound link 0)
#  4. projects/ 명명 규칙 위반 (-session, -production, -YYYY-MM-DD 접미사)
#  5. raw/sources 1:1 정합 (raw 0인데 sources 존재 = save가 ingest를 가장)
#  6. related: 필드의 legacy/ 직접 링크
#  7. _unsorted 잔여
#  8. conversations → wiki distillation coverage
#  9. 신뢰성 — contested 미해결 / contested:true·stale 페이지 / projects source_of_truth (warning)
#
# 실행 위치: vault 루트 (AI-Sessions-Vault/)

set -uo pipefail

VAULT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$VAULT_ROOT"

QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1

FAIL=0
log() { [ "$QUIET" = "0" ] && echo "$@"; }
fail() { FAIL=1; echo "❌ $@"; }
pass() { [ "$QUIET" = "0" ] && echo "✅ $@"; }

WIKI_DIR="AI-Sessions/wiki"
RAW_DIR="AI-Sessions/raw"
CONV_DIR="AI-Sessions/conversations"
INDEX="index.md"
LOG="log.md"

log "=== vault-lint.sh @ $(date '+%Y-%m-%d %H:%M:%S') ==="
log "VAULT_ROOT: $VAULT_ROOT"
log ""

# -------------------------------------------------------------------
# 0. Karpathy LLM Wiki 필수 구조
# -------------------------------------------------------------------
log "[0/8] Karpathy LLM Wiki 구조 검사"
for required_dir in "$RAW_DIR" "$RAW_DIR/articles" "$RAW_DIR/papers" "$RAW_DIR/notes" "$RAW_DIR/inbox" "$RAW_DIR/assets" "$WIKI_DIR" "$CONV_DIR"; do
  if [ ! -d "$required_dir" ]; then
    fail "필수 디렉터리 누락: $required_dir"
  fi
done
for required_file in "$INDEX" "$LOG" "AGENTS.md" "CLAUDE.md"; do
  if [ ! -f "$required_file" ]; then
    fail "필수 파일 누락: $required_file"
  fi
done
[ "$FAIL" = "0" ] && pass "raw/wiki/conversations/schema/index/log 구조 OK"
log ""

# -------------------------------------------------------------------
# 1. frontmatter 누락 검사
# -------------------------------------------------------------------
log "[1/8] frontmatter 누락 검사 (wiki/ — legacy 제외)"
MISS_FM=0
while IFS= read -r f; do
  first=$(head -1 "$f" 2>/dev/null)
  if [ "$first" != "---" ]; then
    fail "frontmatter 누락: $f"
    MISS_FM=$((MISS_FM+1))
  fi
done < <(find "$WIKI_DIR" -maxdepth 4 -type f -name '*.md' ! -path '*/legacy/*' ! -path '*/_status/*' 2>/dev/null)
[ "$MISS_FM" = "0" ] && pass "frontmatter 모두 OK"
log ""

# -------------------------------------------------------------------
# 2. index.md ↔ 디스크 정합
# -------------------------------------------------------------------
log "[2/8] index.md ↔ 디스크 정합"

# 2a. index.md 의 wikilink → 디스크 존재 검사 (본문 placeholder 제외)
PLACEHOLDERS="^(CLAUDE|AGENTS|wikilink|페이지명|관련-페이지-1|관련-페이지-2|source-페이지명|file-1|file-2|file-stem|topic|프로젝트|category|file)$"
BROKEN=0
while IFS= read -r link; do
  stem=$(echo "$link" | sed 's/\[\[//;s/\]\]//')
  echo "$stem" | grep -qE "$PLACEHOLDERS" && continue
  if ! find "$WIKI_DIR" -type f -name "${stem}.md" 2>/dev/null | grep -q .; then
    fail "index.md broken wikilink: [[$stem]]"
    BROKEN=$((BROKEN+1))
  fi
done < <(grep -oE '\[\[[^]]+\]\]' "$INDEX" | sort -u)
[ "$BROKEN" = "0" ] && pass "index.md 의 모든 wikilink 가 디스크 파일을 가리킴"

# 2b. 디스크에 있는 wiki 페이지가 index 에 등재됐는지
MISS_INDEX=0
while IFS= read -r f; do
  stem=$(basename "$f" .md)
  if ! grep -qF "[[$stem]]" "$INDEX"; then
    fail "index.md 미등재: $f"
    MISS_INDEX=$((MISS_INDEX+1))
  fi
done < <(find "$WIKI_DIR" -maxdepth 4 -type f -name '*.md' ! -path '*/legacy/*' ! -path '*/_status/*' 2>/dev/null)
[ "$MISS_INDEX" = "0" ] && pass "디스크의 모든 wiki 페이지가 index 에 등재됨"
log ""

# -------------------------------------------------------------------
# 3. orphan 페이지 (inbound link 0) — legacy 제외
# -------------------------------------------------------------------
log "[3/8] orphan 페이지 검사 (inbound link 0)"
ORPHAN=0
while IFS= read -r f; do
  stem=$(basename "$f" .md)
  # index.md 등재는 inbound로 안 침. 다른 wiki 페이지에서의 [[link]]만 카운트.
  count=$(grep -rl "\[\[${stem}\]\]" "$WIKI_DIR" 2>/dev/null | grep -v "^$f$" | wc -l | tr -d ' ')
  if [ "$count" = "0" ]; then
    log "⚠️  orphan: $stem (wiki 내 inbound 0)"
    ORPHAN=$((ORPHAN+1))
  fi
done < <(find "$WIKI_DIR" -maxdepth 4 -type f -name '*.md' ! -path '*/legacy/*' ! -path '*/_status/*' 2>/dev/null)
if [ "$ORPHAN" -gt "0" ]; then
  log "  → orphan $ORPHAN 건 (lint warning, fail 아님)"
else
  pass "orphan 없음"
fi
log ""

# -------------------------------------------------------------------
# 4. projects/ 명명 규칙
# -------------------------------------------------------------------
log "[4/8] projects/ 명명 규칙 (-session, -production, -YYYY-MM-DD 접미사 금지)"
PROJ_VIOL=0
while IFS= read -r f; do
  base=$(basename "$f" .md)
  if echo "$base" | grep -qE '(-session$|-production-session|-session-[0-9]{4}-[0-9]{2}-[0-9]{2}$|-[0-9]{4}-[0-9]{2}-[0-9]{2}$)'; then
    fail "projects 명명 위반: $f (날짜·session 접미사)"
    PROJ_VIOL=$((PROJ_VIOL+1))
  fi
done < <(find "$WIKI_DIR/projects" -maxdepth 1 -type f -name '*.md' 2>/dev/null)
[ "$PROJ_VIOL" = "0" ] && pass "projects 명명 규칙 OK"
log ""

# -------------------------------------------------------------------
# 5. raw vs sources 1:1 정합
# -------------------------------------------------------------------
log "[5/8] raw vs sources 1:1 정합 (save 가 ingest 를 가장하지 않는지)"
RAW_COUNT=$(find "$RAW_DIR" -type f ! -name '.DS_Store' ! -name '.gitkeep' 2>/dev/null | wc -l | tr -d ' ')
SRC_COUNT=$(find "$WIKI_DIR/sources" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
log "  raw 파일: $RAW_COUNT, sources 페이지: $SRC_COUNT"
if [ "$RAW_COUNT" = "0" ] && [ "$SRC_COUNT" -gt "0" ]; then
  log "⚠️  raw 0인데 sources $SRC_COUNT — 외부 자료는 raw/ 에 두고 ingest 해야 함 (warning)"
fi
log ""

# -------------------------------------------------------------------
# 6. related: 의 legacy 직접 링크
# -------------------------------------------------------------------
log "[6/8] related: 필드의 legacy/ 페이지 직접 링크"
LEGACY_REL=0
while IFS= read -r f; do
  if awk '/^---$/{c++} c==1' "$f" 2>/dev/null | grep -qE "\[\[2026-05-03_|\[\[_setup-verification"; then
    fail "related 에 legacy 직접 링크: $f"
    LEGACY_REL=$((LEGACY_REL+1))
  fi
done < <(find "$WIKI_DIR" -maxdepth 4 -type f -name '*.md' ! -path '*/legacy/*' ! -path '*/_status/*' 2>/dev/null)
[ "$LEGACY_REL" = "0" ] && pass "related 필드의 legacy 링크 없음"
log ""

# -------------------------------------------------------------------
# 7. _unsorted 잔여 + 정규화 위반 폴더
# -------------------------------------------------------------------
log "[7/8] conversations/ 정규화 위반"
UNSORTED=$(find "$CONV_DIR/_unsorted" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
if [ "$UNSORTED" -gt "0" ]; then
  log "⚠️  _unsorted 잔여: $UNSORTED 건 (사용자 승인 후 정규화 필요)"
fi
VIOL_DIRS=$(ls "$CONV_DIR" 2>/dev/null | grep -E '[A-Z]|_[a-z]' | grep -v '^_unsorted$' | wc -l | tr -d ' ')
if [ "$VIOL_DIRS" -gt "0" ]; then
  log "⚠️  정규화 위반 폴더 (대문자·언더스코어): $VIOL_DIRS"
  ls "$CONV_DIR" | grep -E '[A-Z]|_[a-z]' | grep -v '^_unsorted$' | sed 's/^/    /'
fi
log ""

# -------------------------------------------------------------------
# 8. conversations → wiki distillation coverage
# -------------------------------------------------------------------
log "[8/8] conversations → wiki distillation coverage"
MISSING_DISTILL=()
while IFS= read -r d; do
  base=$(basename "$d")
  case "$base" in
    _unsorted)  # 페르소나/개인 원장 폴더가 있으면 여기에 |이름 으로 추가 (distill 커버리지 검사 제외 대상)
      continue
      ;;
  esac
  if [ ! -f "$WIKI_DIR/projects/${base}.md" ] && ! grep -qF "[[$base]]" "$INDEX"; then
    MISSING_DISTILL+=("$base")
  fi
done < <(find "$CONV_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

if [ "${#MISSING_DISTILL[@]}" -gt "0" ]; then
  log "⚠️  conversations 폴더 중 wiki/index 연결이 없는 후보: ${#MISSING_DISTILL[@]}건"
  printf '%s\n' "${MISSING_DISTILL[@]}" | head -20 | sed 's/^/    /'
  log "  → [[conversation-to-wiki-distillation]] 기준으로 순차 승격 필요 (warning, fail 아님)"
else
  pass "conversation distillation coverage OK"
fi
log ""

# -------------------------------------------------------------------
# 9. 신뢰성 — contested / stale / source_of_truth (warning, fail 아님)
# -------------------------------------------------------------------
log "[9/9] 신뢰성 장부·정본 점검"
LEDGER="$WIKI_DIR/_status/contested.md"
if [ -f "$LEDGER" ]; then
  UNRES=$(grep -c '| Unresolved |' "$LEDGER" 2>/dev/null | tr -d ' ')
  if [ "${UNRES:-0}" -gt 0 ]; then
    log "⚠️  미해결 contested ${UNRES}건 (wiki/_status/contested.md) — 정본 확정 필요 (warning)"
  else
    pass "미해결 contested 없음"
  fi
else
  log "⚠️  신뢰성 장부 없음: $LEDGER (생성 권장)"
fi
CFLAG=$(grep -rl '^contested: true' "$WIKI_DIR" 2>/dev/null | grep -v '/_status/' | wc -l | tr -d ' ')
if [ "${CFLAG:-0}" -gt 0 ]; then
  log "⚠️  contested:true 페이지 ${CFLAG}건 — 정본 취급 금지:"
  grep -rl '^contested: true' "$WIKI_DIR" 2>/dev/null | grep -v '/_status/' | sed 's|.*/||;s/^/    /'
fi
SFLAG=$(grep -rl '^status: stale' "$WIKI_DIR" 2>/dev/null | wc -l | tr -d ' ')
[ "${SFLAG:-0}" -gt 0 ] && log "⚠️  status:stale 페이지 ${SFLAG}건 — 재검증 대상"
SOT_MISS=0
while IFS= read -r f; do
  grep -q '^source_of_truth:' "$f" 2>/dev/null || SOT_MISS=$((SOT_MISS+1))
done < <(find "$WIKI_DIR/projects" -maxdepth 1 -type f -name '*.md' 2>/dev/null)
[ "${SOT_MISS:-0}" -gt 0 ] && log "ℹ️  projects 중 source_of_truth 미기재 ${SOT_MISS}건 (점진 보강 권장, fail 아님)"
log ""

# -------------------------------------------------------------------
# 10. 루트 log/index 번호·temp 사본 검출 (동시 쓰기 충돌 잔재 → FAIL)
#     'log 2.md' 류 번호 사본 + 'index 19.tjfgHv' 류 원자적 쓰기 temp 잔재 모두 포함
# -------------------------------------------------------------------
log "[10/10] 루트 log/index 번호·temp 사본 검출"
DUP=$(find "$VAULT_ROOT" -maxdepth 1 \( -name 'log [0-9]*' -o -name 'index [0-9]*' \) 2>/dev/null | wc -l | tr -d ' ')
if [ "${DUP:-0}" -gt 0 ]; then
  fail "루트에 log/index 번호·temp 사본 ${DUP}개 (동시 쓰기 충돌 잔재) — .archive로 이동 필요:"
  find "$VAULT_ROOT" -maxdepth 1 \( -name 'log [0-9]*' -o -name 'index [0-9]*' \) 2>/dev/null | sed 's|.*/||;s/^/    /'
else
  pass "log/index 번호·temp 사본 없음 (정본 1개씩 유지)"
fi
log ""

# -------------------------------------------------------------------
# 11. 도메인 태그 커버리지 (warning, fail 아님) — 신규 wiki 페이지 domain/<slug> 권장
#     규칙 정본: wiki/playbooks/domain-knowledge-pipeline.md
# -------------------------------------------------------------------
log "[11] 도메인 태그 커버리지"
DOM_MISS=0
while IFS= read -r f; do
  awk '/^---$/{c++} c==1' "$f" 2>/dev/null | grep -qE '(^|[,[ ])domain/' || DOM_MISS=$((DOM_MISS+1))
done < <(find "$WIKI_DIR" -maxdepth 4 -type f -name '*.md' ! -path '*/legacy/*' ! -path '*/_status/*' 2>/dev/null)
if [ "${DOM_MISS:-0}" -gt 0 ]; then
  log "ⓘ 도메인 태그 없는 wiki 페이지 ${DOM_MISS}건 (domain/design|content|dev|research|automation|meta 권장; 인물 엔티티 등 도메인 중립은 예외) — [[domain-knowledge-pipeline]]"
else
  pass "모든 wiki 페이지 도메인 태그 보유"
fi
log ""

# -------------------------------------------------------------------
# 12. 止血 — 신규 source orphan 게이트 (FAIL)
#     새 source 는 최소 1개 wiki [[link]] 필수(Karpathy orphan 규칙). 기존 부채는
#     scripts/orphan-grandfathered.txt 로 면제(정제 de-orphan 시 자동 무관).
#     계량: scripts/shelf-debt.py. 정본: [[domain-knowledge-pipeline]] 자가학습 루프.
# -------------------------------------------------------------------
log "[12] 신규 source orphan 止血 게이트"
GF_FILE="scripts/orphan-grandfathered.txt"
NEW_ORPHAN=0
while IFS= read -r f; do
  stem=$(basename "$f" .md)
  count=$(grep -rl "\[\[${stem}\]\]" "$WIKI_DIR" 2>/dev/null | grep -v "^$f$" | wc -l | tr -d ' ')
  if [ "$count" = "0" ]; then
    if [ -f "$GF_FILE" ] && grep -qxF "$stem" "$GF_FILE"; then
      :  # 기존 부채 면제 (grandfather)
    else
      fail "신규 source orphan: $stem — 최소 1개 concept/MOC/synthesis 에 [[link]] 필요 (止血)"
      NEW_ORPHAN=$((NEW_ORPHAN+1))
    fi
  fi
done < <(find "$WIKI_DIR/sources" -maxdepth 1 -type f -name '*.md' 2>/dev/null)
[ "$NEW_ORPHAN" = "0" ] && pass "신규 source orphan 없음 (기존 부채 ${GF_FILE} grandfather)"
log ""

# -------------------------------------------------------------------
# 13. 단일 창고 — 루트 최상위 폴더 화이트리스트 (FAIL on new split store)
#     모든 지식자산(raw 증거·작업 산출물·wiki)은 AI-Sessions/ 아래에. vault 루트에
#     새 창고/보관함 폴더 생성 금지. 기존 drift는 scripts/rootdir-grandfathered.txt 로
#     "이관 대기"로 추적. 정본: [[domain-knowledge-pipeline]] "단일 창고".
# -------------------------------------------------------------------
log "[13] 루트 최상위 폴더 단일창고 게이트"
RD_GF="scripts/rootdir-grandfathered.txt"
ROOT_ALLOWED=" AI-Sessions scripts "
NEW_ROOTDIR=0
while IFS= read -r d; do
  base=$(basename "$d")
  case "$ROOT_ALLOWED" in *" $base "*) continue;; esac
  if [ -f "$RD_GF" ] && grep -qxF "$base" "$RD_GF"; then
    log "ⓘ 루트 폴더(이관 대기): $base — AI-Sessions/ 아래로 통합 예정"
    continue
  fi
  fail "루트 비인가 최상위 폴더: $base — 모든 지식자산은 AI-Sessions/ 아래에. 새 창고/보관함 금지 (단일 창고 규칙)"
  NEW_ROOTDIR=$((NEW_ROOTDIR+1))
done < <(find "$VAULT_ROOT" -maxdepth 1 -mindepth 1 -type d ! -name '.*' 2>/dev/null)
[ "$NEW_ROOTDIR" = "0" ] && pass "루트 최상위 폴더 OK (AI-Sessions/scripts + 이관대기만)"
log ""

# -------------------------------------------------------------------
# 14. autolink 오염 게이트 (FAIL) — conversations/raw 는 불변 원장.
#     외부 자동링커(bus-daemon wiki-link.py / wiki-autolink 스킬)가 삽입하는
#     '<!-- autolink:start -->' 관리 블록이 vault 안 .md 에 있으면 오염으로 간주.
#     근거 사고: 2026-07-17 conversations 857건 무단 수정 → 전량 revert (log.md 참조).
# -------------------------------------------------------------------
log "[14] autolink 오염 게이트 (불변 원장 보호)"
AL_HITS=$(grep -rl 'autolink:start' "AI-Sessions" --include='*.md' 2>/dev/null | grep -v '/\.archive' | wc -l | tr -d ' ')
if [ "${AL_HITS:-0}" -gt 0 ]; then
  fail "autolink 블록 오염 ${AL_HITS}건 — 자동링커가 vault 에 쓰기함. 블록 revert + 링커의 vault 대상 제외 필요:"
  grep -rl 'autolink:start' "AI-Sessions" --include='*.md' 2>/dev/null | grep -v '/\.archive' | head -5 | sed 's/^/    /'
else
  pass "autolink 오염 없음"
fi
log ""

# -------------------------------------------------------------------
# 결과
# -------------------------------------------------------------------
log "=== 결과 ==="
if [ "$FAIL" = "0" ]; then
  log "✅ vault-lint: PASS"
  exit 0
else
  log "❌ vault-lint: FAIL — 위 항목 정리 후 재실행"
  exit 1
fi
