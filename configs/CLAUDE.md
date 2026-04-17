# Termux environment (claude-termux)

Claude Code is running inside **Termux on Android** via `glibc-runner`.
The host is a single-user Android app sandbox, not a normal Linux box.

## Device

- Android: {{ANDROID_VERSION}}
- ROM: {{ROM}}
- Model: {{MODEL}}

## Paths

- `$PREFIX` = `/data/data/com.termux/files/usr` — all packages live here
- `$HOME`   = `/data/data/com.termux/files/home`
- `$TMPDIR` = `$PREFIX/tmp` (no `/tmp`); use `$TMPDIR/claude-termux/` for scratch
- `~/.local/bin/claude` is a shell wrapper around `grun <native-binary>`
- `/sdcard` is the phone's shared storage; write here to share with other apps

## Constraints

- Termux runs as an Android app sandbox (uid ≥ 10000). No `sudo`, no `systemd`.
- The host Android may be rooted — `command -v su` tells you. Don't assume.
- No `/etc`, `/var`, `/usr/bin` in the normal places — paths are under `$PREFIX`.
- Port < 1024 is unusable. Use 1025+.
- The default login shell is bash; `~/.profile` is read (not `~/.bashrc`).
- Android's OOM killer can reap Termux when backgrounded. `claude-tmux`
  grabs `termux-wake-lock` to mitigate, but long jobs can still die.

## Package management

- `pkg install <name>` (thin wrapper over `apt`). `apt` / `apt-get` also work.
- `glibc-repo` + `glibc-runner` from `tur-repo` provide `grun` for
  running upstream glibc binaries.

## Android bridge — Termux:API

If `termux-api` is installed **and** the Termux:API companion app is
sideloaded, the following commands shell out to Android services:

- `termux-clipboard-get` / `termux-clipboard-set` — Android clipboard
- `termux-notification` — post a notification (supports `--action`, `--button*`)
- `termux-toast "text"` — floating toast
- `termux-battery-status` — JSON battery info
- `termux-location -p network -r once` — GPS/network location
- `termux-wifi-connectioninfo` / `termux-wifi-scaninfo` — Wi-Fi state
- `termux-telephony-cellinfo` / `termux-telephony-deviceinfo` — phone state
- `termux-contact-list`, `termux-sms-list`, `termux-call-log` — PIM data
- `termux-camera-info` / `termux-camera-photo` — camera
- `termux-microphone-record` — audio
- `termux-tts-speak` — text-to-speech
- `termux-vibrate` — haptic
- `termux-storage-get <path>` — opens SAF picker to import a file
- `termux-share` — Android share sheet
- `termux-fingerprint` — biometric prompt
- `termux-sensor -l` — list sensors; `-s <name> -n 1` for one reading

All return JSON on stdout. Permissions are granted per-API on first
invocation (popup). If a command hangs with no output, the permission
was denied or the companion app is missing.

## Dev tools (if `make dev-tools` was run)

- `gh` (GitHub CLI) + `openssh` are installed
- An ed25519 key at `~/.ssh/id_ed25519` (no passphrase — Termux has no
  agent daemon)
- `git user.name` and `user.email` are configured

## Conventions for Claude in this environment

- Prefer single-file shell scripts with `#!/data/data/com.termux/files/usr/bin/sh`
- Use `$PREFIX` and `$HOME` explicitly; never hardcode `/usr` or `/home/<user>`
- `apt-get -y -o Dpkg::Options::=--force-confnew` is the project's standard
  apt invocation — see `scripts/_lib.sh` in the claude-termux repo
- When a task involves Android-side data (clipboard, location, SMS, etc.),
  reach for `termux-*` commands before anything else
- Long-running work should be launched from inside `tmux` (the
  `claude-tmux` helper attaches to a persistent session)
- When suggesting edits to shell init, write to `~/.profile`, not
  `~/.bashrc` — Termux's default bash is a login shell
- Scratch files go under `$TMPDIR/claude-termux/` (create with `mkdir -p` on
  first use). Don't dump into `$TMPDIR` directly — it's shared with Termux
  itself and other tools.
