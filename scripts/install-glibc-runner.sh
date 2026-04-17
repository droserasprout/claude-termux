#!/data/data/com.termux/files/usr/bin/sh
# Install glibc-runner. Depends on tur-repo being installed and indexed
# (install-prereqs.sh).
#
# glibc-runner lives in the termux-glibc repo, not tur-repo. `glibc-repo`
# is a tiny shim in tur-repo whose postinst adds the termux-glibc
# sources.list fragment and runs apt update — so we install it first,
# then pull grun.
set -eu
TAG=glibc
. "$(dirname "$0")/_lib.sh"

require_termux
export DEBIAN_FRONTEND=noninteractive

log "installing glibc-repo (adds termux-glibc sources)"
$APT_GET install glibc-repo

log "installing glibc-runner (grun)"
$APT_GET install glibc-runner

command -v grun >/dev/null \
    || die "grun not on PATH after glibc-runner install"

log "grun ready: $(command -v grun)"
