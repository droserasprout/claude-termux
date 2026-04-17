#!/data/data/com.termux/files/usr/bin/sh
# Install the termux-api package (client-side). Requires the companion
# Android app (Termux:API) to actually do anything. We check that it's
# present and print install instructions if not.
set -eu
TAG=termux-api
. "$(dirname "$0")/_lib.sh"

require_termux
export DEBIAN_FRONTEND=noninteractive

log "installing termux-api (client)"
$APT_GET install termux-api

# Check if the companion app is installed. It's a separate APK.
if command -v pm >/dev/null && pm list packages 2>/dev/null \
        | grep -q '^package:com.termux.api$'; then
    log "Termux:API companion app detected"
else
    warn "Termux:API companion app not installed"
    warn "install from F-Droid: https://f-droid.org/en/packages/com.termux.api/"
    warn "or GitHub releases: https://github.com/termux/termux-api/releases"
    warn "(the 'termux-api' package we just installed is just the client;"
    warn " the companion app provides the actual OS bridge)"
fi

log "quick sanity check: termux-clipboard-get (may prompt for permission)"
if timeout 3 termux-clipboard-get >/dev/null 2>&1; then
    log "✅ termux-api is functional"
else
    warn "termux-clipboard-get didn't respond — companion app likely missing"
    warn "or needs permissions grant; try running it once interactively"
fi

log "done — Claude Code can now shell out to: termux-clipboard-{get,set},"
log "  termux-notification, termux-toast, termux-storage-get, etc."
