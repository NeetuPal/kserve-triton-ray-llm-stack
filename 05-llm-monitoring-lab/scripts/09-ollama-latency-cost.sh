#!/bin/bash
# ==============================================================================
# latency_cost_log.py against Ollama (:11434 OpenAI-compatible API).
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1}"
OLLAMA_PORT="${OLLAMA_PORT:-11434}"

export OPENAI_BASE_URL="http://${OLLAMA_HOST}:${OLLAMA_PORT}/v1"
export OPENAI_API_KEY="${OPENAI_API_KEY:-ollama}"

echo "Using Ollama at OPENAI_BASE_URL=$OPENAI_BASE_URL"
exec "$SCRIPT_DIR/02-run-latency-cost.sh"
