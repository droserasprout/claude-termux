# claude-termux

Install [Claude Code](https://claude.com/claude-code) on stock Termux
(Android) using the **official** `bootstrap.sh` installer, via
`glibc-runner`.

## Status

**Milestone 1 — proof of concept.** One script, one target: make
`claude --version` work. Makefile, updates, tmux, termux-api, gh/ssh
helpers land in M2–M3.

## Why this exists

Every existing guide relies on `npm install -g @anthropic-ai/claude-code`,
which as of late 2025 no longer ships a usable global CLI. The official
path is `bootstrap.sh` — but it downloads a native glibc-linked binary
that won't run on Termux's bionic libc.

This repo bridges the gap: use `glibc-runner` (from `tur-repo`) to run
the official binary, with a launcher shim so `claude` Just Works.

No proot-distro (no chroot overhead). No termux-pacman switch (keeps
your stock Termux). No npm hacks.

## Prerequisites

- **Termux from [F-Droid](https://f-droid.org/en/packages/com.termux/)**
  or [GitHub releases](https://github.com/termux/termux-app/releases).
  The Play Store version is frozen at an old build and will fail.
- Device on aarch64 (any modern Android phone).
- Network access.

## Install

```sh
pkg install -y git
git clone https://github.com/<you>/claude-termux ~/claude-termux
cd ~/claude-termux
sh scripts/install-poc.sh
```

Open a new shell (or `source ~/.bashrc`), then:

```sh
claude --version
claude
```

First launch walks through auth.

## What the script does

1. `pkg install` curl, git, tur-repo, glibc-runner.
2. Downloads the official `bootstrap.sh`.
3. Patches the line that runs `claude install` post-download so the
   installer itself runs under `grun`.
4. Runs the patched bootstrap — this lands the real binary at
   `~/.local/share/claude/<version>/claude` and a launcher at
   `~/.local/bin/claude`.
5. Backs up the generated launcher to `~/.termux-claude/launcher.orig`
   and replaces `~/.local/bin/claude` with a shim:
   ```sh
   exec grun ~/.local/share/claude/<version>/claude "$@"
   ```
6. Adds `~/.local/bin` to your PATH if it isn't already.

Idempotent — safe to re-run.

## Known caveats (PoC stage)

- `claude update` from inside Claude Code probably overwrites the
  shimmed launcher. Workaround for now: re-run `sh scripts/install-poc.sh`
  after any update. Proper fix lands in M2.
- Android's OOM killer can still kill Termux in the background. Use
  `termux-wake-lock` and disable battery optimization for Termux. tmux
  integration lands in M3.
- `glibc-runner` ships a specific glibc version; if Anthropic's binary
  is built against a newer glibc, the bootstrap will fail at the
  `claude install` step. Pin an older version via
  `sh scripts/install-poc.sh` after editing the script to pass a
  version to bootstrap, or wait for `tur-repo` to bump.

## Troubleshooting

- `grun: command not found` after install → `pkg install -y glibc-runner`
  again; confirm `tur-repo` is installed (`pkg list-installed | grep tur-repo`).
- `claude: command not found` → `source ~/.bashrc` (or open a new shell).
- Cryptic glibc errors on launch → open an issue with the output of
  `grun --version` and `~/.local/share/claude/`'s contents.

## Uninstall

```sh
rm -rf ~/.local/bin/claude ~/.local/share/claude ~/.local/state/claude \
       ~/.config/claude ~/.termux-claude
```

## License

MIT.
