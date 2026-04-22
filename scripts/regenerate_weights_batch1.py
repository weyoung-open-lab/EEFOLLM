#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Regenerate results/global_experiments_batch1/weights/weights_Map{1..5}.json using llm/generate_qwen_weights.py.

  --mode real   : Qwen2.5 local/HF (slow; needs transformers + GPU recommended)
  --mode auto   : try real, fall back to mock on failure (default)
  --mode mock   : deterministic rule-based from map features (fast; not neural LLM)

NOTE: Python writes raw Qwen/mock JSON. The MATLAB pipeline (generate_llm_weights) runs
validate_llm_weights. For identical behavior to main_run_global_experiments_batch, run MATLAB:

  main_regenerate_llm_weights_maps

after adding repo root to path.

Usage (repo root):
  python scripts/regenerate_weights_batch1.py --mode auto
  python scripts/plot_llm_reward_weights.py --weights-dir results/global_experiments_batch1/weights
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
GEN = REPO / "llm" / "generate_qwen_weights.py"
PROMPT = REPO / "llm" / "prompts" / "reward_prompt.txt"
MODEL = "Qwen/Qwen2.5-3B-Instruct"
FEAT_DIR = REPO / "results" / "global_experiments_batch1" / "features"
OUT_DIR = REPO / "results" / "global_experiments_batch1" / "weights"
DEFAULT_MAPS = [f"Map{i}" for i in range(1, 6)]


def main() -> int:
    ap = argparse.ArgumentParser(description="Regenerate weight JSON via generate_qwen_weights.py")
    ap.add_argument("--mode", choices=("auto", "real", "mock"), default="auto", help="LLM generation mode")
    ap.add_argument(
        "--maps",
        nargs="*",
        metavar="NAME",
        default=None,
        help="Subset e.g. Map3 Map5 (default: Map1..Map5)",
    )
    ap.add_argument("--skip-plot", action="store_true", help="Do not run plot_llm_reward_weights.py")
    args = ap.parse_args()
    maps = list(args.maps) if args.maps else DEFAULT_MAPS

    if not GEN.is_file():
        print("Missing:", GEN, file=sys.stderr)
        return 1

    py = sys.executable
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    for m in maps:
        feat = FEAT_DIR / f"features_{m}.json"
        out_j = OUT_DIR / f"weights_{m}.json"
        if not feat.is_file():
            print("Missing features:", feat, file=sys.stderr)
            return 1
        cmd = [
            py,
            str(GEN),
            "--input",
            str(feat),
            "--output",
            str(out_j),
            "--mode",
            args.mode,
            "--prompt",
            str(PROMPT),
            "--model",
            MODEL,
        ]
        print("Running:", " ".join(cmd))
        r = subprocess.run(cmd, cwd=str(REPO))
        if r.returncode != 0:
            print("Failed for", m, file=sys.stderr)
            return r.returncode
        # Optional: drop _meta so files match MATLAB save_json shape (plot ignores extras)
        try:
            raw = json.loads(out_j.read_text(encoding="utf-8"))
            if isinstance(raw, dict) and "_meta" in raw:
                del raw["_meta"]
                out_j.write_text(json.dumps(raw, ensure_ascii=False, indent=2), encoding="utf-8")
        except Exception as e:
            print("Note: could not strip _meta:", e, file=sys.stderr)

    if not args.skip_plot:
        plot_script = REPO / "scripts" / "plot_llm_reward_weights.py"
        cmd2 = [py, str(plot_script), "--weights-dir", "results/global_experiments_batch1/weights"]
        print("Running:", " ".join(cmd2))
        r2 = subprocess.run(cmd2, cwd=str(REPO))
        if r2.returncode != 0:
            return r2.returncode

    print("Done. Weights:", OUT_DIR)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
