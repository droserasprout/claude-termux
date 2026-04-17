#!/data/data/com.termux/files/usr/bin/sh
# Remove Claude Code payloads and this repo's runtime state. Leaves
# tur-repo / glibc-runner packages and auth credentials alone — remove
# those separately if you want a truly clean slate.
set -eu
TAG=uninstall
. "$(dirname "$0")/_lib.sh"

require_termux

for path in \
    "$LAUNCHER" \
    "$CLAUDE_HOME" \
    "$HOME/.local/state/claude" \
    "$HOME/.config/claude" \
    "$STATE_DIR"
do
    if [ -e "$path" ]; then
        log "removing $path"
        rm -rf "$path"
    fi
done

log "done — credentials in ~/.claude/ and ~/.claude.json were kept"
log "remove those too if you want a clean re-auth"
