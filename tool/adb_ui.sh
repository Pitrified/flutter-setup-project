#!/usr/bin/env bash
# Drive the app on a device or emulator by reading the view tree, not by guessing
# pixels. Source it, then call the helpers:
#
#   source tool/adb_ui.sh
#   ui_dump                      # refresh the cached view tree
#   ui_text                      # list every label on screen
#   ui_tap "Start Conversation"  # tap the centre of the node with that label
#   ui_has "Say something"       # 0 if present, 1 if not
#   ui_type "Hola amigo"         # type into the focused field
#   ui_shot welcome              # screenshot to $UI_OUT/welcome.png
#
# Flutter widgets surface as `content-desc` rather than `text`, so the helpers
# match either. Matching is a substring, so "Start over in German" finds the
# dialog title without spelling out the question mark.
set -uo pipefail

: "${UI_OUT:=/tmp/adb_ui}"
: "${ADB:=adb}"
UI_XML_LOCAL="$UI_OUT/window.xml"
mkdir -p "$UI_OUT"

ui_dump() {
  $ADB shell uiautomator dump /sdcard/window.xml >/dev/null 2>&1 || return 1
  $ADB shell cat /sdcard/window.xml > "$UI_XML_LOCAL" 2>/dev/null || return 1
  # One node per line, which is what every helper below assumes.
  tr '<' '\n<' < "$UI_XML_LOCAL" > "$UI_XML_LOCAL.lines"
}

ui_text() {
  grep -oE '(text|content-desc)="[^"]+"' "$UI_XML_LOCAL.lines" \
    | sed -E 's/^(text|content-desc)="//; s/"$//' | grep -v '^$' | sort -u
}

ui_has() {
  grep -qF "$1" "$UI_XML_LOCAL.lines"
}

# Centre of the first node whose text or content-desc contains $1.
#
# Fixed-string matching, deliberately: a label like "Spanish (European)" is not a
# regex, and treating it as one silently matched the wrong node (the parentheses
# became a group) until this was fixed.
ui_center() {
  local line
  line=$(grep -F "$1" "$UI_XML_LOCAL.lines" | grep -m1 'bounds=')
  [ -z "$line" ] && return 1
  local nums
  nums=$(printf '%s' "$line" | grep -oE 'bounds="\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]"' | grep -oE '[0-9]+')
  [ -z "$nums" ] && return 1
  # shellcheck disable=SC2086
  set -- $nums
  echo "$(( ($1 + $3) / 2 )) $(( ($2 + $4) / 2 ))"
}

# Tap a label. Re-dumps first, so callers do not have to remember to.
ui_tap() {
  ui_dump || { echo "ui_tap: dump failed" >&2; return 1; }
  local xy
  xy=$(ui_center "$1") || { echo "ui_tap: no node matching '$1'" >&2; return 1; }
  # shellcheck disable=SC2086
  $ADB shell input tap $xy
  sleep "${UI_SETTLE:-3}"
}

ui_type() {
  # adb's input text wants %s for a space and cannot carry every character.
  $ADB shell input text "$(printf '%s' "$1" | sed 's/ /%s/g')"
  sleep 1
}

ui_shot() {
  $ADB exec-out screencap -p > "$UI_OUT/${1:-shot}.png"
  echo "$UI_OUT/${1:-shot}.png"
}

# Block until a label appears, or fail after $3 seconds (default 30).
ui_wait_for() {
  local want="$1" limit="${2:-30}" waited=0
  while [ "$waited" -lt "$limit" ]; do
    ui_dump && ui_has "$want" && return 0
    sleep 2
    waited=$(( waited + 2 ))
  done
  echo "ui_wait_for: '$want' did not appear within ${limit}s" >&2
  return 1
}
