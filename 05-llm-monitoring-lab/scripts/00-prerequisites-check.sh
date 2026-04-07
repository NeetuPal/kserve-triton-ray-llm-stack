#!/bin/bash
# ==============================================================================
# Lab 05 — verify Python + pip (no cluster required for most exercises)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_python.sh"

echo "=============================================="
echo "  Lab 05: prerequisites"
echo "=============================================="

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "❌ Missing: $1"
    return 1
  fi
  echo "✅ $1"
}

need_cmd "$PYTHON"

echo ""
echo "Python: $($PYTHON --version)"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo ""
echo "Installing core deps from: $ROOT/requirements.txt"
"$PYTHON" -m pip install -q -r "$ROOT/requirements.txt"

echo ""
echo "✅ Core deps OK. For Phoenix traces: pip install -r requirements-optional.txt"
echo "=============================================="
