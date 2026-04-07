#!/bin/bash
# ==============================================================================
# One traced chat completion → Langfuse (Cloud or self-hosted).
# Keys: Langfuse UI → Project → Settings → API keys
# Self-host: see deploy/LANGFUSE-SELF-HOSTED.md
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_python.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_openai_preflight.sh"

ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

if [ -z "${LANGFUSE_PUBLIC_KEY:-}" ] || [ -z "${LANGFUSE_SECRET_KEY:-}" ]; then
  echo "Set LANGFUSE_PUBLIC_KEY and LANGFUSE_SECRET_KEY."
  echo "Optional: LANGFUSE_BASE_URL (Cloud EU/US or http://localhost:3000 for compose)."
  exit 1
fi

"$PYTHON" -m pip install -q -r "$ROOT/requirements-langfuse.txt"

LOCAL_PORT="${LOCAL_PORT:-8000}"
export OPENAI_BASE_URL="${OPENAI_BASE_URL:-http://127.0.0.1:${LOCAL_PORT}/v1}"

try_resolve_openai_model || true
finalize_openai_model
ensure_local_openai_reachable

if [[ "${OPENAI_BASE_URL}" == *"api.openai.com"* ]] && [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "❌ OPENAI_API_KEY is required for api.openai.com"
  exit 1
fi

"$PYTHON" examples/langfuse_openai_trace.py
