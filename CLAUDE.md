# {{VAULT_NAME}} — LLM Wiki Schema (Template)

> 이 문서는 LLM 에이전트(Claude Code, Codex 등)에게 본 vault의 운영 규약을 알려주는 **Layer 3(스키마)**다.
> Karpathy의 LLM Wiki 패턴(2026-04, https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)을 따른다.
>
> **핵심 명제**: "Obsidian is the IDE; the LLM is the programmer; the wiki is the codebase."
> **역할 분담**: 사용자({{CURATOR}}) = 큐레이터(소스 선별·정본 판단), LLM = 사서(요약·분류·교차링크·색인 전부).

## 0급(최우선·절대) — 환각 0%

> 이 vault는 누적 지식 정본이다. 환각(추측·창작·미검증 주장) 1건이 들어가면 오염이 정제수→스킬로 번진다.
> **환각률 목표는 0%이며, 이 규칙이 다른 모든 규칙보다 우선한다.**

1. **증거-우선**: 모든 사실·경로·`[[link]]`·수치는 실제로 읽은 파일/실행한 명령 출력에 근거. 기억·"아마"·추론으로 쓰지 않는다.
2. **실재 검증**: 인용하는 링크/경로/파일이 실재하는지 grep·ls로 확인. 없는 것 인용 = 환각.
3. **인용 신뢰도 표기**: verbatim vs paraphrase 구분. 원문 대조 못 했으면 "paraphrase"로 낮춰 적는다.
4. **불확실 → 멈춤**: 확신 없으면 "미확인" 표기 후 멈춘다. 지어내지 않는다.
5. **완료 주장 = 증거 동반**: "완료·성공·자동" 주장 전 명령 출력/파일 증거 확인.
6. **권위 > 시간**: 최신이라는 이유로 기존 `source_of_truth`를 자동 덮어쓰지 않는다. 충돌은 contested 장부 + 사용자 확인.
7. **오염 감지 → 작업 중단**: 깨끗한 정제수에 오염수 한 방울도 금지.

## 모든 에이전트 — 쓰기 작업 전 강제 사전점검

1. `AGENTS.md` 체크리스트를 먼저 읽는다 (실행 직전 self-check).
2. `index.md`를 읽어 현재 카탈로그·정리 큐를 확인한다.
3. `bash scripts/vault-lint.sh` 실행 → **exit 0 확인. FAIL 상태에서 신규 쓰기 금지.**
4. 작업 후 다시 lint 통과 확인 → `log.md` append → 사용자 보고.

## save vs ingest 구분 (혼동 금지)

| 구분 | save | ingest |
|---|---|---|
| 트리거 | "저장해", "save to obsidian" | "이거 정리해줘", raw/에 새 파일 |
| 입력 | 현재 대화의 합성 결과물 | raw/ 또는 conversations/의 1차 자료 |
| 출력 | 카테고리 1개에 단일 페이지 | sources 1페이지 + 관련 페이지 10~15개 cross-update |
| 함정 | save를 ingest로 착각 → raw 없는 sources | ingest를 save로 처리 → cross-update 누락 |

**원칙**: 외부 자료(아티클·논문·영상·transcript)는 반드시 `raw/`에 먼저 두고 ingest로 처리한다.

## 3-Layer 아키텍처

**Layer 1 — Raw (불변)**: LLM은 읽기만 한다. 수정·삭제 절대 금지.
**Layer 2 — Wiki (LLM 소유)**: LLM이 만들고 유지. frontmatter + `[[wikilink]]` 필수.
**Layer 3 — Schema**: 이 파일 + `index.md`(카탈로그) + `log.md`(타임라인).

```
{{VAULT_NAME}}/
├── CLAUDE.md · AGENTS.md · README.md · index.md · log.md
├── scripts/            (lint·append·sync·훅 — 방어선)
└── AI-Sessions/
    ├── raw/            articles/ papers/ notes/ inbox/ assets/   ← 불변 증거
    ├── conversations/  {프로젝트}/ 핸드오버 원장 (준-raw, 수정 금지, 승격 대기 큐)
    │   └── _unsorted/  분류 전 임시 (사용자 승인 후 정규화)
    └── wiki/
        ├── sources/    raw 1:1 요약 (+legacy/ 過去분 보관)
        ├── concepts/   이론·패턴          ├── decisions/  의사결정(ADR)
        ├── playbooks/  반복 절차          ├── projects/   프로젝트 누적 지식
        ├── entities/   사람·조직·도구     ├── errors/     시행착오+해결책
        ├── synthesis/  비교·분석·MOC (도메인 MOC 포함)
        ├── knowledge/  도메인 정제수 — 게이트 통과분만. {domain}/reference·judgment
        ├── context/    채널 공유 컨텍스트 팩
        ├── harnesses/  도메인 하네스(스킬 묶음+게이트+version)
        └── _status/    active.md(휘발 상태판) + contested.md(신뢰성 장부)
```

## 핵심 연산 3가지

