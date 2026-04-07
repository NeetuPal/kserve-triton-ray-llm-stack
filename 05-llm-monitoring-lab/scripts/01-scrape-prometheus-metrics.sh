#!/bin/bash
# ==============================================================================
# Fetch Prometheus text exposition from METRICS_URL (if your LLM server exposes /metrics).
# Many gateways enable this explicitly; OpenAI Cloud does not — skip this step for Cloud.
# ==============================================================================
set -euo pipefail

LOCAL_PORT="${LOCAL_PORT:-8000}"
METRICS_URL="${METRICS_URL:-http://127.0.0.1:${LOCAL_PORT}/metrics}"
OUT="${METRICS_OUT:-/tmp/llm-prometheus-metrics.txt}"

echo "=============================================="
echo "  GET $METRICS_URL"
echo "=============================================="

code=$(curl -sS -o "$OUT" -w "%{http_code}" "$METRICS_URL" || true)
if [ "$code" != "200" ]; then
  echo "⚠️  HTTP $code — many OpenAI-compatible servers do not expose /metrics by default."
  echo "   Set METRICS_URL if your gateway uses another path or host."
  echo "   Example: METRICS_URL=http://127.0.0.1:9090/metrics $0"
  exit 1
fi

echo "Sample (first 40 lines):"
head -n 40 "$OUT"
echo ""
echo "✅ Full body saved to $OUT"
