# Lab 5: LLM Monitoring & Observability (standalone)

> **Standalone lab:** teaches **what** to monitor for LLM applications, **how** it appears **in real time** in common tools, and **step-by-step** deployment of **Langfuse** and **Arize Phoenix**.  
> **Does not require** any other lab in this repo. You only need **some** OpenAI-compatible HTTP API (`/v1/chat/completions`): OpenAI, Azure OpenAI, a local gateway (Ollama, LiteLLM, vLLM, etc.), or your own stack.

**Time:** ~15 min (offline scripts) + ~15 min (Phoenix) + ~20–40 min (Langfuse self-host first run) — or ~5 min if you use **Langfuse Cloud**.

---

## 1. What you monitor in production (and what this lab maps to)

| Signal | What it tells you | “Real time” in practice | This lab |
|--------|-------------------|-------------------------|----------|
| **Traces / generations** | Single request path: prompt, model, output, errors | UI updates within seconds of `flush()` or batch upload | **Phoenix** (OpenTelemetry spans), **Langfuse** (generation records) |
| **Latency** | End-to-end and per-stage (network, queue, tokens) | Per-request in trace detail; aggregate in dashboards | `latency_cost_log.py` (wall clock JSON) |
| **Tokens & cost** | Billable usage, budget alerts | Shown on each generation; roll up in product UI | API `usage` + stub `PRICE_TABLE` in `latency_cost_log.py` |
| **Quality** | Is the answer empty, off-topic, unsafe? | Offline batch or streaming eval pipelines | `quality_batch_eval.py` (rule-based gate) |
| **User feedback** | Thumbs, ratings, free text | Stored when user acts; joined to `request_id` later | `log_feedback.py` → JSONL |
| **Prometheus metrics** | QPS, queue depth, GPU/CPU, cache (if exposed) | Scrape interval 15–60s typical; Grafana alerts | `01-scrape-prometheus-metrics.sh` (optional) |

**Reality check:** “Real time” for traces usually means **sub-second to tens of seconds** after the SDK sends events—not magic millisecond streaming of every token into BI unless you built that pipeline.

---

## 2. Choose your LLM backend (any one)

Scripts default to `OPENAI_BASE_URL=http://127.0.0.1:8000/v1` for a **local** gateway. Override for your environment:

| Provider | Typical `OPENAI_BASE_URL` | `OPENAI_API_KEY` |
|----------|---------------------------|------------------|
| **OpenAI** | `https://api.openai.com/v1` | Required |
| **Azure OpenAI** | Your resource endpoint + `/openai/deployments/...` (see Azure docs) | Required |
| **Ollama** (OpenAI compat) | `http://127.0.0.1:11434/v1` | Often omitted / dummy |
| **LiteLLM / vLLM / other** | Your service URL + `/v1` | Per your gateway |

**Model id:** If `GET /v1/models` works, helper scripts pick the first `id`. Otherwise set `OPENAI_MODEL` (e.g. `gpt-4o-mini` on OpenAI, or your local model name).

---

## 2b. Ollama (local LLM, no OpenAI billing)

