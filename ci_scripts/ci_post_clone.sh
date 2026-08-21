#!/bin/bash
set -euo pipefail
exec "$(cd "$(dirname "$0")" && pwd)/trust-macros.sh"
