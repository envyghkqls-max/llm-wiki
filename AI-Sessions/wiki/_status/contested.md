---
type: status
title: Contested & Stale 신뢰성 장부
updated: ''
verified: ''
---
> 미해결 충돌·오염·stale을 한 곳에서 추적한다. **모든 에이전트는 boot 시 이 장부를 먼저 읽고**,
> Unresolved 주제는 "최신이라도 정본 아님"으로 취급한다. 정본 판단은 `source_of_truth` + 사용자.

## 사용법
- 모순/오염/stale 발견 → 아래 표에 한 행 추가 (상태 Unresolved) + 해당 wiki 페이지 frontmatter `contested: true`.
- 사용자가 정본 확정 → 상태 Resolved, 해당 페이지 `source_of_truth` 명시 + `contested: false`.
- 시간순 자연 진화면 상태 Evolution.

## 장부

| 주제 | 정본(source_of_truth) | 이의·오염(contested_by) | 상태 | 갱신일 |
|---|---|---|---|---|
