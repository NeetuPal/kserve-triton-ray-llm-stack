#!/usr/bin/env python3
"""
Append structured user feedback (simulates prod feedback API → warehouse).

Usage:
  python log_feedback.py --request-id req-1 --rating thumbs_up --comment "Good tone"
  python log_feedback.py --request-id req-2 --rating thumbs_down --note "Hallucination" --file feedback.jsonl

In production you'd POST to your gateway; here we append JSONL for teaching.
"""
from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--request-id", required=True)
    ap.add_argument("--rating", default="neutral", help="thumbs_up | thumbs_down | neutral | 1-5")
    ap.add_argument("--comment", default="", help="Free text")
    ap.add_argument("--note", default="", help="Alias internal note")
    ap.add_argument("--file", type=Path, default=Path("feedback.jsonl"))
    args = ap.parse_args()

    rec = {
        "ts": datetime.now(timezone.utc).isoformat(),
        "request_id": args.request_id,
        "rating": args.rating,
        "comment": args.comment or args.note,
    }
    with args.file.open("a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")
    print(json.dumps({"appended": str(args.file), "record": rec}, indent=2))


if __name__ == "__main__":
    main()
