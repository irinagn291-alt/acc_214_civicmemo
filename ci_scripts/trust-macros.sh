#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -n "${BITRISE_SOURCE_DIR:-}" && -f "${BITRISE_SOURCE_DIR}/ci_scripts/macros.json" ]]; then
  ROOT="$BITRISE_SOURCE_DIR"
fi
SRC="${ROOT}/ci_scripts/macros.json"
DEST_DIR="${HOME}/Library/org.swift.swiftpm/security"
mkdir -p "$DEST_DIR"
cp "$SRC" "${DEST_DIR}/macros.json"
echo "Trusted macros → ${DEST_DIR}/macros.json"
