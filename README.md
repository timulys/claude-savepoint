# claude-savepoint

[Claude Code](https://claude.com/claude-code)에서 작업 세션을 **스냅샷**으로 저장하고 나중에 **이어서 진행**할 수 있게 해주는 가벼운 스킬 3종 세트입니다. PC를 옮겨도, 며칠이 지나도 그대로 이어집니다.

```
/save  → 현재 세션 상태를 history 폴더에 저장
/load  → 가장 최근 스냅샷을 읽어 요약하고 작업 재개 제안
/log   → 지난 세션 목록 보기
```

**프로젝트 종속성 없음.** 스킬은 순수 마크다운(SKILL.md 3개)이고, 별도 데몬도 백그라운드 프로세스도 필요 없습니다. 필요한 건 **history 파일을 저장할 폴더 하나뿐**이고, 그 위치는 설치 시점에 사용자가 정합니다.

---

## 설치

### 한 줄 설치 (추천)

```bash
curl -sSL https://raw.githubusercontent.com/timulys/claude-savepoint/main/install.sh | bash
```

설치 스크립트가 history 저장 위치를 묻습니다 (기본값: `~/.claude-savepoint/history`). 그 다음 `~/.claude/skills/{save,load,log}/`에 SKILL.md 3개를 깔아줍니다.

### 직접 받아서 설치

```bash
git clone https://github.com/timulys/claude-savepoint.git
cd claude-savepoint
./install.sh
# 또는 비대화형:
./install.sh --history-dir ~/notes/sessions --force
```

### 설치 확인

Claude Code를 어떤 디렉토리에서든 열고 `/save`를 입력하면 됩니다. 저장 완료 메시지와 함께 새 파일이 history 폴더에 생기면 정상입니다.

---

## 무엇이 설치되나

```
~/.claude/skills/
├── save/SKILL.md
├── load/SKILL.md
└── log/SKILL.md
```

각 SKILL.md 안의 `__HISTORY_DIR__` 자리표시자(placeholder)가 설치 시점에 **사용자가 선택한 history 폴더 절대경로**로 치환되어 있습니다. 이 경로가 세 스킬이 의존하는 **유일한 상태**입니다.

> **추가형(additive) 설치** — 기존 `~/.claude/skills/` 폴더가 있어도, 그 안의 다른 스킬은 일절 건드리지 않고 `save/`, `load/`, `log/` 세 폴더만 추가됩니다. 같은 이름의 스킬이 이미 있으면 백업(`SKILL.md.bak.<timestamp>`) 후 덮어쓰기 여부를 묻습니다.

---

## 동작 방식

### `/save`

대화의 진행 상태(완료한 일, 다음 할 일, 환경 상태, 발견한 이슈, 사용자의 마지막 의도 등)를 분석해 history 폴더에 세 파일을 씁니다:

| 파일 | 역할 |
|---|---|
| `HISTORY-{YYYY-MM-DD-HHmm}.md` | 세션 스냅샷 — 호출할 때마다 새로 생성 |
| `LATEST.md` | 가장 최근 스냅샷 사본 — `/load`가 기본으로 읽음 |
| `INDEX.md` | 모든 스냅샷의 한 줄 인덱스 — `/log`가 읽음 |

### `/load`

기본은 `LATEST.md`를 읽고, 인수로 날짜나 파일명을 주면 그것을 읽습니다. 단순히 본문을 그대로 출력하지 않고 **"어디서부터 이어갈지"를 추출**해 보여줍니다:

- 그때까지 한 일 (한 줄 요약)
- 현재 위치 (프로젝트 / Phase / 마지막 완료 단계)
- 이어서 할 일 (우선순위 순)
- 주의사항 / 미해결
- 환경 상태

추가로 **현재 환경이 history와 일치하는지 자동 검증**합니다. 예를 들어 history엔 Docker 컨테이너 6개가 살아있다고 적혔는데 지금은 3개만 떠 있으면 그 차이를 보고합니다.

### `/log`

`INDEX.md`를 읽어 최근 세션 목록을 표로 출력합니다. 인수로 필터링 가능:

- `/log` — 최근 10개 (기본)
- `/log all` — 전체
- `/log 5` — 최근 5개
- `/log 2026-05-04` — 해당 날짜만
- `/log toy-shop` — 프로젝트명으로 필터
- `/log stats` — 누적 통계

스킬은 모두 **순수 프롬프트**입니다. Claude가 SKILL.md를 읽고 그 지시를 따르는 방식이라, 별도 실행파일도 의존성도 없습니다.

---

## 여러 PC에서 history 공유하기

iCloud Drive, Dropbox, Google Drive, Syncthing, git repo 등 **PC 간에 동기화되는 폴더**를 history 경로로 지정하면 한 PC에서 `/save`, 다른 PC에서 `/load`로 그대로 이어집니다:

```bash
# 노트북 (macOS, iCloud)
./install.sh --history-dir "$HOME/Library/Mobile Documents/com~apple~CloudDocs/claude-history" --force

# 데스크탑 (같은 경로 지정)
./install.sh --history-dir "$HOME/Library/Mobile Documents/com~apple~CloudDocs/claude-history" --force
```

이제 두 PC가 동일한 history를 바라보게 됩니다.

---

## 제거

```bash
./uninstall.sh
```

`~/.claude/skills/`에서 `save/`, `load/`, `log/` 세 폴더만 지웁니다. **history 파일은 어떤 경우에도 자동 삭제되지 않습니다** — 제거는 가역적입니다.

한 줄로 지우는 방법:

```bash
rm -rf ~/.claude/skills/{save,load,log}
```

---

## 설치 옵션

| 플래그 / 환경변수 | 역할 |
|---|---|
| `--history-dir <path>` | 프롬프트 건너뛰고 이 경로 사용 |
| `--force` | 기존 스킬을 묻지 않고 덮어쓰기 |
| `SAVEPOINT_HISTORY_DIR=<path>` | `--history-dir`과 동일 |
| `SAVEPOINT_FORCE=1` | `--force`와 동일 |
| `SAVEPOINT_REPO_RAW=<url>` | 다른 fork/branch에서 SKILL.md fetch (curl\|bash 모드용) |

기존 SKILL.md를 덮어쓰기 전엔 항상 `SKILL.md.bak.<timestamp>` 형태로 자동 백업합니다.

---

## FAQ

**Q. 한 줄 설치 명령에서 입력 프롬프트가 안 받아진다**
A. 일부 터미널에서 `curl | bash` 모드일 때 표준입력이 막힙니다. 그 경우 git clone 방식으로:
```bash
git clone https://github.com/timulys/claude-savepoint.git && cd claude-savepoint && ./install.sh
```

**Q. Claude Code에서 `/save`를 쳤는데 스킬을 못 알아본다**
A. Claude Code를 한 번 종료하고 다시 실행하세요. 새로 추가된 스킬은 다음 세션부터 인식됩니다.

**Q. 비밀번호나 토큰이 history에 저장될까봐 걱정된다**
A. SKILL.md 안에 명시되어 있습니다 — 대화에 비밀번호/토큰/API 키가 등장한 경우 Claude가 저장 시 자동으로 마스킹합니다 (`(민감 정보 마스킹)` 표시).

---

## 라이선스

MIT. [LICENSE](./LICENSE) 참고.
