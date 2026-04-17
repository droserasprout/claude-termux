# shellcheck shell=sh
# Shared helpers for scripts/*. Source me, don't execute me.
#
#   . "$(dirname "$0")/_lib.sh"

TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
STATE_DIR="$HOME/.termux-claude"
CLAUDE_HOME="$HOME/.local/share/claude"
CLAUDE_VERSIONS="$CLAUDE_HOME/versions"
LAUNCHER="$HOME/.local/bin/claude"
LAUNCHER_BACKUP="$STATE_DIR/launcher.orig"
BOOTSTRAP_URL="https://downloads.claude.ai/claude-code-releases/bootstrap.sh"
BOOTSTRAP_PATCHED="$STATE_DIR/bootstrap.patched.sh"

# All apt-get calls go through this — same flags every time.
APT_GET='apt-get -y -o Dpkg::Options::=--force-confnew'

log()  { printf '\033[1;34m[%s]\033[0m %s\n' "${TAG:-claude-termux}" "$*"; }
warn() { printf '\033[1;33m[%s]\033[0m %s\n' "${TAG:-claude-termux}" "$*" >&2; }
die()  { printf '\033[1;31m[%s] %s\033[0m\n' "${TAG:-claude-termux}" "$*" >&2; exit 1; }

require_termux() {
    [ -d "$TERMUX_PREFIX" ] \
        || die "not running inside Termux ($TERMUX_PREFIX missing)"
    command -v pkg >/dev/null \
        || die "pkg not found — is this Termux?"
}

ensure_state_dir() { mkdir -p "$STATE_DIR" "$HOME/.local/bin"; }