**Ingest**: raw 읽기 → `wiki/sources/{slug}.md` 1:1 요약 → 영향 받는 페이지 cross-update(1소스가 10~15페이지) → 신규 entity/concept 생성 → 모순 발견 시 `> [!warning] 모순:` 표시 → index/log 갱신 → lint.
**Query**: index(또는 도메인 MOC) → 관련 페이지 read → 합성 답변 + `[[citation]]`. 유의미한 답변은 동의 받아 `synthesis/`에 보존.
**Lint**: `bash scripts/vault-lint.sh` — 모순·stale·orphan·명명 위반·index 불일치·오염 검출.

## 파일 컨벤션

**명명**
- sources: `YYYY-MM-DD-{type}-{kebab-slug}.md` / decisions: `YYYY-MM-DD-{kebab-slug}.md`
- concepts·playbooks·entities·errors·synthesis: `{kebab-slug}.md` — **날짜 접두사 금지**
- projects: **프로젝트명만** (`myproject.md`). `-session`, `-production`, `-YYYY-MM-DD` 접미사 금지 (lint 차단)
- 핸드오버: `conversations/{프로젝트}/YYYY-MM-DD-HHMM-{프로젝트}-handover.md`
- 프로젝트 폴더명 정규화: lowercase, 공백·언더스코어→하이픈. 프로젝트별 CLAUDE.md의 `vault_folder:` 메타가 있으면 그것이 우선.

**Frontmatter — source**
```yaml
---
type: source
source_type: article|paper|video|podcast|book|transcript|note
title: ''
author:
date_published:
url:
ingested: 'YYYY-MM-DD'
status: ingested
tags: []
---
```

**Frontmatter — 그 외 (concept/decision/playbook/project/entity/error/synthesis)**
```yaml
---
type: concept
title: ''
status: seed|growing|mature|contested|stale
created: 'YYYY-MM-DD'
updated: 'YYYY-MM-DD'      # 마지막 변경 (델타 알림용)
verified: 'YYYY-MM-DD'     # 마지막 사실 검증 (정본 신뢰성)
source_of_truth: ''        # 정본 권위(누가·언제 확정). 비면 '미확정'
contested: false           # true면 정본 보류 → _status/contested.md
author: human|agent        # 사람 vs 봇 가시화
related: []                # [[wikilink]] 배열
tags: []                   # domain/<slug> 1개 포함 권장
---
```

**링크 규칙**: ① 모든 페이지 첫 줄 = `>` 한 문장 요약 ② 모든 페이지 최소 1개 `[[link]]` 포함(orphan 금지 — 신규 source는 lint가 FAIL로 차단) ③ 모든 source는 ≥1개 concept/entity로 연결 ④ 같은 사실은 한 페이지에만, 나머지는 [[link]] (단일 진실의 원천).

## index.md / log.md 운영

- `index.md`(루트) = 마스터 카탈로그. 카테고리별 `- [[페이지]] — 한 줄 요약 (status)`. 매 작업 후 해당 섹션 **부분 갱신**(하단 append 금지 — 카탈로그는 장부가 아니다).
- `log.md`(루트) = append-only 타임라인. 형식: `## [YYYY-MM-DD HH:MM] {operation} | {target} @[채널/이름]` + 1~3줄. operation: ingest|query|lint|handoff|save|manual-edit.
- **공유 상태 파일(log/index/active/contested)은 통째 덮어쓰기 절대 금지** — `bash scripts/vault-append.sh <상대경로> "<텍스트>"` 또는 부분 편집만. 스크립트가 표준 경로를 강제하고 락으로 동시 쓰기를 직렬화한다.

## 진실 판단 — 권위 우선

- **최신**(updated) = 델타 알림용. **정본**(source_of_truth) = 권위. 충돌 시 정본이 이긴다.
- 충돌·오염 발견 시: ① 자동 정본화 금지 ② `_status/contested.md`에 Unresolved 행 등재 + 해당 페이지 `contested: true` ③ 사용자에게 정본 확인 요청 ④ 확정 후 source_of_truth 갱신 + Resolved.
- 가리키는 대상이 실재하지 않으면 `status: stale` + 장부 등재. 모든 에이전트는 boot 시 contested 장부를 먼저 읽는다.

## 상태 레이어 + 동시성 (다중 채널 공유 시)

- `_status/active.md` = "지금 누가 무엇을" 휘발 상태판. 작업 시작 시 자기 행 추가, 종료 시 제거 + log append. **"최근 완료(델타)"는 최신 5건만 유지** — 이력은 log와 git이 보존.
- 같은 프로젝트를 다른 채널이 Active면 대기/조율 (한 번에 하나).
- 모든 기록에 채널 태그: `@[claude|codex|기타/이름]`.
- git 이중 방어: 작업 전 status 확인 → 논리 단위 commit → **`git add .`/`-A` 금지, 자기 파일만 명시 add** → 커밋 전 시크릿 게이트(scripts/hooks/pre-commit이 자동 차단) → 다머신은 참조 전 `bash scripts/vault-sync.sh pull`, 저장 후 `bash scripts/vault-sync.sh push "<msg>" <파일…>`.
- 자동화(cron·데몬)가 vault에 쓰려면 이 스키마의 불변 규칙을 먼저 따라야 한다. **conversations/raw를 수정하는 자동 도구 금지** (lint의 autolink 오염 게이트가 차단).

