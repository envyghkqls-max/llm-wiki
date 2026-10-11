#!/usr/bin/env bash
# secret-patterns.sh — '시크릿 값' 정규식 단일 정본 (1급 보안).
# vault-sync.sh(push 게이트)와 scripts/hooks/pre-commit(커밋 게이트)이 둘 다 이 파일을
# source 한다 → 패턴이 한 곳에만 있어 드리프트 0. 토픽 단어(token/secret 등 본문)는
# 게이트하지 않는다(이 지식 vault는 보안을 '주제'로 다루므로 오탐 방지). '키 값 형태'만 차단.
#
# 접두사 있는 키(sk-ant-api03-…, sk-proj-…)는 하이픈·언더스코어 포함 본문까지 매칭.
# 접두사 없는 구형 sk- 는 '연속 alnum'만 (하이픈 제외) — "task-simplification" 류 단어 오탐 방지.
# 포함: Anthropic, OpenAI, Stripe, Resend, GitHub, Slack, AWS, Google, Telegram 봇 토큰, JWT,
#       DB/큐 접속문자열(user:password@), private key 블록.
_SQ="'"
SECRET_RE='BEGIN ([A-Z]+ )?PRIVATE KEY'
SECRET_RE+='|sk-(ant|proj|svcacct|admin)-[A-Za-z0-9_-]{20,}'
SECRET_RE+='|sk-[A-Za-z0-9]{20,}'
SECRET_RE+='|[rs]k_(live|test)_[A-Za-z0-9]{20,}'
SECRET_RE+='|re_[A-Za-z0-9_]{20,}'
SECRET_RE+='|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}'
SECRET_RE+='|xox[baprs]-[A-Za-z0-9-]{20,}'
SECRET_RE+='|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}'
SECRET_RE+='|[0-9]{8,10}:AA[A-Za-z0-9_-]{30,}'
SECRET_RE+='|eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}'
SECRET_RE+='|(postgres(ql)?|mongodb(\+srv)?|mysql|mariadb|rediss?|amqps?)://[^ /:@"'"$_SQ"']*:[^ @"'"$_SQ"']+@'
export SECRET_RE
unset _SQ
