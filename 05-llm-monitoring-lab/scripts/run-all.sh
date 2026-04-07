#!/bin/bash
# ==============================================================================
# Offline-friendly steps + reminder for live LLM + observability stacks
# ==============================================================================
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$DIR/00-prerequisites-check.sh"
"$DIR/03-run-batch-eval.sh"
"$DIR/04-demo-feedback.sh"

echo ""
echo "=============================================="
echo "  Next — configure OPENAI_* then:"
echo "    ./scripts/02-run-latency-cost.sh"
echo "    ./scripts/01-scrape-prometheus-metrics.sh   # only if your server exposes /metrics"
echo ""
echo "  Observability stacks (see README step-by-step):"
echo "    Phoenix:   docker compose -f ../deploy/docker-compose.phoenix.yaml up"
echo "               ./scripts/05-phoenix-trace.sh"
echo "    Langfuse:  Cloud or deploy/LANGFUSE-SELF-HOSTED.md"
echo "               ./scripts/06-langfuse-trace.sh"
echo "    Ollama:    ./scripts/07-ollama-phoenix-trace.sh (see README §2b)"
echo "    Cleanup:   ./scripts/10-cleanup-lab.sh"
echo "=============================================="
