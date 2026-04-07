# shellcheck shell=bash
# Resolve python3 vs python (Git Bash / Windows often only exposes `python`).
if command -v python3 >/dev/null 2>&1; then
  PYTHON=python3
elif command -v python >/dev/null 2>&1; then
  PYTHON=python
else
  echo "❌ Neither python3 nor python is on PATH." >&2
  echo "   Install Python 3.10+ from https://www.python.org/downloads/ and enable 'Add python.exe to PATH'." >&2
  exit 1
fi
