#!/bin/bash
# ==============================================================================
# Lab 05 — remove generated artifacts (keeps repo + venv; does not stop Docker)
# ==============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "=============================================="
echo "  Lab 05: cleanup local artifacts"
echo "=============================================="

removed=0
for f in examples/feedback.jsonl examples/eval_results.jsonl; do
  if [ -f "$f" ]; then
    rm -f "$f"
    echo "  removed $f"
    removed=$((removed + 1))
  fi
done

if [ -d examples/__pycache__ ]; then
  rm -rf examples/__pycache__
  echo "  removed examples/__pycache__/"
  removed=$((removed + 1))
fi

for tmp in /tmp/llm-prometheus-metrics.txt /tmp/vllm-metrics.txt; do
  if [ -f "$tmp" ]; then
    rm -f "$tmp"
    echo "  removed $tmp"
    removed=$((removed + 1))
  fi
done

if [ "$removed" -eq 0 ]; then
  echo "  (nothing to delete — already clean)"
fi

echo ""
echo "  Docker (stop manually if running):"
echo "    Phoenix:  Ctrl+C in the terminal, or from repo root:"
echo "              docker compose -f 05-llm-monitoring-lab/deploy/docker-compose.phoenix.yaml down"
echo "    Langfuse: Ctrl+C in the compose terminal, or docker compose down in the langfuse clone dir"
echo ""
echo "  To remove a local venv:  rm -rf .venv"
echo "=============================================="
echo "  ✅ Lab 05 artifact cleanup done"
echo "=============================================="
