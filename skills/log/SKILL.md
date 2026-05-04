---
name: log
description: Show the work session history (recent entries from the session history folder's INDEX.md). Use when user types /log or asks to see what they have been working on.
---

# /log — 작업 이력 보기

사용자가 `/log`를 호출하면 history 폴더의 `INDEX.md`를 읽어 **최근 작업 이력**을 보여줍니다.

## 기본 동작

### Step 1. INDEX.md 읽기

기본 경로: `__HISTORY_DIR__/INDEX.md`

- 없으면 "이력 없음. `/save`로 첫 저장을 만들어보세요." 안내
- 있으면 `Read`로 읽음

### Step 2. 최근 N개 표시 (기본 10개)

읽은 INDEX의 표를 최근 10개만 사람이 읽기 좋은 형태로 출력:

```markdown
📜 작업 이력 (최근 10개)

| # | 일시 | 프로젝트 | Phase | 한 줄 요약 |
|---|---|---|---|---|
| 1 | 2026-05-02 02:34 | toy-shop | Phase 0 | Hello World 검증 완료, Day 2 직전 |
| 2 | 2026-04-29 16:00 | toy-shop | 문서 | Codex v1.3 패치 완료 |
| 3 | ...
```

뒤이어:
```
👉 자세히 보려면 `/load <번호>` 또는 `/load HISTORY-2026-05-02-0234`
👉 가장 최근으로 이어가려면 `/load`
```

## 인수 모드

- `/log` — 최근 10개 (기본)
- `/log all` — 전체
- `/log {N}` — 최근 N개 (예: `/log 5`)
- `/log {YYYY-MM-DD}` — 해당 날짜 항목만
- `/log {project}` — 프로젝트명으로 필터 (예: `/log toy-shop`)

## 통계 모드 (선택)

`/log stats`:
```markdown
📊 작업 이력 통계

- 총 세션 수: 24
- 첫 세션: 2026-04-23
- 가장 최근: 2026-05-02
- 프로젝트별 빈도:
  - toy-shop: 18회
  - 기타: 6회
- 평균 세션 간격: 2.3일
```

INDEX.md를 분석해 통계 산출.

## 출력 가이드

- **테이블은 짧게**. 한 줄이 너무 길면 한 줄 요약을 자르거나 ellipsis(`...`)로 줄임
- 번호는 1부터 시작 (가장 최근이 1번)
- 사용자가 자주 본 항목은 `⭐` 표시 (선택)
- 히스토리가 비었으면 빈 메시지 + `/save` 안내

## 주의사항

- INDEX.md는 단순히 인덱스. 본문은 `/load`에서 보여줌
- 표가 깨지면 INDEX.md 자체를 검사 (사용자가 수동 편집했을 수도)
- 절대 history 본문 전체를 출력하지 말 것 (그건 `/load`가 할 일)
