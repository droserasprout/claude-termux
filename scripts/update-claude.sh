#!/data/data/com.termux/files/usr/bin/sh
# Re-run the bootstrap to pull the latest Claude Code, then re-wrap the
# launcher. Identical to install-claude.sh — kept as a separate target
# so the Makefile UX is self-documenting.
set -eu
exec "$(dirname "$0")/install-claude.sh"
