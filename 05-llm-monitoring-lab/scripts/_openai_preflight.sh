# shellcheck shell=bash
# Resolve OPENAI_MODEL; never call OpenAI Cloud model names against a dead localhost.
# Source after OPENAI_BASE_URL and PYTHON are set (from _python.sh).

_is_local_openai_base() {
  case "${OPENAI_BASE_URL:-}" in
    *"127.0.0.1"*|*"localhost"*) return 0 ;;
    *) return 1 ;;
  esac
}

_print_local_openai_help() {
  echo "❌ Nothing is accepting connections at OPENAI_BASE_URL ($OPENAI_BASE_URL)." >&2
  echo "   (Windows: WinError 10061 / 'actively refused' = no server on that port.)" >&2
  echo "" >&2
  echo "   Pick one:" >&2
  echo "   • Local LLM — start or port-forward your OpenAI-compatible server so GET .../v1/models returns 200." >&2
  echo "   • OpenAI Cloud — then run:" >&2
  echo "       export OPENAI_BASE_URL=https://api.openai.com/v1" >&2
  echo "       export OPENAI_API_KEY=sk-...   # from https://platform.openai.com/api-keys" >&2
  echo "       export OPENAI_MODEL=gpt-4o-mini" >&2
}

# If OPENAI_MODEL is unset and /models returns 200, set OPENAI_MODEL from first entry.
try_resolve_openai_model() {
  [ -n "${OPENAI_MODEL:-}" ] && return 0
  local code
  code=$(curl -sS -o /dev/null -w "%{http_code}" --connect-timeout 2 --max-time 8 "${OPENAI_BASE_URL}/models" 2>/dev/null || echo "000")
  echo "$code" | grep -q 200 || return 1
  local mj
  mj=$(curl -sS --max-time 20 "${OPENAI_BASE_URL}/models")
  export OPENAI_MODEL
  OPENAI_MODEL=$(echo "$mj" | "$PYTHON" -c 'import sys,json;d=json.load(sys.stdin);print(d["data"][0]["id"] if d.get("data") else "")')
  [ -n "$OPENAI_MODEL" ]
}

# If still no model: fail on localhost; else use gpt-4o-mini for remote APIs.
finalize_openai_model() {
  if [ -n "${OPENAI_MODEL:-}" ]; then
    return 0
  fi
  if _is_local_openai_base; then
    _print_local_openai_help >&2
    exit 1
  fi
  export OPENAI_MODEL="${OPENAI_MODEL_FALLBACK:-gpt-4o-mini}"
  echo "Using OPENAI_MODEL=$OPENAI_MODEL (remote base URL; override if wrong for your provider)"
}

# Localhost base URL always requires a live /v1/models (even if OPENAI_MODEL was set manually).
ensure_local_openai_reachable() {
  _is_local_openai_base || return 0
  local code
  code=$(curl -sS -o /dev/null -w "%{http_code}" --connect-timeout 2 --max-time 8 "${OPENAI_BASE_URL}/models" 2>/dev/null || echo "000")
  if echo "$code" | grep -q 200; then
    return 0
  fi
  _print_local_openai_help >&2
  exit 1
}
