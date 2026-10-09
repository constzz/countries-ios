#!/bin/sh
# Checks formatting (SwiftFormat) and code smells (SwiftLint), the same way CI does.
#
# Usage: scripts/lint.sh [--fix]
#   --fix  formats the code and applies SwiftLint's automatic fixes before linting.
set -eu

cd "$(dirname "$0")/.."

for tool in swiftformat swiftlint; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "error: $tool not found. Install it with: brew install swiftlint swiftformat" >&2
    exit 1
  fi
done

if [ "${1:-}" = "--fix" ]; then
  swiftformat --quiet .
  swiftlint lint --fix --quiet
fi

swiftformat --quiet --lint .
swiftlint lint --strict --quiet
