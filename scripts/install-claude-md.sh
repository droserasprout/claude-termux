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

# --- device-info substitution ------------------------------------------
# getprop is available to every Android app (including Termux) without
# extra permissions. Each falls back to 'unknown' on failure.
ANDROID_VERSION="$(getprop ro.build.version.release 2>/dev/null || echo unknown)"
MODEL="$(getprop ro.product.model 2>/dev/null || echo unknown)"
# Prefer LineageOS marker; fall back to generic build id.
ROM="$(getprop ro.lineage.version 2>/dev/null)"
[ -z "$ROM" ] && ROM="$(getprop ro.build.display.id 2>/dev/null || echo unknown)"

log "device: Android $ANDROID_VERSION / $ROM / $MODEL"

if [ -e "$DST" ]; then
    BAK="$DST.bak.$(date +%Y%m%d-%H%M%S)"
    log "backing up existing $DST to $BAK"
    cp "$DST" "$BAK"
fi

log "installing $DST"
# `|` delimiter so ROM strings with `/` don't break sed.
sed \
    -e "s|{{ANDROID_VERSION}}|$ANDROID_VERSION|g" \
    -e "s|{{ROM}}|$ROM|g" \
    -e "s|{{MODEL}}|$MODEL|g" \
    "$SRC" > "$DST"

log "done — Claude Code will load this as user memory on next launch"
