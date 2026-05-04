---
name: load
description: Load the most recent saved session state from the session history folder (LATEST.md) and present a summary so the user can immediately resume work. Use when user types /load or asks to resume previous session.
---

# /load — 직전 세션 상태 불러오기

사용자가 `/load`를 호출하면 history 폴더의 `LATEST.md`(또는 지정된 파일)를 읽어 **이전 세션의 진행 상태를 요약**해 보여주고, 사용자가 바로 작업을 이어갈 수 있게 합니다.

## 기본 동작

### Step 1. 파일 읽기

기본 경로: `__HISTORY_DIR__/LATEST.md`

- `LATEST.md`가 존재하면 그것을 `Read`로 읽음
- 없으면 `INDEX.md`에서 최상단 항목 파일을 대신 읽음
- 둘 다 없으면 "저장된 세션 없음. 먼저 `/save`로 저장하세요." 안내

### Step 2. 사용자 친화적 요약 제시

읽은 history 파일에서 다음 4가지를 추출해 **간결하게** 보여줍니다 (전체 본문을 그대로 출력 ❌):

```markdown
📂 마지막 세션 불러옴 ({저장 일시})

🎯 **그때까지 한 일**: {한 줄 요약}

📍 **현재 위치**:
  - 프로젝트: {project}
  - Phase: {phase}
  - 마지막 완료: {마지막으로 완료한 단계}

🚀 **이어서 할 일** (우선순위 순):
  1. {1순위 다음 작업}
  2. {2순위}
  3. {3순위}

⚠️ **확인할 것**:
  - {주의사항 / 미해결 항목}

💻 **환경 상태**:
  - 백그라운드 프로세스: {살아있는 것}
  - 인프라: {Docker 컨테이너 등}

원본: __HISTORY_DIR__/{파일명}
```

### Step 3. 환경 검증 (자동)

요약 출력 후 **현재 환경이 history와 일치하는지 빠르게 검증**:

- Docker 컨테이너 상태: `docker compose ps` (해당 프로젝트 폴더가 명시되어 있으면)
- 포트 점유: history에 명시된 백그라운드 프로세스 포트 점검
- 차이가 있으면 사용자에게 보고 (예: "history에는 toy-redis가 살아있다고 했는데 현재 죽어 있음")

### Step 4. 다음 행동 제안

요약 끝에 "지금 바로 시작할 1순위"를 한 문장으로 제시하고 사용자 확인을 기다림:

```
바로 진행할까요? 1순위는 "{1순위 작업}" 입니다.
- A. 그대로 진행
- B. 다른 항목부터
- C. 환경 점검만 하고 잠시 대기
```

## 파일 지정 모드

사용자: `/load 2026-04-29`
→ `__HISTORY_DIR__/HISTORY-2026-04-29-*.md` 패턴 매칭. 여러 개면 그 날짜 중 가장 최근.

사용자: `/load HISTORY-2026-04-29-1530`
→ 정확한 파일명으로 로드.

사용자: `/load list`
→ `/log`로 위임.

## 주의사항

- **History 본문 전체를 그대로 출력하지 말 것.** 사용자가 보고 싶은 건 "어디서부터 이어갈지"지 옛 기록 전부가 아님.
- History에 명시된 파일 경로가 실제로 존재하는지 검증 (없어졌으면 알림)
- 백그라운드 프로세스가 history 시점과 다르면 명확히 보고 (`Discovery Server는 종료된 상태`)
- 사용자가 "/load 후 바로 시작" 의도면 다음 도구 호출까지 자동으로 (단, 위험한 작업이면 확인)
