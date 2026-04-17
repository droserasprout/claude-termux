#!/data/data/com.termux/files/usr/bin/sh
# Sync package index, full-upgrade (avoids ABI skew from a stale
# bootstrap), install the few deps every other script needs.
set -eu
TAG=prereqs
. "$(dirname "$0")/_lib.sh"

require_termux
ensure_state_dir

export DEBIAN_FRONTEND=noninteractive

log "syncing package index + full-upgrade (first-run sync can take a minute)"
# Fresh Termux bootstraps ship older openssl than libngtcp2 expects —
# partial `apt install` then trips a dynamic-linker error on curl. Full
# upgrade before touching anything else avoids this.
$APT_GET update
$APT_GET full-upgrade

log "installing curl, git, tur-repo"
$APT_GET install curl git tur-repo

# tur-repo drops a sources.list fragment the current index doesn't know
# about yet — the next stage needs the fresh listing.
log "refreshing index for tur-repo"
$APT_GET update

log "done"
