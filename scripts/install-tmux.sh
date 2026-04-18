#!/data/data/com.termux/files/usr/bin/sh
# Install tmux + drop the repo's tmux.conf. Also installs a `claude-tmux`
# helper that attaches to (or creates) a named tmux session before
# launching Claude Code — so an OOM-killed Termux doesn't lose it.
set -eu
TAG=tmux
. "$(dirname "$0")/_lib.sh"

require_termux
export DEBIAN_FRONTEND=noninteractive

log "installing tmux"
$APT_GET install tmux

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO_ROOT/configs/tmux.conf"
DST="$HOME/.tmux.conf"
[ -f "$SRC" ] || die "tmux.conf not found at $SRC"

if [ -e "$DST" ] && ! cmp -s "$SRC" "$DST"; then
    log "backing up existing ~/.tmux.conf to ~/.tmux.conf.bak"
    mv "$DST" "$DST.bak"
fi

log "installing ~/.tmux.conf"
cp "$SRC" "$DST"

# ~/.local/bin is PATH'd by install-claude.sh; this just drops a helper there.
WRAPPER="$HOME/.local/bin/claude-tmux"
log "installing claude-tmux helper at $WRAPPER"
cat > "$WRAPPER" <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
# claude-tmux: run Claude Code inside a persistent tmux session so the
# OS killing Termux in the background doesn't lose the session.
SESSION="${CLAUDE_TMUX_SESSION:-claude}"
termux-wake-lock 2>/dev/null || true
if tmux has-session -t "$SESSION" 2>/dev/null; then
    exec tmux attach -t "$SESSION"
else
    exec tmux new-session -s "$SESSION" claude "$@"
fi
EOF
chmod +x "$WRAPPER"

log "done — run 'claude-tmux' to start Claude in a persistent session"
log "tip: 'termux-wake-lock' is enabled automatically by the wrapper"
