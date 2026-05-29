#!/usr/bin/env bash
# claude-savepoint installer
#
# Installs three Claude Code skills (/save, /load, /log) that snapshot and
# resume your work session via a single user-chosen history folder.
#
# Usage:
#   Interactive:    ./install.sh
#   Non-interactive: ./install.sh --history-dir <path> [--force]
#   Pipe install:    curl -sSL https://.../install.sh | bash
#
# Env overrides (highest precedence after CLI flags):
#   SAVEPOINT_HISTORY_DIR=<path>   skip the prompt
#   SAVEPOINT_FORCE=1              overwrite existing skills without asking

set -euo pipefail

# ---------- constants ----------
# When run from a checked-out repo, BASH_SOURCE[0] points at this file.
# When run via `curl | bash`, BASH_SOURCE[0] is empty and $0 is "bash" — we
# detect that case below and fetch SKILL.md files from REPO_RAW into a tmpdir.
_self="${BASH_SOURCE[0]:-}"
if [[ -n "$_self" && -f "$_self" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "$_self")" && pwd)"
else
  SCRIPT_DIR=""
fi
SKILLS_DST="$HOME/.claude/skills"
SKILL_NAMES=(save load log)
PLACEHOLDER='__HISTORY_DIR__'
DEFAULT_HISTORY_DIR="$HOME/.claude-savepoint/history"
REPO_RAW="${SAVEPOINT_REPO_RAW:-https://raw.githubusercontent.com/timulys/claude-savepoint/main}"

# ---------- ui helpers ----------
c_reset=$'\033[0m'; c_bold=$'\033[1m'; c_dim=$'\033[2m'
c_green=$'\033[32m'; c_yellow=$'\033[33m'; c_red=$'\033[31m'; c_cyan=$'\033[36m'

info()  { printf "%s[info]%s %s\n"  "$c_cyan"   "$c_reset" "$*"; }
ok()    { printf "%s[ok]%s   %s\n"  "$c_green"  "$c_reset" "$*"; }
warn()  { printf "%s[warn]%s %s\n"  "$c_yellow" "$c_reset" "$*"; }
die()   { printf "%s[err]%s  %s\n"  "$c_red"    "$c_reset" "$*" >&2; exit 1; }

# ---------- arg parse ----------
HISTORY_DIR=""
FORCE="${SAVEPOINT_FORCE:-0}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --history-dir) HISTORY_DIR="${2:-}"; shift 2 ;;
    --force) FORCE=1; shift ;;
    -h|--help)
      sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) die "unknown arg: $1 (use --help)" ;;
  esac
done

# Env var overrides if CLI flag absent.
HISTORY_DIR="${HISTORY_DIR:-${SAVEPOINT_HISTORY_DIR:-}}"

# ---------- locate skill sources ----------
# Prefer local skills/ next to the script (git clone case). Fall back to
# fetching from REPO_RAW into a tmpdir (curl|bash case).
if [[ -n "$SCRIPT_DIR" && -d "$SCRIPT_DIR/skills" ]]; then
  SKILLS_SRC="$SCRIPT_DIR/skills"
  for n in "${SKILL_NAMES[@]}"; do
    [[ -f "$SKILLS_SRC/$n/SKILL.md" ]] || die "missing skill source: $SKILLS_SRC/$n/SKILL.md"
  done
else
  command -v curl >/dev/null 2>&1 || die "curl not found (needed for remote install)"
  TMPDIR_FETCH="$(mktemp -d 2>/dev/null || mktemp -d -t savepoint)"
  trap 'rm -rf "$TMPDIR_FETCH"' EXIT
  info "fetching skills from $REPO_RAW"
  for n in "${SKILL_NAMES[@]}"; do
    mkdir -p "$TMPDIR_FETCH/skills/$n"
    if ! curl -fsSL "$REPO_RAW/skills/$n/SKILL.md" -o "$TMPDIR_FETCH/skills/$n/SKILL.md"; then
      die "failed to fetch skills/$n/SKILL.md from $REPO_RAW"
    fi
  done
  SKILLS_SRC="$TMPDIR_FETCH/skills"
fi

