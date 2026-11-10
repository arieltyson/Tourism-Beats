#!/bin/bash
# Captures the raw App Store listing screens on one simulator display: dark
# appearance, a clean 9:41 status bar, and each screen reached by
# AppStoreScreenshotUITests driving the real app.
#
# The test walks to a screen and leaves <name>.ready in the output folder;
# this script saves that display with simctl and answers with <name>.done.
# XCTest can't save iPhone Duo's inner display itself, so simctl does.
#
# Usage: capture.sh <simulator name or UDID> <output folder> [display]
#   capture.sh "iPhone 18 Pro" raw-iphone
#   capture.sh "iPhone Duo" raw-duo-outer
#   capture.sh "iPhone Duo" raw-duo-inner primary-1   (unfold it first)
#
# Set ONLY to capture some screens, as in ONLY=test02City.
set -euo pipefail
cd "$(dirname "$0")"
DEVICE="$1"
case "$2" in /*) OUT="$2" ;; *) OUT="$PWD/$2" ;; esac
DISPLAY_NAME="${3:-primary}"
DD="${DERIVED_DATA:-/tmp/tourism-beats-screenshots}"
TESTS="Tourism BeatsUITests/AppStoreScreenshotUITests"

if [[ "$DEVICE" =~ ^[0-9A-F-]{36}$ ]]; then DESTINATION="id=$DEVICE"; else DESTINATION="name=$DEVICE"; fi
ONLY_TESTING=()
if [ -n "${ONLY:-}" ]; then
  for test in $ONLY; do ONLY_TESTING+=(-only-testing:"$TESTS/$test"); done
else
  ONLY_TESTING=(-only-testing:"$TESTS")
fi

xcrun simctl boot "$DEVICE" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE" -b >/dev/null
xcrun simctl ui "$DEVICE" appearance dark
xcrun simctl status_bar "$DEVICE" override --time 9:41 --dataNetwork wifi --wifiMode active \
  --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100

mkdir -p "$OUT"
rm -f "$OUT"/*.ready "$OUT"/*.done

# Save each screen the test says is ready.
(
  while true; do
    for marker in "$OUT"/*.ready; do
      [ -e "$marker" ] || continue
      name=$(basename "$marker" .ready)
      xcrun simctl io "$DEVICE" screenshot --display="$DISPLAY_NAME" "$OUT/$name.png" >/dev/null 2>&1
      rm -f "$marker"
      touch "$OUT/$name.done"
      echo "$OUT/$name.png"
    done
    sleep 1
  done
) &
WATCHER=$!
trap 'kill $WATCHER 2>/dev/null; rm -f "$OUT"/*.ready "$OUT"/*.done' EXIT

TEST_RUNNER_SCREENSHOT_OUTPUT_DIR="$OUT" xcodebuild test \
  -project "../../Tourism Beats.xcodeproj" -scheme "Tourism Beats" \
  -destination "platform=iOS Simulator,$DESTINATION" -derivedDataPath "$DD" \
  "${ONLY_TESTING[@]}" -quiet
