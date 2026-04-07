#!/bin/bash
# ==============================================================================
# Rule-based batch "evaluation" on sample JSONL (no LLM call).
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_python.sh"

ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

OUT="${OUT:-examples/eval_results.jsonl}"
"$PYTHON" examples/quality_batch_eval.py examples/sample_responses.jsonl -o "$OUT"
echo "Per-row results: $OUT"
