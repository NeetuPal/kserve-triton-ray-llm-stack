#!/bin/bash
# ==============================================================================
# OTLP gRPC → Phoenix + one instrumented chat completion
#   docker compose -f deploy/docker-compose.phoenix.yaml up
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_python.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_openai_preflight.sh"

ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

"$PYTHON" -m pip install -q -r "$ROOT/requirements-optional.txt"

LOCAL_PORT="${LOCAL_PORT:-8000}"
export OPENAI_BASE_URL="${OPENAI_BASE_URL:-http://127.0.0.1:${LOCAL_PORT}/v1}"
export OTEL_EXPORTER_OTLP_ENDPOINT="${OTEL_EXPORTER_OTLP_ENDPOINT:-http://127.0.0.1:4317}"

try_resolve_openai_model || true
finalize_openai_model
ensure_local_openai_reachable

if [[ "${OPENAI_BASE_URL}" == *"api.openai.com"* ]] && [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "❌ OPENAI_API_KEY is required for api.openai.com"
  exit 1
fi

echo "OPENAI_MODEL=$OPENAI_MODEL  OTEL_EXPORTER_OTLP_ENDPOINT=$OTEL_EXPORTER_OTLP_ENDPOINT"
"$PYTHON" examples/phoenix_openai_trace.py
