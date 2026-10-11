#!/bin/sh
# Regenerates the Apollo code and fails if it differs from what's committed, the same way CI does.
#
# Usage: scripts/check-codegen.sh
# Environment:
#   APOLLO_CLI  path to apollo-ios-cli (default: ./apollo-ios-cli; see docs/DEVELOPMENT.md, Codegen)
set -eu

cd "$(dirname "$0")/.."

cli="${APOLLO_CLI:-./apollo-ios-cli}"
generated=Packages/AtlasData/Sources/AtlasData/Generated

if [ ! -x "$cli" ]; then
  echo "error: $cli not found. Install it as described in docs/DEVELOPMENT.md (Codegen)." >&2
  exit 1
fi

"$cli" generate --path ./apollo-codegen-config.json

if [ -n "$(git status --porcelain -- "$generated")" ]; then
  echo "error: the committed generated code is out of date. Commit the regenerated files:" >&2
  git status --short -- "$generated" >&2
  exit 1
fi
echo "Generated code is up to date."
