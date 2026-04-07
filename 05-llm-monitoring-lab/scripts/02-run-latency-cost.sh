#!/bin/bash
# ==============================================================================
# examples/latency_cost_log.py — needs any OpenAI-compatible /v1 with chat.completions
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_python.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_openai_preflight.sh"

ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

LOCAL_PORT="${LOCAL_PORT:-8000}"
export OPENAI_BASE_URL="${OPENAI_BASE_URL:-http://127.0.0.1:${LOCAL_PORT}/v1}"

try_resolve_openai_model || true
finalize_openai_model
ensure_local_openai_reachable

if [[ "${OPENAI_BASE_URL}" == *"api.openai.com"* ]] && [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "❌ OPENAI_API_KEY is required for api.openai.com"
  exit 1
fi

echo "Using OPENAI_MODEL=$OPENAI_MODEL  OPENAI_BASE_URL=$OPENAI_BASE_URL"
"$PYTHON" examples/latency_cost_log.py
