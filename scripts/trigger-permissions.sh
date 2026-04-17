#!/data/data/com.termux/files/usr/bin/sh
# Run every Termux:API command once to provoke Android's permission
# popups. Run interactively — tap "Allow" on each dialog as it appears.
# Safe: commands read only (no SMS send, no file writes beyond /tmp).
#
# Requires: termux-api package + Termux:API companion app.
set -u
TAG=perms
. "$(dirname "$0")/_lib.sh"

require_termux

command -v termux-clipboard-get >/dev/null \
    || die "termux-api not installed — run 'make termux-api' first"

# pm may not be on PATH for all users — check is best-effort.
if command -v pm >/dev/null && ! pm list packages 2>/dev/null \
        | grep -q '^package:com.termux.api$'; then
    warn "Termux:API companion app missing — popups will not appear."
    warn "install from F-Droid: https://f-droid.org/en/packages/com.termux.api/"
    exit 1
fi

# Each call is wrapped: short timeout, errors ignored (a denied popup is
# a normal outcome here). Give the user a beat between popups.
run() {
    label="$1"; shift
    printf '\033[1;34m[%s]\033[0m %-16s → %s\n' "$TAG" "$label" "$*"
    timeout 5 "$@" >/dev/null 2>&1 || true
    sleep 1
}

log "triggering Android permission dialogs — tap Allow on each"

run "battery"       termux-battery-status
run "clipboard"     termux-clipboard-get
run "notification"  termux-notification --title "claude-termux" --content "permission check"
run "camera"        termux-camera-info
run "location"      termux-location -p network -r once
run "wifi"          termux-wifi-connectioninfo
run "telephony"     termux-telephony-cellinfo
run "contacts"      termux-contact-list
run "SMS"           termux-sms-list -l 1
run "call log"      termux-call-log -l 1

log "done — re-run to confirm (should be silent with no popups)"
