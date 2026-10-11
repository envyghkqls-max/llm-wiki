#!/usr/bin/env bash
# install-hooks.sh — vault-lint pre-commit 게이트 활성화 (모든 채널 공통)
#
# core.hooksPath 를 추적되는 scripts/hooks/ 로 지정 → 훅이 repo와 함께 따라가
# 어느 클론·기기·에이전트(Codex·Claude·Hermes)가 커밋해도 동일하게 적용된다.
# core.hooksPath 자체는 per-clone 로컬 설정이라, 새 클론마다 이 스크립트 1회 실행.
ROOT="$(git rev-parse --show-toplevel)" || exit 1
cd "$ROOT" || exit 1
git config core.hooksPath scripts/hooks
chmod +x scripts/hooks/* 2>/dev/null
echo "✅ git hooks 활성화: core.hooksPath=scripts/hooks"
echo "   pre-commit = vault-lint 하드 게이트 (FAIL 시 커밋 차단, 전 채널 공통)"
echo "   새 클론/기기에서 이 스크립트를 1회 실행하세요."
