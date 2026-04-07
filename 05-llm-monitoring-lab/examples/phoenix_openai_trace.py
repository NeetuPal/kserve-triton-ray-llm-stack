#!/usr/bin/env python3
"""
Send one chat completion to any OpenAI-compatible API while exporting OTEL spans to Arize Phoenix.

1) Start Phoenix, e.g.:
     docker compose -f deploy/docker-compose.phoenix.yaml up
   or: docker run --rm -p 6006:6006 -p 4317:4317 arizephoenix/phoenix:latest

2) pip install -r requirements-optional.txt

3) UI: http://localhost:6006

Env:
  OTEL_EXPORTER_OTLP_ENDPOINT  default http://127.0.0.1:4317 (gRPC)
  OPENAI_BASE_URL              default http://127.0.0.1:8000/v1 (Ollama: http://127.0.0.1:11434/v1)
  OPENAI_API_KEY               required for OpenAI Cloud; dummy often OK for local gateways
  OPENAI_MODEL                 optional; if unset, uses GET /v1/models when available, else gpt-4o-mini

Note: OTLP gRPC vs HTTP varies by Phoenix version; adjust exporter if traces do not appear.
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
        from openinference.instrumentation.openai import OpenAIInstrumentor
        from opentelemetry import trace
        from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
        from opentelemetry.sdk.resources import Resource
        from opentelemetry.sdk.trace import TracerProvider
        from opentelemetry.sdk.trace.export import SimpleSpanProcessor
        from openai import OpenAI
    except ImportError:
        print("Install optional deps: pip install -r requirements-optional.txt", file=sys.stderr)
        raise SystemExit(1) from None

    endpoint = os.environ.get("OTEL_EXPORTER_OTLP_ENDPOINT", "http://127.0.0.1:4317")
    resource = Resource(attributes={"service.name": "llm-monitoring-lab"})
    provider = TracerProvider(resource=resource)
    provider.add_span_processor(SimpleSpanProcessor(OTLPSpanExporter(endpoint=endpoint, insecure=True)))
    trace.set_tracer_provider(provider)
    OpenAIInstrumentor().instrument()

    base = os.environ.get("OPENAI_BASE_URL", "http://127.0.0.1:8000/v1").rstrip("/")
    if not base.endswith("/v1"):
        base = base.rstrip("/") + "/v1"

    model = os.environ.get("OPENAI_MODEL", "").strip() or _default_model(base)
    client = OpenAI(base_url=base, api_key=os.environ.get("OPENAI_API_KEY", "dummy"))

    r = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": "Say hi in one line."}],
        max_tokens=64,
    )
    print(r.choices[0].message.content)
    print("Check Phoenix UI for the trace.", file=sys.stderr)


if __name__ == "__main__":
    main()
