#!/data/data/com.termux/files/usr/bin/sh
# Download + install Claude Code via the official bootstrap.sh, then
# replace the generated ~/.local/bin/claude symlink with a grun wrapper
# so the glibc-linked binary runs on Termux's bionic libc.
#
# Idempotent: re-running is safe and will re-wrap if the symlink came
# back (e.g. after `claude update`).
set -eu
TAG=install
. "$(dirname "$0")/_lib.sh"

require_termux
ensure_state_dir

command -v grun >/dev/null \
    || die "grun not found — run 'make glibc-runner' first"

# --- fetch + patch bootstrap --------------------------------------------
log "fetching bootstrap.sh"
curl -fsSL "$BOOTSTRAP_URL" -o "$BOOTSTRAP_PATCHED"

# Upstream runs the downloaded binary at the end of the script:
#     "$binary_path" install ${TARGET:+"$TARGET"}
# On Termux this fails (glibc vs bionic), so prefix with grun.
if ! grep -q '"$binary_path" install' "$BOOTSTRAP_PATCHED"; then
    die "bootstrap.sh format changed; expected '\"\$binary_path\" install' line"
fi
log "patching bootstrap to run installer under grun"
sed -i 's#"\$binary_path" install#grun "$binary_path" install#' "$BOOTSTRAP_PATCHED"

# --- run it -------------------------------------------------------------
log "running patched bootstrap (downloads + installs Claude Code)"
bash "$BOOTSTRAP_PATCHED"

[ -e "$LAUNCHER" ] || die "bootstrap did not create $LAUNCHER"

# --- wrap launcher ------------------------------------------------------
log "locating installed claude binary"
if [ -L "$LAUNCHER" ]; then
    REAL_BIN="$(readlink -f "$LAUNCHER")"
elif [ -f "$LAUNCHER" ] && head -c4 "$LAUNCHER" | grep -q ELF; then
    # Already a binary copy (some layouts); use it as-is as the "real".
    REAL_BIN="$LAUNCHER.real"
    mv -f "$LAUNCHER" "$REAL_BIN"
else
    REAL_BIN="$(
        find "$CLAUDE_VERSIONS" -maxdepth 1 -type f 2>/dev/null \
            | sort -V | tail -n1
    )"
fi
[ -n "${REAL_BIN:-}" ] && [ -x "$REAL_BIN" ] \
    || die "could not locate the installed claude binary under $CLAUDE_VERSIONS"
log "real binary: $REAL_BIN"

printf '%s\n' "$REAL_BIN" > "$LAUNCHER_BACKUP"

log "replacing launcher with grun wrapper"
rm -f "$LAUNCHER"
cat > "$LAUNCHER" <<EOF
#!$TERMUX_PREFIX/bin/sh
# claude-termux: wraps the native Claude Code binary with glibc-runner
# (grun) so it can execute on Termux's bionic libc. \`claude update\`
# restores the symlink — re-run \`make install\` or \`make update\` after.
exec grun "$REAL_BIN" "\$@"
EOF
chmod +x "$LAUNCHER"

# --- PATH hygiene -------------------------------------------------------
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *)
        log "adding ~/.local/bin to PATH in shell rc files"
        for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
            [ -f "$rc" ] || continue
            grep -qF '.local/bin' "$rc" \
                || printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$rc"
        done
        ;;
esac

log "verifying"
if "$LAUNCHER" --version; then
    log "✅ claude ready — open a new shell or \`source ~/.bashrc\`, then run: claude"
else
    die "claude --version failed — see output above"
fi
