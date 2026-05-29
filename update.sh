#!/usr/bin/env bash
# claude-savepoint updater
#
# Re-installs the latest /save /load /log skills WITHOUT changing where your
# history already lives. The previously chosen history dir is reused, so this
# is safe to run any time you want to pull the newest skill versions.
#
# Usage:
#   In a clone:    ./update.sh
#   From anywhere: curl -fsSL https://raw.githubusercontent.com/timulys/claude-savepoint/main/update.sh -o /tmp/savepoint-update.sh && bash /tmp/savepoint-update.sh
#
# How the history dir is resolved (first match wins):
#   1. $SKILLS_DST/.savepoint.env        (written by install.sh)
#   2. parsed from the installed save/SKILL.md
#   3. ~/.claude-savepoint/history        (default)

set -euo pipefail

SKILLS_DST="$HOME/.claude/skills"
CONF="$SKILLS_DST/.savepoint.env"
DEFAULT_HISTORY_DIR="$HOME/.claude-savepoint/history"
REPO_RAW="${SAVEPOINT_REPO_RAW:-https://raw.githubusercontent.com/timulys/claude-savepoint/main}"

c_reset=$'\033[0m'; c_green=$'\033[32m'; c_cyan=$'\033[36m'; c_red=$'\033[31m'
info() { printf "%s[update]%s %s\n" "$c_cyan"  "$c_reset" "$*"; }
ok()   { printf "%s[ok]%s     %s\n" "$c_green" "$c_reset" "$*"; }
die()  { printf "%s[err]%s    %s\n" "$c_red"   "$c_reset" "$*" >&2; exit 1; }

# ---------- resolve history dir ----------
HISTORY_DIR=""

# 1) config written at install time
if [[ -f "$CONF" ]]; then
  # shellcheck disable=SC1090
  . "$CONF" || true
  HISTORY_DIR="${SAVEPOINT_HISTORY_DIR:-}"
fi

# 2) parse from installed save skill — line: 기본 경로: `<dir>/`
if [[ -z "$HISTORY_DIR" && -f "$SKILLS_DST/save/SKILL.md" ]]; then
  line="$(grep -m1 '기본 경로: `' "$SKILLS_DST/save/SKILL.md" 2>/dev/null || true)"
  if [[ -n "$line" ]]; then
    d="${line#*\`}"; d="${d%%\`*}"; d="${d%/}"
    [[ -n "$d" ]] && HISTORY_DIR="$d"
  fi
fi

# 3) default
HISTORY_DIR="${HISTORY_DIR:-$DEFAULT_HISTORY_DIR}"
info "history dir : $HISTORY_DIR  (preserved)"

# ---------- run the latest installer ----------
# Clone mode: script lives on disk next to a git repo  -> git pull + local install
# Remote mode: no local repo                            -> download installer to a
#              temp file and run it (we intentionally avoid piping a download
#              straight into a shell; a partial download could otherwise run a
#              half-written script).
_self="${BASH_SOURCE[0]:-}"
SCRIPT_DIR=""
if [[ -n "$_self" && -f "$_self" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "$_self")" && pwd)"
fi

if [[ -n "$SCRIPT_DIR" && -d "$SCRIPT_DIR/.git" && -f "$SCRIPT_DIR/install.sh" ]]; then
  info "clone mode — git pull + local install"
  git -C "$SCRIPT_DIR" pull --ff-only || die "git pull failed (resolve clone state, then retry)"
  "$SCRIPT_DIR/install.sh" --history-dir "$HISTORY_DIR" --force
else
  command -v curl >/dev/null 2>&1 || die "curl not found (needed for remote update)"
  info "remote mode — downloading latest installer from $REPO_RAW"
  tmp="$(mktemp 2>/dev/null || mktemp -t savepoint-install)"
  trap 'rm -f "$tmp"' EXIT
  curl -fsSL "$REPO_RAW/install.sh" -o "$tmp" || die "failed to download installer"
  bash "$tmp" --history-dir "$HISTORY_DIR" --force
fi

ok "updated. Start a NEW Claude Code session to pick up the changes."
