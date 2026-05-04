#!/usr/bin/env bash
# claude-savepoint uninstaller — removes the three skills from ~/.claude/skills.
# History files are NEVER deleted; uninstall is reversible.

set -euo pipefail

SKILLS_DST="$HOME/.claude/skills"
SKILL_NAMES=(save load log)

c_reset=$'\033[0m'; c_green=$'\033[32m'; c_yellow=$'\033[33m'; c_red=$'\033[31m'
ok()   { printf "%s[ok]%s   %s\n" "$c_green"  "$c_reset" "$*"; }
warn() { printf "%s[warn]%s %s\n" "$c_yellow" "$c_reset" "$*"; }
die()  { printf "%s[err]%s  %s\n" "$c_red"    "$c_reset" "$*" >&2; exit 1; }

FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

if [[ "$FORCE" != "1" && -t 0 ]]; then
  printf "Remove /save /load /log from %s? [y/N] " "$SKILLS_DST"
  read -r reply </dev/tty || reply=""
  case "${reply:-N}" in Y|y) ;; *) die "aborted" ;; esac
fi

removed=0
for name in "${SKILL_NAMES[@]}"; do
  d="$SKILLS_DST/$name"
  if [[ -d "$d" ]]; then
    rm -rf "$d"
    ok "removed $d"
    removed=$((removed+1))
  else
    warn "$d not found"
  fi
done

printf "\n%s✓ done. %d skill(s) removed.%s\n" "$c_green" "$removed" "$c_reset"
printf "Your history files were NOT touched.\n"
