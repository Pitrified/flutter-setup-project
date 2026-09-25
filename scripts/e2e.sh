#!/usr/bin/env bash
# The slow check: the real app, on an emulator, against a mock OpenAI server.
#
#   scripts/e2e.sh                 # boot if needed, run, leave the emulator up
#   scripts/e2e.sh --stop-emulator # also shut the emulator down afterwards
#
# Deliberately NOT part of scripts/check.sh: this takes minutes and needs an
# emulator, and a gate nobody will wait for is not a gate
# (docs/getting-started.md, "What the mock does not prove").
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

AVD="${AVD:-fala_api36}"
PORT="${MOCK_PORT:-8099}"
DEVICE="${DEVICE:-emulator-5554}"
OUT="${E2E_OUT:-build/e2e}"
STOP_EMULATOR=0
[ "${1:-}" = "--stop-emulator" ] && STOP_EMULATOR=1

export ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
command -v flutter >/dev/null 2>&1 || export PATH="$HOME/flutter/bin:$PATH"
command -v adb >/dev/null 2>&1 || export PATH="$ANDROID_HOME/platform-tools:$PATH"

mkdir -p "$OUT"
mock_pid=""
booted_here=0

cleanup() {
  # Kill by PID, never by pattern: `pkill -f mock_openai` matches the very
  # command line that started it, which kills this script instead.
  [ -n "$mock_pid" ] && kill "$mock_pid" 2>/dev/null
  if [ "$STOP_EMULATOR" = "1" ] && [ "$booted_here" = "1" ]; then
    adb -s "$DEVICE" emu kill 2>/dev/null
  fi
}
trap cleanup EXIT

echo "--- emulator"
if adb devices | grep -q "^${DEVICE}[[:space:]]*device$"; then
  echo "    $DEVICE already running"
else
  echo "    booting $AVD headless"
  "$ANDROID_HOME/emulator/emulator" -avd "$AVD" \
    -no-window -gpu swiftshader_indirect -no-audio -no-boot-anim -no-snapshot-save \
    > "$OUT/emulator.log" 2>&1 &
  booted_here=1
  adb wait-for-device
  # Wait for the boot to finish, not just for adb to answer: an app installed
  # before this point fails in ways that look like app bugs.
  for _ in $(seq 1 90); do
    [ "$(adb -s "$DEVICE" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] && break
    sleep 2
  done
  [ "$(adb -s "$DEVICE" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] || {
    echo "    emulator did not finish booting; see $OUT/emulator.log"; exit 1; }
  echo "    booted"
fi

echo "--- mock OpenAI on :$PORT"
python3 tool/mock_openai.py --port "$PORT" --log-file "$OUT/requests.jsonl" \
  > "$OUT/mock.log" 2>&1 &
mock_pid=$!
for _ in $(seq 1 20); do
  curl -sf -m 1 "http://127.0.0.1:$PORT/health" >/dev/null 2>&1 && break
  sleep 0.5
done
curl -sf -m 1 "http://127.0.0.1:$PORT/health" >/dev/null 2>&1 || {
  echo "    mock did not come up; see $OUT/mock.log"; exit 1; }
# Also reachable as 127.0.0.1 inside the device, which is what a cabled phone
# needs; the emulator reaches the host at 10.0.2.2 either way.
adb -s "$DEVICE" reverse "tcp:$PORT" "tcp:$PORT" >/dev/null 2>&1

echo "--- integration test"
flutter test integration_test/app_test.dart -d "$DEVICE" \
  --dart-define="OPENAI_BASE_URL=http://10.0.2.2:$PORT/v1" 2>&1 | tee "$OUT/test.log"
# The test's exit code, not tee's.
status=${PIPESTATUS[0]}

echo
if [ "$status" -eq 0 ]; then
  echo "e2e passed. Requests the app made: $OUT/requests.jsonl"
else
  echo "e2e FAILED (exit $status). Logs in $OUT/: test.log, mock.log, requests.jsonl"
fi
exit "$status"
