#!/usr/bin/env bash
# Driver for running and poking the Santian Flutter app on an Android
# emulator/device, from Git Bash on Windows. See SKILL.md for the narrative;
# this is the harness it calls.
#
# Usage: driver.sh <command> [args...]
#   launch                    Start `flutter run` in the background, wait for
#                             it to finish building and land on the device.
#   wait-ready [timeout_s]    Block until the build log shows success/failure
#                             (default timeout 600s). Use after `launch` if you
#                             backgrounded it yourself.
#   status                    Show attached devices + whether flutter run is
#                             still alive.
#   relaunch                  Re-open the app via `am start` (fast path, no
#                             rebuild) - use after an accidental exit.
#   screenshot <name>         Save a PNG to artifacts/<name>.png, print the
#                             path. View it with the Read tool (this script
#                             cannot render images).
#   dump                      uiautomator-dump the current screen, pull it to
#                             artifacts/window_dump.xml, print every
#                             text=/content-desc=/bounds= triple.
#   find <needle>             Like `dump`, filtered to elements whose text or
#                             content-desc contains <needle> (case-insensitive).
#                             Prints bounds AND a ready-to-use center tap
#                             coordinate for each match.
#   tap <x> <y>               adb input tap at raw device pixel coordinates
#                             (as printed by `dump`/`find` - NOT scaled to any
#                             screenshot preview size).
#   tap-text <needle>         Convenience: find the first element matching
#                             <needle> and tap its center. Fails loudly (exits
#                             1) if there's no unique match instead of
#                             guessing.
#   type <text>               adb input text. Spaces must come through as
#                             literal spaces; this wraps them for you.
#   key <keyevent-name-or-code>
#                             adb input keyevent. Accepts a numeric code or
#                             one of the friendly names: enter, back, home.
#   dark <yes|no>             Toggle system dark mode (the app follows
#                             ThemeMode.system, so this switches its theme).
#   stop                      Kill the app process (does not stop the
#                             emulator or the `flutter run` process).
#
# Env overrides:
#   ADB_BIN     path to adb.exe (default: first of `adb` on PATH, else the
#               hardcoded fallback below)
#   DEVICE      device/emulator serial (default: first line of `adb devices`)
#   EMULATOR    AVD name to boot if no device is attached
#               (default: Pixel_3a_API_35_extension_level_13_x86_64)
#   PACKAGE     app package id (default: com.arcbyte.santian)
#   ACTIVITY    launch activity (default: .MainActivity)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -W)"
ARTIFACTS_DIR="$SCRIPT_DIR/artifacts"
mkdir -p "$ARTIFACTS_DIR"
RUN_LOG="$ARTIFACTS_DIR/flutter_run.log"

ADB_BIN="${ADB_BIN:-}"
if [ -z "$ADB_BIN" ]; then
  if command -v adb >/dev/null 2>&1; then
    ADB_BIN="adb"
  else
    ADB_BIN="D:\\Android\\Sdk\\platform-tools\\adb.exe"
  fi
fi

EMULATOR="${EMULATOR:-Pixel_3a_API_35_extension_level_13_x86_64}"
PACKAGE="${PACKAGE:-com.arcbyte.santian}"
ACTIVITY="${ACTIVITY:-.MainActivity}"

adb_() { "$ADB_BIN" ${DEVICE:+-s "$DEVICE"} "$@"; }

pick_device() {
  if [ -n "${DEVICE:-}" ]; then return; fi
  DEVICE="$("$ADB_BIN" devices | awk 'NR>1 && $2=="device" {print $1; exit}')"
}

cmd_status() {
  echo "== adb devices =="
  "$ADB_BIN" devices
  echo "== flutter run process =="
  ps aux 2>/dev/null | grep -i "[f]lutter" || echo "(none found)"
}

cmd_launch() {
  pick_device
  if [ -z "${DEVICE:-}" ]; then
    echo "No device attached; booting emulator $EMULATOR in the background..."
    (flutter emulators --launch "$EMULATOR" >>"$RUN_LOG" 2>&1 &)
    echo "Waiting up to 90s for it to attach..."
    for _ in $(seq 1 45); do
      pick_device
      [ -n "${DEVICE:-}" ] && break
      sleep 2
    done
    if [ -z "${DEVICE:-}" ]; then
      echo "Emulator never attached; check 'flutter emulators' / AVD name." >&2
      return 1
    fi
  fi
  echo "Using device: $DEVICE"
  echo "Starting flutter run (log: $RUN_LOG)..."
  : >"$RUN_LOG"
  (flutter run -d "$DEVICE" -v >>"$RUN_LOG" 2>&1 &)
  cmd_wait_ready "${1:-600}"
}

cmd_wait_ready() {
  local timeout="${1:-600}"
  echo "Waiting up to ${timeout}s for build+launch to finish..."
  local waited=0
  while [ "$waited" -lt "$timeout" ]; do
    if grep -qE "Flutter run key commands" "$RUN_LOG" 2>/dev/null; then
      echo "Ready."
      return 0
    fi
    if grep -qE "Exception|BUILD FAILED|Error running|Gradle task .* failed" "$RUN_LOG" 2>/dev/null; then
      echo "Build/launch failed - tail of log:" >&2
      tail -n 40 "$RUN_LOG" >&2
      return 1
    fi
    sleep 3
    waited=$((waited + 3))
  done
  echo "Timed out after ${timeout}s waiting for readiness. Tail of log:" >&2
  tail -n 40 "$RUN_LOG" >&2
  return 1
}