# Detect non-interactive (piped) execution. If no path supplied AND no tty, fall back to default.
if [[ -z "$HISTORY_DIR" ]]; then
  if [[ -t 0 ]]; then
    printf "%sclaude-savepoint%s — installer\n" "$c_bold" "$c_reset"
    printf "\nWhere should session history files be stored?\n"
    printf "  %s(default: %s)%s\n" "$c_dim" "$DEFAULT_HISTORY_DIR" "$c_reset"
    printf "> "
    read -r HISTORY_DIR </dev/tty || true
  fi
  HISTORY_DIR="${HISTORY_DIR:-$DEFAULT_HISTORY_DIR}"
fi

# Expand ~ and resolve relative-to-home paths.
case "$HISTORY_DIR" in
  "~"|"~/"*) HISTORY_DIR="${HOME}${HISTORY_DIR#\~}" ;;
esac
# Make absolute (without requiring the dir to exist yet).
if [[ "$HISTORY_DIR" != /* ]]; then
  HISTORY_DIR="$(pwd)/$HISTORY_DIR"
fi

info "history dir : $HISTORY_DIR"
info "skills dest : $SKILLS_DST"

# ---------- ensure history dir ----------
if [[ ! -d "$HISTORY_DIR" ]]; then
  if [[ -t 0 && "$FORCE" != "1" ]]; then
    printf "history folder does not exist. create it? [Y/n] "
    read -r reply </dev/tty || reply=""
    case "${reply:-Y}" in
      Y|y|"") ;;
      *) die "aborted (history dir missing)";;
    esac
  fi
  mkdir -p "$HISTORY_DIR"
  ok "created $HISTORY_DIR"
fi

# ---------- install each skill ----------
mkdir -p "$SKILLS_DST"

for name in "${SKILL_NAMES[@]}"; do
  src="$SKILLS_SRC/$name/SKILL.md"
  dst_dir="$SKILLS_DST/$name"
  dst="$dst_dir/SKILL.md"

  if [[ -e "$dst" && "$FORCE" != "1" ]]; then
    if [[ -t 0 ]]; then
      printf "%s already exists. overwrite? [y/N] " "$dst"
      read -r reply </dev/tty || reply=""
      case "${reply:-N}" in
        Y|y) ;;
        *)
          warn "skipped $name"
          continue ;;
      esac
    else
      warn "skipped $name (exists, --force not set)"
      continue
    fi
  fi

  mkdir -p "$dst_dir"
  # Backup existing.
  if [[ -e "$dst" ]]; then
    backup="${dst}.bak.$(date +%Y%m%d-%H%M%S)"
    cp "$dst" "$backup"
    info "backed up old $name to $backup"
  fi

  # Copy + substitute placeholder. Use awk for safe literal substitution
  # (sed would need delimiter escaping for paths containing /).
  awk -v repl="$HISTORY_DIR" -v ph="$PLACEHOLDER" '
    { gsub(ph, repl); print }
  ' "$src" >"$dst"

  # Verify substitution.
  if grep -q "$PLACEHOLDER" "$dst"; then
    die "placeholder substitution failed for $name (please report this bug)"
  fi
  ok "installed /$name → $dst"
done

# ---------- record config for updates ----------
# Persist the chosen history dir so update.sh can re-install without re-prompting
# (and without changing where history already lives). %q keeps it shell-safe.
printf 'SAVEPOINT_HISTORY_DIR=%q\n' "$HISTORY_DIR" > "$SKILLS_DST/.savepoint.env"
ok "recorded config → $SKILLS_DST/.savepoint.env"

# ---------- done ----------
printf "\n%s✓ claude-savepoint installed%s\n" "$c_green" "$c_reset"
printf "  history dir : %s\n" "$HISTORY_DIR"
printf "  skills      : %s/{save,load,log}/SKILL.md\n" "$SKILLS_DST"
printf "\n"
printf "Next steps in Claude Code:\n"
printf "  1. open any project\n"
printf "  2. type %s/save%s — confirms install works end-to-end\n"   "$c_bold" "$c_reset"
printf "  3. type %s/log%s to see history, %s/load%s to resume\n"   "$c_bold" "$c_reset" "$c_bold" "$c_reset"
printf "\nUninstall: ./uninstall.sh  (or just %srm -rf %s/{save,load,log}%s)\n" \
  "$c_dim" "$SKILLS_DST" "$c_reset"
