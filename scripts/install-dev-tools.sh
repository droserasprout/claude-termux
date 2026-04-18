#!/data/data/com.termux/files/usr/bin/sh
# Install gh + openssh, configure git identity, generate an SSH key if
# the user doesn't have one, and print the `gh ssh-key add` command.
#
# Fully non-interactive when called with env vars:
#   GIT_USER_NAME="..." GIT_USER_EMAIL="..." make dev-tools
# Otherwise prompts.
set -eu
TAG=dev-tools
. "$(dirname "$0")/_lib.sh"

require_termux
export DEBIAN_FRONTEND=noninteractive

log "installing gh, openssh"
$APT_GET install gh openssh

# --- git identity -------------------------------------------------------
# $1 = git config key, $2 = override value (may be empty), $3 = prompt label
set_git_identity() {
    key="$1"; override="$2"; label="$3"
    cur="$(git config --global "$key" 2>/dev/null || true)"
    if [ -n "$cur" ]; then
        log "git $key already set: $cur"
    elif [ -n "$override" ]; then
        git config --global "$key" "$override"
    elif [ -t 0 ]; then
        printf 'git %s: ' "$label"; read -r val
        [ -n "$val" ] && git config --global "$key" "$val"
    else
        warn "git $key not set and stdin is not a tty — skipping"
    fi
}

set_git_identity user.name  "${GIT_USER_NAME:-}"  user.name
set_git_identity user.email "${GIT_USER_EMAIL:-}" user.email

# --- ssh key ------------------------------------------------------------
KEY="$HOME/.ssh/id_ed25519"
if [ -f "$KEY" ]; then
    log "ssh key already exists: $KEY"
else
    log "generating ed25519 ssh key (no passphrase — Termux has no agent daemon)"
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -N '' -f "$KEY" -C "$(git config --global user.email 2>/dev/null || echo termux)"
fi

log "public key (add it to GitHub):"
printf '\n'
cat "$KEY.pub"
printf '\n'

SSH_TITLE="$(hostname 2>/dev/null || echo termux)"
log "to add via gh:  gh ssh-key add $KEY.pub --title $SSH_TITLE"
log "to auth gh:     gh auth login    (opens browser or device code)"
log "done"