[Ollama](https://ollama.com/) exposes an **OpenAI-compatible** HTTP API on **`http://127.0.0.1:11434/v1`** ([docs](https://github.com/ollama/ollama/blob/main/docs/openai.md)). Use it when you want this lab **without** cloud API keys or quota.

### Install and run Ollama

1. Install Ollama for [Windows / macOS / Linux](https://ollama.com/download).
2. Start the app (or `ollama serve` on Linux) so something listens on **11434**.
3. Pull a small chat model (pick any name you like; examples use a common tag):

   ```bash
   ollama pull llama3.2
   ```

4. Sanity check (should return JSON):

   ```bash
   curl -sS http://127.0.0.1:11434/v1/models
   ```

### Wire this lab to Ollama

**Option A — helper scripts** (set `OPENAI_BASE_URL` + dummy key, then call the usual flows):

| Script | What it runs |
|--------|----------------|
| [`scripts/07-ollama-phoenix-trace.sh`](scripts/07-ollama-phoenix-trace.sh) | Phoenix-instrumented chat → OTLP |
| [`scripts/08-ollama-langfuse-trace.sh`](scripts/08-ollama-langfuse-trace.sh) | Langfuse-instrumented chat (needs `LANGFUSE_*`) |
| [`scripts/09-ollama-latency-cost.sh`](scripts/09-ollama-latency-cost.sh) | `latency_cost_log.py` JSON |

Example (Phoenix container running, Ollama running):

```bash
cd 05-llm-monitoring-lab
export OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4317
./scripts/07-ollama-phoenix-trace.sh
```

**Option B — environment only**

```bash
export OPENAI_BASE_URL=http://127.0.0.1:11434/v1
export OPENAI_API_KEY=ollama    # dummy; Ollama ignores it
# optional if you have several models:
export OPENAI_MODEL=llama3.2
./scripts/05-phoenix-trace.sh
```

**Override host/port** (remote Ollama or custom bind):

```bash
export OLLAMA_HOST=192.168.1.10
export OLLAMA_PORT=11434
./scripts/07-ollama-phoenix-trace.sh
```

**Token usage note:** Ollama may return partial or zero `usage` fields depending on version; `latency_cost_log.py` still records wall-clock latency. Cost estimates are **not** meaningful for local Ollama unless you assign your own `PRICE_TABLE`.

---

## 3. Step-by-step — offline monitoring (no LLM required)

These teach **quality** and **feedback** pipelines without calling a model.

1. **Prerequisites**

   ```bash
   cd 05-llm-monitoring-lab
   python -m pip install -r requirements.txt
   ```

2. **Batch quality evaluation** — reads `examples/sample_responses.jsonl`, prints summary JSON and optional per-row file:

   ```bash
   python examples/quality_batch_eval.py examples/sample_responses.jsonl -o examples/eval_results.jsonl
   ```

3. **Feedback log** — simulates “app posts feedback to warehouse”:

   ```bash
   python examples/log_feedback.py --request-id req-1 --rating thumbs_up --comment "Helpful" --file examples/feedback.jsonl
   ```

Or run `./scripts/run-all.sh` (Git Bash / WSL) to install deps and run batch eval + demo feedback.

---

## 4. Step-by-step — Phoenix (traces in real time)

**What happens when you run the example:** the OpenAI client is **instrumented**; each `chat.completions.create` becomes **OTLP spans** sent to Phoenix’s gRPC port; the **Phoenix UI** shows a trace tree within seconds.

### 4.1 Deploy Phoenix

**Option A — Docker Compose (from repo root):**

```bash
docker compose -f 05-llm-monitoring-lab/deploy/docker-compose.phoenix.yaml up
```

**Option B — single container:**

```bash
docker run --rm -p 6006:6006 -p 4317:4317 arizephoenix/phoenix:latest
```

Leave this running. **UI:** [http://localhost:6006](http://localhost:6006) · **OTLP gRPC:** `localhost:4317`

### 4.2 Install Python instrumentation

```bash
cd 05-llm-monitoring-lab
python -m pip install -r requirements-optional.txt
```

### 4.3 Point at your LLM and send one traced call

**Local gateway on port 8000:**

```bash
export OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4317
export OPENAI_BASE_URL=http://127.0.0.1:8000/v1
./scripts/05-phoenix-trace.sh
```

If nothing listens on that port, you get **connection refused** (Windows: WinError 10061). The helper scripts exit **before** calling Python and tell you to either start a local LLM or switch to **OpenAI Cloud** (below).

**OpenAI Cloud:**

```bash
export OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4317
export OPENAI_BASE_URL=https://api.openai.com/v1
export OPENAI_API_KEY=sk-...
export OPENAI_MODEL=gpt-4o-mini
python examples/phoenix_openai_trace.py
```

### 4.4 What to click in the UI

Open Phoenix → find the latest trace → inspect **span duration**, **attributes** (model, messages where configured), and **hierarchy** (one generation under a root span). That is the **real-time observability** experience teams use to debug latency and failures.

---

## 5. Step-by-step — Langfuse (generations in real time)

**What happens when you run the example:** the Langfuse-wrapped `OpenAI` client records a **generation** (inputs, outputs, latency, token usage when returned); the SDK **buffers** events and POSTs to Langfuse; `flush()` forces delivery so short CLIs still see data **immediately** in the UI.

### 5.1 Deploy or sign up

**Option A — Langfuse Cloud (fastest)**  
1. Create a project at [https://cloud.langfuse.com](https://cloud.langfuse.com) (or US region if offered).  
2. **Settings → API keys** → create **public** and **secret** keys.

```bash
export LANGFUSE_PUBLIC_KEY=pk-lf-...
export LANGFUSE_SECRET_KEY=sk-lf-...
export LANGFUSE_BASE_URL=https://cloud.langfuse.com
```

**Option B — Self-hosted (Docker Compose)**  
Follow **[deploy/LANGFUSE-SELF-HOSTED.md](deploy/LANGFUSE-SELF-HOSTED.md)** (clone official `langfuse` repo, set secrets, `docker compose up`, open `http://localhost:3000`, create keys). Then:

```bash
export LANGFUSE_BASE_URL=http://localhost:3000
export LANGFUSE_PUBLIC_KEY=pk-lf-...
export LANGFUSE_SECRET_KEY=sk-lf-...
```

### 5.2 Install SDK

```bash
cd 05-llm-monitoring-lab
python -m pip install -r requirements-langfuse.txt
```

### 5.3 Run one traced completion

**With helper script:**

```bash
export OPENAI_BASE_URL=https://api.openai.com/v1   # or your gateway
export OPENAI_API_KEY=sk-...                       # if required
./scripts/06-langfuse-trace.sh
```

**Direct:**

```bash
python examples/langfuse_openai_trace.py
```

### 5.4 What to click in the UI

Open **Traces** or **Generations** → select the latest row → verify **latency**, **token counts**, **cost** (if Langfuse has pricing metadata for that model), and **metadata** (`source: 05-llm-monitoring-lab`). That mirrors how teams monitor **production** traffic (often with sampling turned on).

---

## 6. Step-by-step — latency & cost JSON (one request)

After `OPENAI_*` is set:

```bash
./scripts/02-run-latency-cost.sh
```

You get printed JSON: `latency_ms`, `prompt_tokens`, `completion_tokens`, `estimated_cost_usd` (teaching stub — replace `PRICE_TABLE` with your org’s pricing).

---

## 7. Step-by-step — Prometheus scrape (optional)

Only if your server exposes metrics (many **do not** by default):

```bash
export METRICS_URL=http://127.0.0.1:8000/metrics
./scripts/01-scrape-prometheus-metrics.sh
```

Useful when your gateway documents a `/metrics` or sidecar scrape target; **OpenAI Cloud** has no such URL for students.

---

## Project layout

```
05-llm-monitoring-lab/
├── README.md
├── requirements.txt
├── requirements-optional.txt     # Phoenix / OTEL gRPC
├── requirements-langfuse.txt
├── deploy/
│   ├── docker-compose.phoenix.yaml
│   └── LANGFUSE-SELF-HOSTED.md
├── examples/
│   ├── sample_responses.jsonl
│   ├── quality_batch_eval.py
│   ├── latency_cost_log.py
│   ├── log_feedback.py
│   ├── phoenix_openai_trace.py
│   └── langfuse_openai_trace.py
└── scripts/
    ├── 00-prerequisites-check.sh
    ├── 01-scrape-prometheus-metrics.sh
    ├── 02-run-latency-cost.sh
    ├── 03-run-batch-eval.sh
    ├── 04-demo-feedback.sh
    ├── 05-phoenix-trace.sh
    ├── 06-langfuse-trace.sh
    ├── 07-ollama-phoenix-trace.sh
    ├── 08-ollama-langfuse-trace.sh
    ├── 09-ollama-latency-cost.sh
    ├── 10-cleanup-lab.sh
    └── run-all.sh
```

---

## Environment variables (cheat sheet)

| Variable | Role |
|----------|------|
| `OPENAI_BASE_URL` | Chat Completions API base (`.../v1`) |
| `OPENAI_API_KEY` | Required for OpenAI / Azure; often dummy for local gateways |
| `OPENAI_MODEL` | Override model id; scripts fall back to `gpt-4o-mini` if `/v1/models` missing |
| `OPENAI_MODEL_FALLBACK` | Override default fallback model name |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | Phoenix gRPC (default `http://127.0.0.1:4317`) |
| `LANGFUSE_PUBLIC_KEY` / `LANGFUSE_SECRET_KEY` | Langfuse SDK auth |
| `LANGFUSE_BASE_URL` | Cloud or `http://localhost:3000` |
| `METRICS_URL` | Prometheus scrape URL for `01-scrape-prometheus-metrics.sh` |
| `OLLAMA_HOST` / `OLLAMA_PORT` | Used by `07` / `08` / `09` Ollama wrappers (default `127.0.0.1` / `11434`) |

---

## Production mindset

- Replace stub **pricing** with list prices and your **SKU** metadata.  
- Add **sampling** in high-volume paths so observability cost stays bounded.  
- Combine **offline eval** (datasets) with **online** traces and **feedback** joins on `request_id`.  
- Run Langfuse/Phoenix in **your** VPC with auth/TLS for real workloads — the compose here is for learning.

---

## Cleanup

**Local generated files** (gitignored):

```bash
cd 05-llm-monitoring-lab
./scripts/10-cleanup-lab.sh
```

That removes `examples/feedback.jsonl`, `examples/eval_results.jsonl`, `examples/__pycache__/`, and common `/tmp/*metrics*` scrape outputs. It does **not** stop Docker.

**Observability containers:** stop Phoenix / Langfuse with Ctrl+C in the terminal where they run, or:

```bash
# Phoenix (from repo root)
docker compose -f 05-llm-monitoring-lab/deploy/docker-compose.phoenix.yaml down
```

**Optional:** delete a local virtualenv with `rm -rf .venv`.
