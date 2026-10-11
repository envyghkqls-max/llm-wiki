#!/usr/bin/env bash
# vault-append.sh — 공유 상태 파일(log.md / index.md / active.md 등)에 "안전 append"만 허용.
#
# 목적: 통째 덮어쓰기(write_file / `>` 리다이렉트)로 인한 동시 쓰기 손실
#       (실사례: cron 에이전트가 log.md를 통째 덮어써 기록이 유실된 사고) 재발을 물리적으로 차단한다.
#       모든 채널(Claude Code / Codex / Hermes cron)이 공유 상태를 갱신할 때 이 스크립트를 거친다.
#
# 사용법:
#   bash scripts/vault-append.sh <vault루트기준-상대경로> "<append할 텍스트>"
#   echo "여러 줄..." | bash scripts/vault-append.sh <vault루트기준-상대경로>
# 예:
#   bash scripts/vault-append.sh log.md "## [2026-06-09 21:30] save | wiki/x @[claude/시원]"
#
# 보장:
#   - 항상 파일 끝에 append (절대 truncate/overwrite 안 함 — `>>`만 사용)
#   - mkdir 원자적 락으로 동시 쓰기를 직렬화 (macOS/Linux 공통, flock 불필요)
#   - 대상은 vault 루트 기준 상대경로만 (절대경로/.. 경로탈출 차단)
set -euo pipefail

VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_REL="${1:-}"
[ -n "$TARGET_REL" ] || { echo "usage: vault-append.sh <relative-target> [text]" >&2; exit 2; }

# 경로 탈출 차단: 절대경로 / .. 금지
case "$TARGET_REL" in
  /*|*..*) echo "거부: vault 루트 기준 상대경로만 허용 ($TARGET_REL)" >&2; exit 2 ;;
  .git|.git/*|*/.git/*|.obsidian/*|scripts/*) echo "거부: .git·.obsidian·scripts 아래는 append 대상이 아님 ($TARGET_REL)" >&2; exit 2 ;;
  *.md) ;;
  *) echo "거부: 마크다운(.md) 파일만 append 허용 ($TARGET_REL)" >&2; exit 2 ;;
esac

# 공유 상태 파일 표준 경로 강제 (2026-07-17 — 제2 원장 재발 방지)
# 근거: AI-Sessions/log.md·루트 active.md가 경로 혼선으로 생성돼 원장이 분기했던 사고.
# basename이 공유 상태 파일이면 표준 경로로 교정하고 알린다.
BASE_NAME="$(basename "$TARGET_REL")"
CANON=""
case "$BASE_NAME" in
  log.md|index.md)          CANON="$BASE_NAME" ;;
  active.md|contested.md)   CANON="AI-Sessions/wiki/_status/$BASE_NAME" ;;
esac
if [ -n "$CANON" ] && [ "$TARGET_REL" != "$CANON" ]; then
  echo "경로 교정: $TARGET_REL → $CANON (공유 상태 파일은 표준 경로 하나만 존재해야 함)" >&2
  TARGET_REL="$CANON"
fi
TARGET="$VAULT_ROOT/$TARGET_REL"
# 심볼릭 링크 거부 (링크를 통해 vault 밖 파일에 쓰는 것 차단)
[ -L "$TARGET" ] && { echo "거부: 심볼릭 링크 대상 ($TARGET_REL)" >&2; exit 2; }

# 부모 디렉토리 실재 확인 (없으면 아래 mkdir 락이 영원히 실패해 '락 획득 실패'로 오인됨)
PARENT_DIR="$(dirname "$TARGET")"
[ -d "$PARENT_DIR" ] || { echo "거부: 대상 부모 디렉토리 없음 — $PARENT_DIR" >&2; exit 2; }

# append 내용: 2번째 인자 또는 stdin
if [ "$#" -ge 2 ]; then
  CONTENT="$2"
else
  CONTENT="$(cat)"
fi
[ -n "$CONTENT" ] || { echo "거부: 빈 내용은 append하지 않음" >&2; exit 2; }

# mkdir 원자적 락 (최대 ~5초 대기). 이미 있으면 다른 채널이 쓰는 중.
LOCK="$TARGET.lock.d"
tries=0
until mkdir "$LOCK" 2>/dev/null; do
  tries=$((tries + 1))
  if [ "$tries" -gt 50 ]; then
    echo "거부: 락 획득 실패(다른 채널이 쓰는 중일 수 있음) — $TARGET_REL" >&2
    exit 1
  fi
  sleep 0.1
done
trap 'rmdir "$LOCK" 2>/dev/null || true' EXIT

# 파일 끝 개행 보장 후 append (절대 truncate 안 함)
if [ -f "$TARGET" ]; then
  last="$(tail -c1 "$TARGET" 2>/dev/null || true)"
  [ -n "$last" ] && printf '\n' >>"$TARGET"
fi
printf '%s\n' "$CONTENT" >>"$TARGET"

echo "appended → $TARGET_REL"
