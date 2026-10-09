#!/bin/bash
# Builds and tests the app on every supported Xcode and simulator.
#
#   Xcode 27.1    iPhone 17 Pro, iOS 27.0   clean build + full test plan, including snapshots
#   Xcode 27.1    iPhone 15 Pro, iOS 17.0   test plan without snapshots (deployment-target floor)
#   Xcode 26.0.1  iPhone 17 Pro, iOS 26.0   clean build + test plan without snapshots
#
# Each Xcode gets a clean build, which fails if it reports any warning. Xcode is selected per
# run with DEVELOPER_DIR; xcode-select is never changed.
#
# Usage: scripts/test-matrix.sh
# Environment:
#   XCODE_27_PATH  Xcode 27.1   (default: "/Applications/Xcode 27.1.app")
#   XCODE_26_PATH  Xcode 26.0.1 (default: "/Applications/Xcode.app")
set -euo pipefail

cd "$(dirname "$0")/.."

XCODE_27_PATH="${XCODE_27_PATH:-/Applications/Xcode 27.1.app}"
XCODE_26_PATH="${XCODE_26_PATH:-/Applications/Xcode.app}"
SCHEME="CountriesApp"
SNAPSHOT_TARGET="CountriesUISnapshotTests"

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/countries-test-matrix.XXXXXX")"
echo "Logs and result bundles: $WORK_DIR"

fail() {
  echo "error: $1" >&2
  if [ -n "${2:-}" ] && [ -f "$2" ]; then
    echo "--- last lines of $2 ---" >&2
    tail -n 40 "$2" >&2
  fi
  exit 1
}

# build <label> <xcode path>: a clean build-for-testing that must report zero warnings.
build() {
  local label=$1 xcode=$2
  local log="$WORK_DIR/$label-build.log" result="$WORK_DIR/$label-build.xcresult"
  [ -d "$xcode" ] || fail "Xcode not found at $xcode (set XCODE_27_PATH / XCODE_26_PATH)"
  echo "==> Build: $(DEVELOPER_DIR="$xcode/Contents/Developer" xcodebuild -version | head -n 1)"
  DEVELOPER_DIR="$xcode/Contents/Developer" xcodebuild build-for-testing \
    -scheme "$SCHEME" -testPlan "$SCHEME" \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "$WORK_DIR/$label-DerivedData" \
    -resultBundlePath "$result" >"$log" 2>&1 || fail "build failed on $label" "$log"

  local warnings
  warnings=$(DEVELOPER_DIR="$xcode/Contents/Developer" xcrun xcresulttool get build-results --path "$result" \
    | plutil -extract warningCount raw -o - -- -)
  [ "$warnings" -eq 0 ] || fail "the build on $label reported $warnings warning(s)" "$log"
  echo "    OK, 0 warnings"
}

# test <label> <xcode path> <destination> <snapshots: yes|no>: runs the test plan on a built product.
run_tests() {
  local label=$1 xcode=$2 destination=$3 snapshots=$4
  local row="$label ${destination#platform=iOS Simulator,}"
  local slug log result
  slug=$(echo "$row" | tr -c '[:alnum:]' '-')
  log="$WORK_DIR/$slug-test.log"
  result="$WORK_DIR/$slug-test.xcresult"
  local skip=()
  [ "$snapshots" = yes ] || skip=(-skip-testing:"$SNAPSHOT_TARGET")

  echo "==> Test: $row"
  DEVELOPER_DIR="$xcode/Contents/Developer" xcodebuild test-without-building \
    -scheme "$SCHEME" -testPlan "$SCHEME" \
    -destination "$destination" \
    -derivedDataPath "$WORK_DIR/$label-DerivedData" \
    -resultBundlePath "$result" -collect-test-diagnostics never \
    ${skip[@]+"${skip[@]}"} >"$log" 2>&1 || fail "tests failed on $row" "$log"

  local summary
  summary=$(DEVELOPER_DIR="$xcode/Contents/Developer" xcrun xcresulttool get test-results summary --path "$result")
  echo "    OK, $(echo "$summary" | plutil -extract passedTests raw -o - -- -) passed," \
    "$(echo "$summary" | plutil -extract skippedTests raw -o - -- -) skipped"
}

build xcode27 "$XCODE_27_PATH"
run_tests xcode27 "$XCODE_27_PATH" "platform=iOS Simulator,name=iPhone 17 Pro,OS=27.0" yes
run_tests xcode27 "$XCODE_27_PATH" "platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0" no

build xcode26 "$XCODE_26_PATH"
run_tests xcode26 "$XCODE_26_PATH" "platform=iOS Simulator,name=iPhone 17 Pro,OS=26.0.1" no

# Keep logs and result bundles; drop the DerivedData folders (several hundred MB each).
rm -rf "$WORK_DIR"/*-DerivedData
echo "All rows passed."
