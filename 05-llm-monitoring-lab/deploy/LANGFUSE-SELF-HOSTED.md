# Langfuse self-hosted (official Docker Compose)

Use this when you want **Langfuse on your machine** instead of [Langfuse Cloud](https://cloud.langfuse.com/).

## What you are starting (real-time data path)

1. Your **app / lab script** sends traces to the Langfuse **HTTP API** (SDK batches and POSTs events).
2. The **web** container stores metadata in **Postgres**, large analytics in **ClickHouse**, queue/cache in **Redis**, blobs in **S3-compatible** storage (MinIO in the default compose).
3. A **worker** processes the queue so the **UI** at port **3000** shows generations, latency, and token usage within seconds.

## Steps (copy-paste)

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or Docker Engine + Compose plugin).

2. Clone the official repo (compose file lives there):

   ```bash
   git clone https://github.com/langfuse/langfuse.git
   cd langfuse
   ```

3. Edit `docker-compose.yml`: replace every `# CHANGEME` secret with long random values (see [upstream guide](https://langfuse.com/self-hosting/deployment/docker-compose)).

4. Start:

   ```bash
   docker compose up
   ```

5. Wait until logs show the web container **Ready** (~2–3 minutes first time).

6. Open **http://localhost:3000**, sign up / create an **organization** and **project**.

7. **Settings → API keys** → create **public** and **secret** keys for the SDK.

8. Point this lab’s scripts at your instance:

   ```bash
   export LANGFUSE_BASE_URL=http://localhost:3000
   export LANGFUSE_PUBLIC_KEY=pk-lf-...
   export LANGFUSE_SECRET_KEY=sk-lf-...
   ```

9. Run the trace demo from `05-llm-monitoring-lab` (after your LLM `OPENAI_*` vars are set):

   ```bash
   cd ../path/to/kserve-triton-ray-llm-stack/05-llm-monitoring-lab/scripts
   ./06-langfuse-trace.sh
   ```

10. In the Langfuse UI, open **Traces** — you should see a new generation within a few seconds (the example calls `flush()` so short scripts still show up).

## Shutdown

```bash
docker compose down
```

Add `-v` only if you intend to wipe local databases.
