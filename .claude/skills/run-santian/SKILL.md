---
name: run-santian
description: Build, run, and drive the Santian Flutter app on an Android emulator. Use when asked to start/run Santian, take a screenshot of its UI, verify a change works in the real app, or drive it through a flow (create/complete/delete a task, toggle dark mode).
---

Santian is an Android-only Flutter app (no `windows/`/`ios/` platform dirs -
only `android/`) driven here via `adb` from Git Bash on Windows. There is no
Playwright/tmux harness for it - the driver is
`.claude/skills/run-santian/driver.sh`, a thin wrapper over `adb`/
`uiautomator` that launches the app, takes screenshots, and taps/types by
resolving on-screen element bounds instead of guessed pixel coordinates.

All paths below are relative to the repo root (`D:\Projects\Dev\Santian`).

## Prerequisites

Already-installed toolchain used to verify this skill (Windows host, Git
Bash as the shell):

- Flutter 3.41.4 (stable) / Dart 3.11.1 - `flutter --version`
- Android SDK platform-tools, with `adb.exe` at
  `D:\Android\Sdk\platform-tools\adb.exe` (not on `PATH` in Git Bash)
- An AVD: `Pixel_3a_API_35_extension_level_13_x86_64` (`flutter emulators`
  lists it)

No package install step was needed beyond `flutter pub get` (below) - the
SDKs were already present on this machine.

## Setup

```bash
flutter pub get
```

## Run (agent path)

Use the driver, `.claude/skills/run-santian/driver.sh`. It auto-detects
`adb` (falls back to the hardcoded SDK path above if `adb` isn't on `PATH`)
and the first attached device, both overridable via env vars - see the
comment header in the script for the full list.

```bash
# 1. Launch: boots the AVD if nothing's attached, runs `flutter run` in the
#    background, and blocks until the build either succeeds or fails. First
#    build is a cold Gradle build and commonly takes 3-6 minutes; this is
#    normal, not a hang.
bash .claude/skills/run-santian/driver.sh launch

# 2. Drive it.
bash .claude/skills/run-santian/driver.sh screenshot my-shot   # -> artifacts/my-shot.png
bash .claude/skills/run-santian/driver.sh find "Create task"   # locate an element
bash .claude/skills/run-santian/driver.sh tap-text "Create task"
bash .claude/skills/run-santian/driver.sh type "Buy milk"
bash .claude/skills/run-santian/driver.sh key enter
bash .claude/skills/run-santian/driver.sh dark yes              # toggle dark theme
```

Screenshots and the pulled `uiautomator` dump land in
`.claude/skills/run-santian/artifacts/` (gitignored). View a screenshot with
the Read tool - this script only captures pixels, it can't render them.

| command | what it does |
|---|---|
| `launch [timeout_s]` | Boot emulator if needed, `flutter run -d <device>` in background, wait for ready (default timeout 600s) |
| `wait-ready [timeout_s]` | Just the wait, if you backgrounded `launch` yourself |
| `status` | Show `adb devices` + whether a `flutter run` process is alive |
| `relaunch` | Fast re-open via `am start` (no rebuild) - use after the app exits unexpectedly |
| `screenshot <name>` | Save `artifacts/<name>.png`, print its path |
| `dump` | uiautomator-dump the current screen, print every `text=`/`content-desc=`/`bounds=` triple |
| `find <needle>` | `dump` filtered to elements matching `<needle>` (case-insensitive), with each match's tap-ready center coordinate |
| `tap <x> <y>` | `adb input tap` at raw device-pixel coordinates (as printed by `dump`/`find` - do not scale from a shrunk screenshot preview) |
| `tap-text <needle>` | Resolve `<needle>` via `find` and tap its center; fails loudly if it's not exactly one match |
| `type <text>` | `adb input text`, with spaces handled for you |
| `key <name-or-code>` | `adb input keyevent`; accepts `enter`/`back`/`home` or a raw code |
| `dark <yes\|no>` | Toggle system dark mode (the app follows `ThemeMode.system`) |
| `stop` | `am force-stop` the app (does not stop the emulator or `flutter run`) |

## Run (human path)

```bash
flutter run -d emulator-5554   # or whatever `flutter devices` lists
```
Opens the app with hot reload in the foreground; `q` to quit. Not useful for
an agent - no way to see the window without a screenshot step, which is what
the driver automates.

## Test

```bash
flutter test
```
217 tests, all passing as of this session (~44s). CI (`.github/workflows/ci.yml`)
additionally runs `flutter analyze` and re-runs `dart run build_runner build`
to fail on drifted generated (`*.g.dart`) Isar code.

---

## Gotchas

- **`adb` isn't on `PATH` in Git Bash.** The driver falls back to
  `D:\Android\Sdk\platform-tools\adb.exe`; override with `ADB_BIN` if yours
  lives elsewhere.

- **Git Bash silently mangles device-side absolute paths.** Any bare
  `/sdcard/...` argument passed to a native Windows exe (`adb.exe`) gets
  rewritten to a bogus Windows-rooted path (e.g.
  `C:/Program Files/Git/sdcard/window_dump.xml`) *before adb ever sees it*.
  This bit us badly: with only the `adb pull` call protected by
  `MSYS_NO_PATHCONV=1` and not the `adb shell uiautomator dump` call, the
  dump silently wrote to the wrong (bogus) path every time, so the
  subsequent "successful" pull just kept re-fetching an arbitrarily old
  leftover `/sdcard/window_dump.xml` from hours earlier in the session. It
  looked exactly like a stuck/stale accessibility tree - we spent real time
  chasing it with `adb reboot`, `adb kill-server`/`start-server`, and app
  force-stop/relaunch, none of which touched the actual cause. **Both** the
  `uiautomator dump` call and the `pull` call need `MSYS_NO_PATHCONV=1`; the
  driver now sets it on both. If `find`/`tap-text`/`dump` ever look wrong
  again, don't reach for a reboot first - screenshot the real screen and
  compare against what `dump` reported.

- **`adb pull`'s local destination must be a real Windows-style path**
  (e.g. from `pwd -W`, as the driver does), not a POSIX one like
  `/tmp/foo.xml`. `MSYS_NO_PATHCONV=1` disables Git Bash's path conversion
  for *every* argument in that command, so a POSIX-style destination that
  would normally get auto-converted into a valid Windows path instead fails
  with "cannot create file/directory".

- **A stray `back` after submitting a form can exit the whole app.**
  Tasks List is the root/home screen with no back stack, so
  `key enter` (submit) immediately followed by `key back` pops out of the
  app entirely rather than closing just the sheet. If that happens:
  `bash .claude/skills/run-santian/driver.sh relaunch`.

- **`tap-text` requires an exact single match.** Several rows can share
  partial text (e.g. two tasks both containing "task"); it deliberately
  fails rather than guessing which one you meant - narrow the needle or use
  `find` to inspect matches and `tap <x> <y>` directly.

- **Cold build is slow, not stuck.** The first `flutter run` after a clean
  checkout builds a fresh Gradle daemon and can sit quietly for
  3-6 minutes before any device-side log output appears. `launch`'s default
  600s timeout accounts for this; don't kill it early.
