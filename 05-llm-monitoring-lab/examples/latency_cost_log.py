#!/usr/bin/env python3
"""
Measure end-to-end latency and estimate $ from token usage (OpenAI-compatible / vLLM).

Env:
  OPENAI_BASE_URL  default http://127.0.0.1:8000/v1
  OPENAI_MODEL     default gpt-4o-mini (override for any OpenAI-compatible server)
"""
from __future__ import annotations

import json
import os
import time

from openai import OpenAI

# Example $/1K tokens — replace with your org’s pricing table (teaching only).
PRICE_TABLE = {
    "default": {"prompt_per_1k": 0.00015, "completion_per_1k": 0.0006},
}


def estimate_cost(prompt_tokens: int, completion_tokens: int, tier: str = "default") -> float:
    p = PRICE_TABLE.get(tier, PRICE_TABLE["default"])
    return (
        (prompt_tokens / 1000.0) * p["prompt_per_1k"]
        + (completion_tokens / 1000.0) * p["completion_per_1k"]
    )


def main() -> None:
    base = os.environ.get("OPENAI_BASE_URL", "http://127.0.0.1:8000/v1").rstrip("/")
    if not base.endswith("/v1"):
        base = base.rstrip("/") + "/v1"

    model = os.environ.get("OPENAI_MODEL", "gpt-4o-mini")
    client = OpenAI(base_url=base, api_key=os.environ.get("OPENAI_API_KEY", "dummy"))

    user_msg = os.environ.get("SAMPLE_PROMPT", "Say hello in one short sentence.")

    t0 = time.perf_counter()
    resp = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": user_msg}],
        max_tokens=128,
        temperature=0.3,
    )
    latency_ms = (time.perf_counter() - t0) * 1000.0

    u = resp.usage
    pt = u.prompt_tokens or 0
    ct = u.completion_tokens or 0
    cost = estimate_cost(pt, ct)

    out = {
        "latency_ms": round(latency_ms, 2),
        "model": model,
        "finish_reason": resp.choices[0].finish_reason,
        "prompt_tokens": pt,
        "completion_tokens": ct,
        "total_tokens": pt + ct,
        "estimated_cost_usd": round(cost, 6),
        "answer_preview": (resp.choices[0].message.content or "")[:200],
    }
    print(json.dumps(out, indent=2))


if __name__ == "__main__":
    main()
