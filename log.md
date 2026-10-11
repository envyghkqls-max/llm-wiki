# Vault Log

> append-only 운영 타임라인. 새 항목은 항상 **파일 끝에** `bash scripts/vault-append.sh log.md "..."`로 추가한다.
> 통째 덮어쓰기·재정렬 금지. 형식(grep 친화):
>
> ```
> ## [YYYY-MM-DD HH:MM] {operation} | {target} @[채널/이름]
> - 무엇을 했는지 1~3줄
> ```
>
> operation: `ingest` | `query` | `lint` | `handoff` | `save` | `manual-edit` | `setup`
