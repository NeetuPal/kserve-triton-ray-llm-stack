#!/usr/bin/env python3
"""
Lightweight "evaluation pipeline" on a JSONL file of prompt/response[/reference].

No cloud judge required — teaches structure you can swap for Ragas, OpenAI grader, etc.
Each line: {"id","prompt","response","reference"?}
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


def score_row(row: dict) -> dict:
    rid = row.get("id", "?")
    resp = (row.get("response") or "").strip()
    ref = (row.get("reference") or "").strip()
    prompt = row.get("prompt", "")

    checks = {
        "non_empty": len(resp) > 0,
        "min_length_10": len(resp) >= 10,
        "no_refusal_phrase": not re.search(
            r"\b(can't|cannot|sorry, i can't)\b", resp.lower()
        ),
    }
    if ref:
        checks["reference_in_response"] = ref.lower() in resp.lower()

    bools = [v for v in checks.values() if isinstance(v, bool)]
    quality_score = sum(1 for v in bools if v) / max(len(bools), 1)

    return {
        "id": rid,
        "prompt_len": len(prompt),
        "response_len": len(resp),
        "checks": checks,
        "quality_score": round(quality_score, 3),
    }


def main() -> None:
    ap = argparse.ArgumentParser(description="Batch quality checks on JSONL.")
    ap.add_argument("jsonl", type=Path, help="Path to .jsonl file")
    ap.add_argument(
        "-o", "--out", type=Path, default=None, help="Write per-row results JSONL"
    )
    args = ap.parse_args()

    rows: list[dict] = []
    with args.jsonl.open(encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            rows.append(json.loads(line))

    results = [score_row(r) for r in rows]
    avg_q = sum(r["quality_score"] for r in results) / max(len(results), 1)

    summary = {
        "rows": len(results),
        "avg_quality_score": round(avg_q, 3),
        "pass_threshold_0_8": sum(1 for r in results if r["quality_score"] >= 0.8),
    }
    print(json.dumps({"summary": summary, "details": results}, indent=2))

    if args.out:
        with args.out.open("w", encoding="utf-8") as f:
            for r in results:
                f.write(json.dumps(r) + "\n")
        print(f"Wrote {args.out}", file=sys.stderr)


if __name__ == "__main__":
    main()
