#!/data/data/com.termux/files/usr/bin/sh
# Drop configs/CLAUDE.md into ~/.claude/CLAUDE.md so Claude Code picks
# it up as user-scoped memory. Backs up an existing file if its content
# differs — never overwrites silently.
set -eu
TAG=claude-md
. "$(dirname "$0")/_lib.sh"

require_termux

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO_ROOT/configs/CLAUDE.md"
DST="$HOME/.claude/CLAUDE.md"

[ -f "$SRC" ] || die "CLAUDE.md template not found at $SRC"

mkdir -p "$HOME/.claude"

if [ -e "$DST" ] && ! cmp -s "$SRC" "$DST"; then
    BAK="$DST.bak.$(date +%Y%m%d-%H%M%S)"
    log "backing up existing $DST to $BAK"
    cp "$DST" "$BAK"
fi

log "installing $DST"
cp "$SRC" "$DST"

log "done — Claude Code will load this as user memory on next launch"
