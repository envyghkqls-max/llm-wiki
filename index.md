# Vault Index

> 마스터 카탈로그. 모든 wiki 페이지는 여기 등재된다 — 형식: `- [[페이지명]] — 한 줄 요약 (status)`.
> 갱신은 해당 카테고리 섹션에 **부분 편집**으로만 (하단 append 금지 — 카탈로그는 장부가 아니다. 장부는 log.md).

## Status (`wiki/_status/`) — 운영 신뢰성
- [[active]] — 채널 공유 휘발 상태판
- [[contested]] — 신뢰성 장부 (정본 분쟁 추적)

## 도메인 뷰 (cross-cut)
<!-- 도메인 MOC가 생기면 여기 등재 (예: design-moc — 링크 형식으로) -->

## Context (`wiki/context/`)

## Concepts (`wiki/concepts/`)

## Knowledge — 정제수 (`wiki/knowledge/`)
<!-- 도메인별 품질 게이트 통과분만. owner 단일 작성자 -->

## Harnesses (`wiki/harnesses/`)

## Decisions (`wiki/decisions/`)

## Playbooks (`wiki/playbooks/`)

## Projects (`wiki/projects/`)

## Entities (`wiki/entities/`)

## Errors (`wiki/errors/`)

## Synthesis (`wiki/synthesis/`)

## Sources (`wiki/sources/`)

### Legacy (`wiki/sources/legacy/`)

## 카테고리 분포

| 카테고리 | 페이지 수 | 비고 |
|---|---|---|
| sources | 0 | |
| knowledge (정제수) | 0 | |
| projects | 0 | |
| errors | 0 | |
| decisions | 0 | |
| playbooks | 0 | |
| synthesis | 0 | |
| concepts | 0 | |
| entities | 0 | |
| context | 0 | |
| harnesses | 0 | |

> 분포표는 주기적으로 실측(`find`)으로 재생성한다 — 스냅샷이 낡으면 카탈로그와 모순된다.

## 컨벤션 빠른 참조 (전체: CLAUDE.md / AGENTS.md)
- 모든 wiki 페이지는 frontmatter + 첫 줄 요약 필수
- `[[wikilink]]`로 cross-reference. 신규 페이지는 최소 1개 링크
- `status`: seed → growing → mature
- **projects 명명**: 프로젝트명만. 날짜·"session" 접미사 금지
- 신규/수정 후 반드시 `bash scripts/vault-lint.sh` 통과 + log.md append

## 알려진 정리 큐
<!-- lint 결과 기반으로 유지: orphan 목록, _unsorted 잔여, distill 후보 등 -->
