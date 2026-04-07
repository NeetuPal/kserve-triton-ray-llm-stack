#!/bin/bash
# ==============================================================================
# Phoenix trace demo using Ollama's OpenAI-compatible API (default :11434).
# Prereq: Ollama running + at least one model pulled (e.g. ollama pull llama3.2)
# Docs: https://github.com/ollama/ollama/blob/main/docs/openai.md
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1}"
OLLAMA_PORT="${OLLAMA_PORT:-11434}"

export OPENAI_BASE_URL="http://${OLLAMA_HOST}:${OLLAMA_PORT}/v1"
export OPENAI_API_KEY="${OPENAI_API_KEY:-ollama}"

echo "Using Ollama OpenAI API at OPENAI_BASE_URL=$OPENAI_BASE_URL"
exec "$SCRIPT_DIR/05-phoenix-trace.sh"
