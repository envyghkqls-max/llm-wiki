# AGENTS.md — Vault 강제 self-check (모든 에이전트 필수)

> 이 파일은 **실행 직전 체크리스트**다. 상세 규약은 [`CLAUDE.md`](CLAUDE.md), 카탈로그는 [`index.md`](index.md), 타임라인은 [`log.md`](log.md).
> 어떤 에이전트든 이 vault에 쓰기·이동·삭제를 시도하기 전 이 체크리스트를 통과해야 한다.
>
> **명제**: 사용자는 큐레이터, LLM은 librarian. wiki는 codebase처럼. 같은 사실은 한 페이지에만.

## 0급 — 환각 0% (모든 규칙에 우선)

- 모든 사실·경로·`[[link]]`·수치는 실제로 읽은 파일/실행 출력에 근거. 추측·기억·"아마" 금지.
- 불확실하면 "미확인" 표기 후 멈춤. 쓰기 전 인용 대상 실재 검증. "완료"는 증거 확인 후에만.

## 0. 모든 쓰기 작업 전 (예외 없음)

```
□ CLAUDE.md 사전점검·output classifier 섹션을 읽었다
□ index.md에서 카탈로그·정리 큐를 확인했다
□ bash scripts/vault-lint.sh → exit 0 확인 (실패면 정리 먼저)
□ 이번 작업이 save / ingest / handoff / 상태 갱신 중 무엇인지 구분했다
□ 산출물을 5종(원본/원장/지식/런타임/행동규칙)으로 분류했다
□ wiki/_status/contested.md를 읽었다 (걸린 주제는 정본 취급·덮어쓰기 금지)
□ wiki/_status/active.md에서 다른 채널의 동시 작업을 확인하고 내 행을 등재했다
□ 신규/수정 wiki 페이지에 domain/<slug> 태그 + author: 표식을 단다
```

## 1. save
```
□ 외부 1차 자료면 save가 아니라 ingest로 우회
□ 카테고리 1개 결정 + 파일명 규칙 준수 (projects는 프로젝트명만)
□ frontmatter 표준 + 첫 줄 한 문장 요약 + 최소 1개 [[link]]
□ index.md 해당 섹션 한 줄 추가 · log.md append · lint 재실행 → 사용자 보고
```

## 2. ingest
```
□ raw/ 원본 read (수정 금지) → wiki/sources/ 1:1 요약 생성
□ 영향 페이지 cross-update (1 소스 → 10~15 페이지 목표. 1~2개면 save였을 가능성)
□ 기존 주장과 모순이면 > [!warning] 표시 (silent overwrite 금지)
□ index/log 갱신 · lint 통과 · 변경 페이지 수 + 핵심 cross-update 보고
```

## 3. lint
```
□ bash scripts/vault-lint.sh 실행 → 항목별 조치 (frontmatter 보강 / index 동기화 /
  broken link 해소 / orphan cross-link / 명명 위반은 dry-run 보고서로)
□ log.md append + 결과 요약 보고
```

## 4. handoff / distill
```
□ 델타 classifier 먼저 — 새 소스·결정·상태·오류·절차가 없으면 노트를 만들지 않는다
□ 프로젝트명 정규화 후 conversations/{폴더}/YYYY-MM-DD-HHMM-{프로젝트}-handover.md
□ 재사용 지식은 같은 턴에 wiki로 승격 (원장에만 남기지 않는다)
```

## 5. 재구성 / 이동 / 삭제 (destructive — 반드시 사용자 승인)
```
□ 승인 없으면 dry-run 보고서(wiki/synthesis/_REVIEW-YYYY-MM-DD-{topic}.md)만 작성 후 중단
□ 승인 후: 한 번에 한 논리 단위 → 이동 후 구경로 참조 grep → lint → log append
□ 계획과 실물이 다르면 계획을 고집하지 말고 증거로 재판정한다
```

## 동시성 (다중 채널 공통)
```
□ log/index/active 갱신은 scripts/vault-append.sh 또는 부분 편집만 — 통째 덮어쓰기 금지
□ 모든 엔트리에 채널 태그 @[채널/이름]
□ git add는 자기가 만든 파일만 명시 경로로 (git add . / -A 절대 금지)
□ 자기 작업은 commit(+push)까지 완결 — 미커밋 방치 = broken link = 오염
□ 다른 채널 미커밋이 떠 있으면 공유 파일 일괄 add 금지
```

## 절대 금지 (lint가 자동 차단하는 것 포함)

- raw/·conversations/ 수정·삭제 · frontmatter 없는 페이지 · 신규 source orphan
- projects 날짜·session 접미사 · 외부 자료 save 직행 · lint FAIL 중 신규 쓰기
- 루트 새 최상위 폴더(제2 창고) · log/index 번호 사본 방치 · 통째 덮어쓰기
- contested 주제 무단 정본화 · 모순 발견 후 장부 미등재 종료
- 자동 도구(링커·포매터 등)가 conversations/raw를 수정하는 것 (autolink 오염 게이트가 FAIL)

## 보고 형식 (모든 작업 종료 시)

```
{operation} 완료.
- 변경: {파일 경로 목록}
- 카테고리/근거: {1줄}
- lint: pass (또는 실패 항목)
- 갱신: index.md, log.md
- 후속 권장: {있으면 1~2줄}
```
