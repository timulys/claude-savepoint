---
name: save
description: Save the current work session state (last completed step, pending requests, next actions, environment state) to the session history folder for resumption later. Use when user types /save or asks to save progress.
---

# /save — 세션 상태 저장

사용자가 `/save`를 호출하면 **현재 대화에서 진행 중이던 작업 상태**를 history 폴더에 저장해 다음 세션에서 이어갈 수 있게 합니다.

## 저장 위치

기본 경로: `__HISTORY_DIR__/`

저장 파일:
1. **`HISTORY-{YYYY-MM-DD-HHmm}.md`** — 새 스냅샷 (매 호출마다 새 파일)
2. **`LATEST.md`** — 가장 최근 저장본 사본 (덮어쓰기). `/load`가 우선 참조
3. **`INDEX.md`** — 모든 저장 이력의 한 줄 인덱스 (append)

## 저장 절차

### Step 1. 폴더 보장
```
__HISTORY_DIR__/  (없으면 mkdir -p)
```

### Step 2. 현재 시각으로 파일명 생성
- 형식: `HISTORY-2026-05-02-0234.md` (YYYY-MM-DD-HHmm)
- macOS: `date '+%Y-%m-%d-%H%M'`로 추출

### Step 3. 대화 컨텍스트를 다음 템플릿으로 정리해 작성

```markdown
---
created: "{ISO datetime}"
session_id: "{HISTORY-{YYYY-MM-DD-HHmm}}"
project: "{현재 진행 중인 프로젝트 이름 — 추론}"
phase: "{현재 Phase — 추론}"
tags:
  - type/session-history
---

# Session History — {YYYY-MM-DD HH:mm}

## 🎯 한 줄 요약
{이번 세션의 핵심 진행 내용 한 줄}

## 📍 현재 위치
- **프로젝트**: {예: toy-shop MSA}
- **마지막으로 완료한 단계**: {예: [Impl]multi-module-setup §11 Hello World 검증}
- **현재 작업 중이던 것**: {예: 없음 (방금 완료) / Phase 1 Day 2 회원가입 API 시작 직전}

## ✅ 이번 세션에서 한 일 (시간순)
1. {작업 1}
2. {작업 2}
3. ...

## 🔥 발견한 이슈 / 함정
- {이슈 1: 설명 + 해결 방법}
- {이슈 2: ...}

## 📝 작성/수정한 파일
- `path/to/file.md` — {무엇을 변경했는지}
- ...

## 💻 환경 상태
- **백그라운드 프로세스**: {살아있는 java/docker 컨테이너 등 — 죽었으면 명시}
- **포트 점유**: {예: 33306 MySQL, 27017 Mongo, ...}
- **인프라 컨테이너**: {예: docker compose ps 결과 요약}

## 🚀 다음에 이어서 할 일 (우선순위 순)
1. **{1순위 다음 작업}** — {간단 설명 + 시작 명령어 또는 파일 경로}
2. {2순위}
3. {3순위}

## ⚠️ 주의사항 / 미해결
- {다음 세션 시작 시 반드시 확인할 것}
- {중단된 백그라운드 작업이 있으면 명시}

## 🔗 관련 문서
- [[Arch]toy-shop]
- [[Phase1]toy-shop-msa-skeleton]
- ...

## 💬 사용자의 마지막 의도
{사용자가 마지막에 한 말 + 무엇을 원했는지}
```

### Step 4. `LATEST.md` 갱신
방금 작성한 내용을 `LATEST.md`로도 동일 내용 복사 (덮어쓰기). `/load`가 항상 이 파일을 본다.

### Step 5. `INDEX.md`에 한 줄 추가 (없으면 헤더와 함께 생성)

```markdown
# Session History Index

| Datetime | File | Project | Phase | 한 줄 요약 |
|---|---|---|---|---|
| 2026-05-02 02:34 | [HISTORY-2026-05-02-0234](HISTORY-2026-05-02-0234.md) | toy-shop | Phase 0 (셋업) | Hello World 검증 완료, 내일 Phase 1 Day 2 시작 |
| ...
```

기존 INDEX.md가 있으면 새 줄을 **표 맨 위에 추가** (가장 최근이 위로).

### Step 6. 사용자에게 보고

다음 형식으로 짧게 응답:

```
✅ 저장 완료

파일: __HISTORY_DIR__/HISTORY-2026-05-02-0234.md
요약: {한 줄 요약}
다음 시작점: {1순위 다음 작업}

내일 `/load` 호출하면 위 내용을 그대로 불러옵니다.
```

## 정보 수집 가이드

대화 컨텍스트를 분석할 때 다음을 추출:

| 항목 | 어디서 찾나 |
|---|---|
| **현재 작업** | 가장 최근 사용자 요청 + 마지막 도구 호출 결과 |
| **완료한 일** | 이번 세션의 모든 도구 호출 / 작성한 파일 |
| **수정 파일** | Edit/Write 도구 호출 대상 |
| **백그라운드 프로세스** | `run_in_background: true` Bash 호출 + 살아있는지 추정 |
| **포트** | 사용자나 도구가 언급한 모든 포트 |
| **이슈/함정** | "에러", "실패", "트러블슈팅" 키워드 + 해결 흐름 |
| **다음 작업** | 사용자가 "다음", "내일", "이어서" 언급한 것 + 추론 |

## 호출 예시

사용자: `/save`

→ 위 절차 그대로 실행. 추가 인수 없음.

사용자: `/save 토이 프로젝트 진행 상황만 저장`

→ 인수가 있으면 한 줄 요약 부분에 사용자 의도 반영.

## 주의사항

- **저장하기 전에 사용자에게 다시 묻지 말 것** — `/save`는 저장 명령. 바로 실행.
- 비밀번호 / 토큰 / API 키가 대화에 등장했다면 **저장에서 제외**하고 "(민감 정보 마스킹)" 표시
- 파일 작성은 `Write` 도구 사용
- INDEX 갱신은 `Read` 후 `Edit` 또는 `Write` 사용 (기존 내용 보존)
