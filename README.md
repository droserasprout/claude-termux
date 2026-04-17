# claude-termux

Install [Claude Code](https://claude.com/claude-code) on stock Termux
(Android) using the **official** `bootstrap.sh`, via `glibc-runner`.

No proot-distro (no chroot overhead). No termux-pacman (keeps your
stock Termux). No npm workaround (dead as of late 2025).

## Status

**Milestone 3 — tmux, termux-api, dev-tools.** Verified on OnePlus 6
(enchilada, LineageOS 15).

## Why

Every existing guide still points at
`npm install -g @anthropic-ai/claude-code`, which no longer ships a
usable global CLI. Anthropic's official path is `bootstrap.sh` — but it
downloads a native glibc binary that won't run on Termux's bionic libc.

This repo bridges that gap: run the official installer under `grun`
(from `tur-repo`'s `glibc-runner`), then shim `~/.local/bin/claude` so
every subsequent invocation is transparently wrapped.

## Prerequisites

- **Termux from [F-Droid](https://f-droid.org/en/packages/com.termux/)**
  or [GitHub releases](https://github.com/termux/termux-app/releases).
  The Play Store build is frozen and will fail on `pkg`.
- aarch64 device (any modern Android phone).
- Network.

## Install

```sh
pkg install -y git make
git clone https://github.com/<you>/claude-termux ~/claude-termux
cd ~/claude-termux
make install
```

Open a new shell (or `source ~/.bashrc`), then:

```sh
claude --version   # → 2.1.113 (Claude Code)
claude             # interactive; first launch walks through auth
```

## Makefile targets

```text
make help           list targets
make install        prereqs + glibc-runner + Claude Code (core)
make all            install + tmux + termux-api + dev-tools (everything)
make prereqs        apt update/upgrade + curl/git/tur-repo
make glibc-runner   install grun from termux-glibc
make claude         install Claude Code + wrap launcher with grun
make update         re-run bootstrap; re-wrap launcher
make tmux           install tmux + configs/tmux.conf + claude-tmux helper
make termux-api     install termux-api client (companion app sideload needed)
make trigger-permissions  fire every Android permission popup once
make dev-tools      install gh + openssh, set git identity, generate ssh key
make claude-md      drop a Termux-aware CLAUDE.md into ~/.claude/
make doctor         diagnose the install
make uninstall      remove Claude payload + repo state (keeps packages + auth)
```

All scripts are idempotent.

### Extras

- **`make tmux`** drops a minimal `~/.tmux.conf` (prefix `C-a`, compact
  status bar) and installs a `claude-tmux` helper that attaches to (or
  creates) a named tmux session before launching Claude and grabs
  `termux-wake-lock`. Use it instead of bare `claude` to survive
  Android's OOM killer.
- **`make termux-api`** installs the CLI client. You also need the
  [Termux:API companion app](https://f-droid.org/en/packages/com.termux.api/)
  sideloaded — the package we install is just the bridge. Once both are
  present, Claude can shell out to `termux-clipboard-{get,set}`,
  `termux-notification`, `termux-toast`, `termux-storage-get`, etc.
- **`make trigger-permissions`** runs each `termux-*` API command once
  so Android raises its grant dialogs (clipboard, notifications,
  camera, location, Wi-Fi, telephony, contacts, SMS, call log). Tap
  Allow on each; re-run to confirm (should be silent the second time).
  Requires the Termux:API companion app.
- **`make claude-md`** drops `configs/CLAUDE.md` to `~/.claude/CLAUDE.md`
  — a Termux-aware profile that teaches Claude about `$PREFIX`, `grun`,
  `termux-*` tools, the OOM killer, and why `~/.profile` matters on
  this platform. Backs up any existing file before overwriting.
- **`make dev-tools`** installs `gh` + `openssh`, sets `git user.name`
  and `user.email` (interactively, or via `GIT_USER_NAME` /
  `GIT_USER_EMAIL` env), and generates an ed25519 SSH key. It prints
  the pubkey and the `gh ssh-key add` command — you still have to run
  `gh auth login` yourself.

## How it works

1. **`make prereqs`** — `apt update && apt full-upgrade` (Termux's
   bundled libs diverge from its mirrors over time; a first-run
   upgrade prevents ABI-mismatch errors), then installs `curl`, `git`,
   `tur-repo`.
2. **`make glibc-runner`** — Installs `glibc-repo` (adds the
   `termux-glibc` sources), then `glibc-runner`. Gives you `grun`.
3. **`make claude`** — Downloads upstream `bootstrap.sh`, sed-patches
   its final `"$binary_path" install` line to prefix `grun`, runs it.
   The installer lands the native binary at
   `~/.local/share/claude/versions/<ver>` and makes `~/.local/bin/claude`
   a symlink to it. We replace the symlink with a shell wrapper that
   `exec grun <real> "$@"`.

## Caveats

- **`claude update` (from inside Claude) will restore the symlink** and
  bypass `grun`, breaking the command. Workaround: run `make update`
  after any version bump. A post-update hook is on the roadmap.
- **Android's OOM killer** can still kill Termux in the background.
  `termux-wake-lock` helps; tmux integration lands in M3.
- **glibc ABI mismatch** — if Anthropic's binary is built against a
  newer glibc than `glibc-runner` ships, `claude install` will fail.
  Pin an older Claude by editing `install-claude.sh` to pass a version
  to bootstrap, or wait for `termux-glibc` to bump.

## Troubleshooting

- `grun: command not found` → `make glibc-runner`.
- `claude: command not found` → `source ~/.bashrc` (or open a new
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