## 작업 종료 시 output classifier (5종 분류)

- 원본/외부 증거인가? → `raw/` (또는 원 소스 경로+검증 명령 기록)
- 작업 원장인가? → `conversations/{프로젝트}/`
- 재사용 지식인가? → `wiki/` (아래 우선순위: 프로젝트 상태→projects, 오류→errors, 절차→playbooks, 결정→decisions, 지도→synthesis)
- 런타임 상태인가? → 외부 상태 저장소({{RUNTIME_DB — 없으면 active.md}})
- 반복 행동 규칙인가? → 에이전트 스킬/메모리 (7일 뒤 stale해질 것은 메모리에 넣지 않는다 — vault로 offload)

이 분류 없이 "답변만" 남기면 지식 성장 루프가 끊긴 것으로 간주한다.

## 도메인 지식 파이프라인 (정제수 루프)

- **축1 도메인** = frontmatter tags에 `domain/<slug>` 1개(그래프 자동 채색). **축2 형태** = 기존 카테고리. 파일은 옮기지 않는다.
- 도메인 레지스트리 (조직에 맞게 교체):

| 슬러그 | 도메인 | owner | MOC | 정제수 |
|---|---|---|---|---|
| `domain/design` | 디자인·UI | {{OWNER_DESIGN}} | [[design-moc]] | `knowledge/design/` |
| `domain/content` | 콘텐츠·영상 | {{OWNER_CONTENT}} | [[content-moc]] | `knowledge/content/` |
| `domain/dev` | 개발·인프라 | {{OWNER_DEV}} | [[dev-moc]] | `knowledge/dev/` |
| `domain/research` | 리서치 | {{OWNER_RESEARCH}} | [[research-moc]] | `knowledge/research/` |
| `domain/automation` | 자동화·에이전트 운영 | {{OWNER_AUTOMATION}} | [[automation-moc]] | `knowledge/automation/` |

- **6단계 정제 흐름**: 레퍼런스 수집(sources) → 해체·분석(synthesis) → 개념 이해(concepts) → 규칙 도출(playbooks·decisions) → 모듈화(projects) → 스킬화. 각 단계가 다음 단계의 원료. MOC가 "다음 단계로 올라갈 후보"를 한 줄씩 유지 — 흐름이 멈춘 지점 = 다음 distill 대상.
- **원수→정제수 필터**: cron 덤프는 그대로 두고 품질 게이트(도메인별 `_quality-rubric`) 통과분만 `knowledge/<domain>/`로. 정제 = 분류 + 검증.
- **참조는 계단식**: contested 게이트 → 도메인 1개로 분류 → 그 도메인 MOC만 → 후보 1~3개 요약 → 필요한 것만 본문. **vault 전체·index 전체를 읽지 않는다** (지식이 커져도 참조 비용 일정).
- **동시성**: 수집은 각자 새 파일에만 태그(충돌 0). MOC·정제수는 owner 단일 작성자, partial-edit만.

## handoff / distill

- 정기 handoff의 목적은 idle 보고가 아니라 저장소 성장. **델타 classifier 먼저: 새 소스·결정·상태·오류·절차가 없으면 노트를 만들지 않는다.**
- conversations는 최종 지식이 아니라 승격 대기 큐 — 결정·절차·오류·상태 변화는 같은 턴에 wiki로 distill.

## 금기 (절대 하지 말 것)

- `raw/`·`conversations/` 수정·삭제 (이동은 사용자 승인 시만) / frontmatter 없는 wiki 페이지 / orphan 생성
- projects에 날짜·session 접미사 / 외부 자료를 save로 직행 (raw→ingest 우회 금지)
- lint FAIL 상태에서 신규 쓰기 / index 갱신 누락한 채 종료
- vault 루트에 새 최상위 폴더(제2 창고) 생성 — 모든 자산은 AI-Sessions/ 아래 (lint FAIL)
- log/index/active를 통째 덮어쓰기 / 루트에 `log 2.md`류 번호 사본 방치
- contested 주제를 사용자 확인 없이 정본화 / 모순 발견 후 장부 미등재 종료

## 커스터마이즈 포인트

| placeholder | 채울 내용 |
|---|---|
| `{{VAULT_NAME}}` | vault 폴더명 |
| `{{CURATOR}}` | 큐레이터(사용자) 이름 |
| `{{OWNER_*}}` | 도메인별 owner (사람 또는 에이전트 페르소나) |
| `{{RUNTIME_DB}}` | 런타임 상태 저장소가 있으면 경로 (없으면 삭제) |
| 도메인 표 | 조직의 실제 도메인으로 교체 + `wiki/knowledge/` 하위 폴더 동기화 |
| vault-lint.sh 191행 부근 | 페르소나/개인 원장 폴더가 있으면 distill 검사 제외 목록에 추가 |