cmd_relaunch() {
  pick_device
  adb_ shell am start -n "$PACKAGE/$ACTIVITY"
}

cmd_screenshot() {
  pick_device
  local name="${1:?usage: driver.sh screenshot <name>}"
  local out="$ARTIFACTS_DIR/${name}.png"
  adb_ exec-out screencap -p >"$out"
  echo "$out"
}

cmd_dump() {
  pick_device
  local device_path="/sdcard/window_dump.xml"
  local local_path="$ARTIFACTS_DIR/window_dump.xml"
  # IMPORTANT: both calls below need MSYS_NO_PATHCONV=1, not just the pull.
  # Git Bash silently rewrites a bare /sdcard/... argument (to *either* an
  # `adb shell ...` command or an `adb pull` command - both invoke the
  # native adb.exe) into a bogus Windows-rooted path like
  # "C:/Program Files/Git/sdcard/window_dump.xml" before adb ever sees it.
  # If only the dump call is unprotected, uiautomator silently dumps to
  # that bogus path (or fails) and /sdcard/window_dump.xml on the device is
  # never actually refreshed - so a subsequent *protected* pull "succeeds"
  # but silently retrieves an arbitrarily old leftover file, which looks
  # exactly like a stale/stuck accessibility tree (we lost ~20 minutes to
  # this exact red herring - reboots, adb server restarts, and app
  # relaunches all "failed" to fix "staleness" that was actually just this).
  # The destination for `pull` must additionally be a real Windows-style
  # path (from `pwd -W`, as set up above): MSYS_NO_PATHCONV=1 disables
  # conversion for BOTH sides of that command, so a POSIX-style destination
  # like /tmp/foo would silently fail to be created.
  MSYS_NO_PATHCONV=1 adb_ shell uiautomator dump "$device_path" >/dev/null 2>&1
  MSYS_NO_PATHCONV=1 adb_ pull "$device_path" "$local_path" >/dev/null 2>&1
  grep -oE 'text="[^"]*"|content-desc="[^"]*"|bounds="\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]"' "$local_path" \
    | paste - - -
}

cmd_find() {
  local needle="${1:?usage: driver.sh find <needle>}"
  cmd_dump | grep -i "$needle"
  echo "---"
  echo "Center coordinates for each match above:"
  cmd_dump | grep -i "$needle" | grep -oE '\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]' | while read -r b; do
    IFS='[],' read -r _ x1 y1 _ x2 y2 _ <<<"${b//]/],}"
    # simpler parse:
    read -r x1 y1 x2 y2 <<<"$(echo "$b" | grep -oE '[0-9]+' | tr '\n' ' ')"
    echo "  bounds=$b  center=$(( (x1 + x2) / 2 )) $(( (y1 + y2) / 2 ))"
  done
}

cmd_tap() {
  pick_device
  local x="${1:?usage: driver.sh tap <x> <y>}" y="${2:?usage: driver.sh tap <x> <y>}"
  adb_ shell input tap "$x" "$y"
}

cmd_tap_text() {
  pick_device
  local needle="${1:?usage: driver.sh tap-text <needle>}"
  local matches
  matches="$(cmd_dump | grep -i "$needle")"
  local n
  n="$(printf '%s\n' "$matches" | grep -c . || true)"
  if [ "$n" -ne 1 ]; then
    echo "Expected exactly 1 match for '$needle', found $n:" >&2
    printf '%s\n' "$matches" >&2
    return 1
  fi
  local b x1 y1 x2 y2
  b="$(printf '%s' "$matches" | grep -oE '\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]')"
  read -r x1 y1 x2 y2 <<<"$(echo "$b" | grep -oE '[0-9]+' | tr '\n' ' ')"
  local cx=$(( (x1 + x2) / 2 )) cy=$(( (y1 + y2) / 2 ))
  echo "Tapping '$needle' at $cx $cy"
  adb_ shell input tap "$cx" "$cy"
}

cmd_type() {
  pick_device
  local text="${1:?usage: driver.sh type <text>}"
  adb_ shell input text "${text// /%s}"
}

cmd_key() {
  pick_device
  local k="${1:?usage: driver.sh key <name-or-code>}"
  case "$k" in
    enter) k=66 ;;
    back) k=4 ;;
    home) k=3 ;;
  esac
  adb_ shell input keyevent "$k"
}

cmd_dark() {
  pick_device
  local mode="${1:?usage: driver.sh dark <yes|no>}"
  adb_ shell cmd uimode night "$mode"
}

cmd_stop() {
  pick_device
  adb_ shell am force-stop "$PACKAGE"
}

main() {
  local sub="${1:-}"
  [ $# -gt 0 ] && shift
  case "$sub" in
    launch) cmd_launch "$@" ;;
    wait-ready) cmd_wait_ready "$@" ;;
    status) cmd_status "$@" ;;
    relaunch) cmd_relaunch "$@" ;;
    screenshot) cmd_screenshot "$@" ;;
    dump) cmd_dump "$@" ;;
    find) cmd_find "$@" ;;
    tap) cmd_tap "$@" ;;
    tap-text) cmd_tap_text "$@" ;;
    type) cmd_type "$@" ;;
    key) cmd_key "$@" ;;
    dark) cmd_dark "$@" ;;
    stop) cmd_stop "$@" ;;
    *)
      sed -n '2,45p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 1
      ;;
  esac
}

main "$@"
