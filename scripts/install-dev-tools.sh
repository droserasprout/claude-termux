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
cur_name="$(git config --global user.name  2>/dev/null || true)"
cur_email="$(git config --global user.email 2>/dev/null || true)"

if [ -z "$cur_name" ]; then
    if [ -n "${GIT_USER_NAME:-}" ]; then
        git config --global user.name "$GIT_USER_NAME"
    elif [ -t 0 ]; then
        printf 'git user.name: '; read -r name
        [ -n "$name" ] && git config --global user.name "$name"
    else
        warn "git user.name not set and stdin is not a tty — skipping"
    fi
else
    log "git user.name already set: $cur_name"
fi

if [ -z "$cur_email" ]; then
    if [ -n "${GIT_USER_EMAIL:-}" ]; then
        git config --global user.email "$GIT_USER_EMAIL"
    elif [ -t 0 ]; then
        printf 'git user.email: '; read -r email
        [ -n "$email" ] && git config --global user.email "$email"
    else
        warn "git user.email not set and stdin is not a tty — skipping"
    fi
else
    log "git user.email already set: $cur_email"
fi

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

log "to add via gh:  gh ssh-key add $KEY.pub --title enchilada"
log "to auth gh:     gh auth login    (opens browser or device code)"
log "done"
