# claude-termux

Install [Claude Code](https://claude.com/claude-code) on stock Termux
(Android) using the official `bootstrap.sh`, via `glibc-runner`.

Anthropic's installer downloads a native glibc binary that won't
run on Termux's bionic libc. This repo runs it under `grun`
(from `tur-repo`'s `glibc-runner`) and shims `~/.local/bin/claude` so
every subsequent invocation is transparently wrapped.

## Prerequisites

- **Termux from [F-Droid](https://f-droid.org/en/packages/com.termux/)**
  or [GitHub releases](https://github.com/termux/termux-app/releases).
  The Play Store build is frozen and will fail on `pkg`.
- aarch64 device (tested on Android 15).
- Network.

## Installation

In Termux:

```sh
pkg install -y git make
git clone https://github.com/droserasprout/claude-termux ~/claude-termux
cd ~/claude-termux
make install
```

Open a new shell (or `source ~/.profile`), then:

```sh
claude --version   # → 2.1.113 (Claude Code)
claude             # interactive; first launch walks through auth
```

## Makefile targets

Run `make` without arguments to see the full list:

```text
Meta
  help                 Show this help
  install              Core install: prereqs + grun + Claude Code
  setup                Alias for `install`
  all                  Everything: core + extras

Core
  prereqs              apt update + full-upgrade, install curl/git/tur-repo
  glibc-runner         Install glibc-runner (grun) from termux-glibc
  claude               Install Claude Code and wrap its launcher with grun
  update               Re-run bootstrap to update Claude Code; re-wrap launcher
  uninstall            Remove Claude payload + repo state (keeps packages, auth)
  doctor               Diagnose the install

Extras
  tmux                 Install tmux + configs/tmux.conf + claude-tmux helper
  termux-api           Install termux-api client (companion app must be sideloaded)
  trigger-permissions  Fire every Android permission popup once
  dev-tools            Install gh + openssh, configure git identity, generate ssh key
  claude-md            Install configs/CLAUDE.md to ~/.claude/CLAUDE.md (Termux profile memory)
```

All scripts are idempotent.

### Notes on extras

- **`tmux`** — prefix `C-a`, compact status bar. `claude-tmux` grabs
  `termux-wake-lock` and attaches to a named session; use it instead
  of bare `claude` to survive the OOM killer.
- **`termux-api`** — the package is just the bridge; you also need the
  [Termux:API companion app](https://f-droid.org/en/packages/com.termux.api/)
  sideloaded. Once both are present, Claude can shell out to
  `termux-clipboard-{get,set}`, `termux-notification`, `termux-toast`,
  `termux-storage-get`, etc.
- **`trigger-permissions`** — probes clipboard, notifications, camera,
  location, Wi-Fi, telephony, contacts, SMS, call log. Tap Allow on
  each; re-run to confirm (should be silent).
- **`claude-md`** — the template teaches Claude about `$PREFIX`,
  `grun`, `termux-*` tools, the OOM killer, and why `~/.profile`
  matters here. Backs up any existing file.
- **`dev-tools`** — interactive by default, or set `GIT_USER_NAME` /
  `GIT_USER_EMAIL` in the env. Prints the pubkey and the
  `gh ssh-key add` command; run `gh auth login` yourself.

## How it works

`make install` is three scripts in a row.

**prereqs** runs `apt update && apt full-upgrade` first — Termux images
drift from their package index over time, and a partial install later
will trip dynamic-linker errors on something like `curl`. With the
system level-set, it pulls `curl`, `git`, and `tur-repo`.

**glibc-runner** is two steps: `glibc-repo` (a tiny shim from
`tur-repo`) registers the `termux-glibc` sources, then `glibc-runner`
itself installs the linker and libs that let glibc ELF binaries execute
under Termux's bionic userland. The command that comes out of this is
`grun`.

**claude** fetches Anthropic's upstream `bootstrap.sh`, `sed`-patches
the final `"$binary_path" install` line so it runs under `grun`, and
executes it. The installer drops the native binary at
`~/.local/share/claude/versions/<ver>` and points `~/.local/bin/claude`
at it as a symlink. We swap the symlink for a two-line shell wrapper
that `exec`s `grun` against the real binary — every subsequent `claude`
invocation is transparently shimmed.

## Caveats

- **`claude update` breaks the launcher.** The self-updater rewrites
  `~/.local/bin/claude` back to a direct symlink, so the next run
  bypasses `grun` and dies. Run `make update` after any version bump to
  re-wrap. A post-update hook is on the roadmap.
- **The OOM killer is undefeated.** If Termux sits in the background
  long enough, Android will reap it and your session goes with it. Run
  Claude under `claude-tmux` (from `make tmux`) — it grabs
  `termux-wake-lock` and re-attaches to a named tmux session so at
  worst you pick up where you left off.
- **glibc ABI mismatch.** If Anthropic ships a binary built against a
  newer glibc than `termux-glibc` currently packages, `claude install`
  fails with a linker error. Either pin an older Claude (pass the
  version to `bootstrap.sh` in `install-claude.sh`), or wait for
  `termux-glibc` to catch up.

## Troubleshooting

- `grun: command not found` → `make glibc-runner`.
- `claude: command not found` → `source ~/.profile` (or open a new
  shell) so `~/.local/bin` is on `PATH`.
- Linker errors on launch → `make doctor` for a full diagnostic; open
  an issue with its output plus `grun --version`.

## Uninstall

```sh
make uninstall
# credentials are kept; add these if you want a full wipe:
rm -rf ~/.claude ~/.claude.json
# packages stay; remove them yourself if you like:
# pkg uninstall glibc-runner glibc-repo
```

## License

MIT.
