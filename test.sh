#!/usr/bin/env bash
# Run the unit tests for pinning-target selection (manual and automatic mode).
set -euo pipefail
cd "$(dirname "$0")"

OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT

swiftc src/DisplayUtils.swift tests/DisplaySelectionTests.swift \
    -framework AppKit \
    -o "$OUT/tests"

"$OUT/tests"
