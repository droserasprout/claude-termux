#!/data/data/com.termux/files/usr/bin/sh
# Diagnostic report — what's installed, what's wrapped, what's wrong.
set -eu
TAG=doctor
. "$(dirname "$0")/_lib.sh"

require_termux

status=0
check() {
    label="$1"; shift
    if "$@" >/dev/null 2>&1; then
        printf '  \033[1;32m✓\033[0m %s\n' "$label"
    else
        printf '  \033[1;31m✗\033[0m %s\n' "$label"
        status=1
    fi
}

log "environment"
printf '  PREFIX=%s\n' "$TERMUX_PREFIX"
printf '  HOME=%s\n' "$HOME"
printf '  PATH=%s\n' "$PATH"

log "binaries"
check "curl"              command -v curl
check "git"               command -v git
check "grun"              command -v grun
check "launcher exists"   test -f "$LAUNCHER"
launcher_is_wrap() { [ -f "$LAUNCHER" ] && head -n1 "$LAUNCHER" | grep -q '^#!'; }
real_binary_ok()   { real="$(cat "$LAUNCHER_BACKUP" 2>/dev/null)" && [ -x "$real" ]; }
check "launcher is wrap"  launcher_is_wrap
check "real binary"       real_binary_ok

log "runtime"
if [ -x "$LAUNCHER" ]; then
    printf '  claude --version: '
    if out="$("$LAUNCHER" --version 2>&1)"; then
        printf '\033[1;32m%s\033[0m\n' "$out"
    else
        printf '\033[1;31mFAILED\033[0m\n  %s\n' "$out"
        status=1
    fi
fi

log "versions installed"
if [ -d "$CLAUDE_VERSIONS" ]; then
    ls -1 "$CLAUDE_VERSIONS" 2>/dev/null | sed 's/^/  /'
else
    printf '  (none)\n'
fi

exit $status
