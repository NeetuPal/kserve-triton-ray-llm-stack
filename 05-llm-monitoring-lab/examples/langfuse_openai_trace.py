#!/usr/bin/env python3
"""
Send one chat completion to any OpenAI-compatible API and record it in Langfuse (OpenAI SDK wrapper).

Works with Langfuse Cloud or self-hosted Docker Compose. Keys: project → Settings → API keys.

Env:
  LANGFUSE_PUBLIC_KEY   pk-lf-...
  LANGFUSE_SECRET_KEY   sk-lf-...
  LANGFUSE_BASE_URL     https://cloud.langfuse.com | https://us.cloud.langfuse.com | http://localhost:3000

LLM (OpenAI-compatible):
  OPENAI_BASE_URL       https://api.openai.com/v1 | http://127.0.0.1:11434/v1 (Ollama) | any /v1 gateway
  OPENAI_API_KEY        set for cloud providers; local gateways often accept a placeholder
  OPENAI_MODEL          optional; if unset, tries GET /v1/models, else uses gpt-4o-mini

Install: pip install -r requirements-langfuse.txt

Call get_client().flush() so short CLI runs still upload traces (SDK batches by default).
Docs: https://langfuse.com/docs/integrations/openai/python
"""
from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request


def _default_model(base: str) -> str:
    root = base.rstrip("/")
    if root.endswith("/v1"):
        root = root[: -len("/v1")]
    url = f"{root}/v1/models"
    try:
        with urllib.request.urlopen(url, timeout=15) as resp:
            data = json.loads(resp.read().decode())
        items = data.get("data") or []
        if items:
            return str(items[0]["id"])
    except (urllib.error.URLError, OSError, json.JSONDecodeError, KeyError):
        pass
    return "gpt-4o-mini"


def main() -> None:
    try:
        from langfuse import get_client
        from langfuse.openai import OpenAI
    except ImportError:
        print("Install: pip install -r requirements-langfuse.txt", file=sys.stderr)
        raise SystemExit(1) from None

    if not os.environ.get("LANGFUSE_PUBLIC_KEY") or not os.environ.get("LANGFUSE_SECRET_KEY"):
        print(
            "Set LANGFUSE_PUBLIC_KEY and LANGFUSE_SECRET_KEY (Langfuse project → Settings → API keys).",
            file=sys.stderr,
        )
        raise SystemExit(1)

    base = os.environ.get("OPENAI_BASE_URL", "http://127.0.0.1:8000/v1").rstrip("/")
    if not base.endswith("/v1"):
        base = base.rstrip("/") + "/v1"

    model = os.environ.get("OPENAI_MODEL", "").strip() or _default_model(base)

    client = OpenAI(
        base_url=base,
        api_key=os.environ.get("OPENAI_API_KEY", "dummy"),
    )

    r = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": "Say hi in one line."}],
        max_tokens=64,
        name="lab-openai-chat",
        metadata={"source": "05-llm-monitoring-lab"},
    )
    print(r.choices[0].message.content)
    get_client().flush()
    print("Check Langfuse UI for the trace.", file=sys.stderr)


if __name__ == "__main__":
    main()
