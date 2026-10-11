# LLM Wiki Vault — Template

LLM 에이전트가 사서(librarian) 역할로 유지하는 지식 베이스 템플릿. Andrej Karpathy의
[LLM Wiki 패턴](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)을 다중 에이전트
운영용으로 확장한 실전 구조를, 데이터 없이 뼈대와 규약만 담았다.

> "Obsidian is the IDE; the LLM is the programmer; the wiki is the codebase."

## 왜 이 구조인가 (RAG와의 차이)

RAG는 질문할 때마다 원문을 다시 읽고 결과를 버린다 — 축적이 없다. LLM Wiki는 합성을 **ingest 시점에
한 번** 수행해 마크다운 위키로 굳히고, 이후엔 그 결과물을 읽는다. 소스와 질문이 쌓일수록 위키가
촘촘해지는 복리 구조다. 단, 잘못된 해석도 함께 굳는 것이 유일한 약점이라 이 템플릿은 방어선(환각 0%
규칙, lint 게이트, 신뢰성 장부)을 구조에 내장했다.

## 3-Layer 한눈에

| 레이어 | 위치 | 소유 | 규칙 |
|---|---|---|---|
| 1. Raw (증거) | `AI-Sessions/raw/` | 사람 | LLM은 읽기만. 수정·삭제 절대 금지 |
| 준-raw (원장) | `AI-Sessions/conversations/` | 자동 생성 | 불변. wiki로의 승격 대기 큐 |
| 2. Wiki (지식) | `AI-Sessions/wiki/` | LLM | frontmatter+링크 필수, 게이트 통과분만 정제수로 |
| 3. Schema (규약) | `CLAUDE.md`·`AGENTS.md`·`index.md`·`log.md` | 함께 진화 | 에이전트 행동의 정본 |

## 빠른 시작

1. 이 폴더를 원하는 이름으로 두고 **Obsidian에서 vault로 연다**.
2. `CLAUDE.md` 하단 "커스터마이즈 포인트"의 `{{PLACEHOLDER}}`를 채운다 (큐레이터 이름, 도메인 owner 등).
3. git 초기화: `git init && git add -A && git commit -m "init: vault template"`
   (초기화 이후에는 규약대로 `git add .` 금지 — 파일 명시 add. 템플릿엔 데이터가 없으므로 최초 1회만 허용.)
4. 커밋 게이트 활성화: `bash scripts/install-hooks.sh` (lint FAIL·시크릿 값이 커밋되는 것을 물리적으로 차단).
5. 정합 확인: `bash scripts/vault-lint.sh` → PASS 확인.
6. 첫 소스를 `AI-Sessions/raw/articles/`에 넣고 에이전트에게 "이거 ingest해줘"라고 말한다.

## 자연어 사용법 (에이전트에게 이렇게 말하면 된다)

| 말하기 | 일어나는 일 |
|---|---|
| "이거 저장해" / "save to obsidian" | 직전 결과물을 적절한 카테고리에 단일 페이지로 저장 |
| "이거 ingest해줘" / "정리해줘" | raw 소스 → sources 요약 + 관련 페이지 10~15개 교차 갱신 |
| "X에 대해 뭐 있어?" | 카탈로그/MOC에서 찾아 합성 답변 + [[인용]] |
| "wiki 점검" / "lint" | 모순·고아 페이지·명명 위반·오염 검출 |
| "이전 세션 참조" / "지난번 어디까지" | 해당 프로젝트 핸드오버·위키 로드 후 이어서 작업 |

## 내장 방어선 (이 템플릿의 차별점)

- **환각 0% 0급 규칙** — 증거 없는 문장은 vault에 들어오지 못한다 (CLAUDE.md·AGENTS.md 최상단).
- **vault-lint.sh (검사 14종)** — 구조·frontmatter·orphan·명명·단일 창고·자동링커 오염까지 검출. FAIL이면 신규 쓰기 금지.
- **pre-commit 훅** — lint FAIL과 시크릿 값(secret-patterns.sh 정본)이 커밋되는 것을 차단. FAIL-CLOSED.
- **vault-append.sh** — 공유 상태 파일(log/index/active)의 통째 덮어쓰기·제2 원장 생성·동시 쓰기 충돌을 물리적으로 차단.
- **신뢰성 장부(contested.md)** — "최신 ≠ 정본". 충돌은 사용자가 확정할 때까지 정본 취급 금지.
- **vault-sync.sh** — 다머신 동기화(pull --rebase / 명시 파일 push, 시크릿 게이트 내장).

## 구조 커스터마이즈

- **도메인**: 기본 5종(design/content/dev/research/automation)은 예시다. `CLAUDE.md` 도메인 표와
  `AI-Sessions/wiki/knowledge/` 하위 폴더를 조직에 맞게 함께 바꾼다.
- **페르소나/개인 원장 폴더**: cron 에이전트별 폴더를 쓰면 `scripts/vault-lint.sh`의 distill 커버리지
  제외 목록(주석 표시된 곳)에 폴더명을 추가한다.
- **런타임 DB**: 별도 상태 저장소가 없으면 `_status/active.md`만으로 충분하다.

## 유래

한 운영 vault(다중 채널 — Claude Code·Codex·cron 에이전트 동시 사용)에서 2026-05~07 동안 실제 사고
(동시 쓰기 사본, 이중 원장, 자동 링커의 불변 레이어 오염)를 겪고 그 방어책이 규약·스크립트로 승격된
구조를 일반화했다. 규칙 하나하나에 실제 사고 사례가 있다 — 임의로 제거하기 전에 CLAUDE.md의 해당
섹션 설명을 읽어볼 것.
