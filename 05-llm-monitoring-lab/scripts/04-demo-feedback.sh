#!/bin/bash
# ==============================================================================
# Append a few feedback rows to examples/feedback.jsonl (gitignored).
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_python.sh"

ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT/examples"

FB="${FEEDBACK_FILE:-feedback.jsonl}"
"$PYTHON" log_feedback.py --request-id demo-req-1 --rating thumbs_up --comment "Clear answer" --file "$FB"
"$PYTHON" log_feedback.py --request-id demo-req-2 --rating thumbs_down --comment "Wrong date" --file "$FB"
echo ""
echo "Appended to $FB — tail:"
tail -n 5 "$FB"
