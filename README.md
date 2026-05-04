# claude-savepoint

Three lightweight skills for [Claude Code](https://claude.com/claude-code) that let you **snapshot** a session and **resume** it later — across machines, across days.

```
/save  → write session state to a history folder
/load  → read the most recent snapshot, summarize, and offer to resume
/log   → list past sessions
```

No project lock-in. The skills are pure markdown (no scripts, no daemons), and the only thing they need is **one folder** — chosen at install time — to store history files in.

---

## Install

### One-liner (recommended)

```bash
curl -sSL https://raw.githubusercontent.com/timulys/claude-savepoint/main/install.sh | bash
```

The installer asks where to put session history (default: `~/.claude-savepoint/history`), then drops three SKILL.md files into `~/.claude/skills/{save,load,log}/`.

### Manual

```bash
git clone https://github.com/timulys/claude-savepoint.git
cd claude-savepoint
./install.sh
# or non-interactive:
./install.sh --history-dir ~/notes/sessions --force
```

### Verify

Open Claude Code in any directory and run `/save`. You should see a confirmation and a new file under your chosen history folder.

---

## What gets installed

```
~/.claude/skills/
├── save/SKILL.md
├── load/SKILL.md
└── log/SKILL.md
```

Each SKILL.md has the placeholder `__HISTORY_DIR__` replaced with the path you chose during install. That path is the **only** state these skills depend on.

---

## How it works

`/save` writes three files to the history folder:

| File | Purpose |
|---|---|
| `HISTORY-{YYYY-MM-DD-HHmm}.md` | Full snapshot — created fresh each call |
| `LATEST.md` | Copy of the most recent snapshot — `/load` reads this by default |
| `INDEX.md` | One-line table of every snapshot — `/log` reads this |

`/load` reads `LATEST.md` (or a specific date/file you pass) and presents a structured summary: what was done, what's next, what to verify. It also checks the current environment (Docker, ports) against what the snapshot recorded and reports any drift.

`/log` reads `INDEX.md` and shows recent sessions in a table, with optional filters (`/log 5`, `/log toy-shop`, `/log 2026-05-04`).

The skills are **pure prompts** — Claude reads the SKILL.md and follows the instructions. No background processes, no IPC, no extra dependencies.

---

## Multi-machine workflow

Pick a history folder that syncs across your machines (iCloud Drive, Dropbox, a git repo, Syncthing) and point each install at the same path:

```bash
# laptop
./install.sh --history-dir ~/Library/Mobile\ Documents/com~apple~CloudDocs/claude-history

# desktop
./install.sh --history-dir ~/Library/Mobile\ Documents/com~apple~CloudDocs/claude-history
```

Now `/save` on one machine and `/load` on the other.

---

## Uninstall

```bash
./uninstall.sh
```

Removes the three skill folders from `~/.claude/skills/`. **Your history files are never touched** — uninstall is reversible.

---

## Customize the install

| Flag / env | Effect |
|---|---|
| `--history-dir <path>` | Skip the prompt; use this path |
| `--force` | Overwrite existing skills without asking |
| `SAVEPOINT_HISTORY_DIR=<path>` | Same as `--history-dir` |
| `SAVEPOINT_FORCE=1` | Same as `--force` |

Existing SKILL.md files are backed up to `SKILL.md.bak.<timestamp>` before overwrite.

---

## License

MIT. See [LICENSE](./LICENSE).
