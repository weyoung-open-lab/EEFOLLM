#!/usr/bin/env python3
"""Deterministic mock LLM reward generator for offline reproducibility."""
import argparse
import json
from copy import deepcopy


def clip_norm(stage):
    vals = [max(0.05, min(0.85, float(stage[k]))) for k in ("wL", "wC", "wS", "wT")]
    s = sum(vals) if sum(vals) > 0 else 1.0
    vals = [v / s for v in vals]
    return {"wL": vals[0], "wC": vals[1], "wS": vals[2], "wT": vals[3]}


def build_mock_weights(feat):
    density = float(feat.get("obstacle_density", 0.15))
    narrow = float(feat.get("narrow_corridor_ratio", 0.2))
    turning = float(feat.get("turning_difficulty_score", 0.3))
    clutter = float(feat.get("clutter_score", 0.3))
    complexity = 0.35 * density + 0.25 * narrow + 0.2 * turning + 0.2 * clutter
    complexity = max(0.0, min(1.0, complexity))

    early = {
        "wL": 0.25 - 0.10 * complexity,
        "wC": 0.45 + 0.20 * complexity,
        "wS": 0.18 + 0.05 * complexity,
        "wT": 0.12 - 0.05 * complexity,
    }
    mid = {
        "wL": 0.32 - 0.06 * complexity,
        "wC": 0.35 + 0.12 * complexity,
        "wS": 0.20 + 0.06 * complexity,
        "wT": 0.13 - 0.04 * complexity,
    }
    late = {
        "wL": 0.44 - 0.12 * complexity,
        "wC": 0.20 + 0.10 * complexity,
        "wS": 0.22 + 0.08 * complexity,
        "wT": 0.14 - 0.03 * complexity,
    }
    return {"early": clip_norm(early), "mid": clip_norm(mid), "late": clip_norm(late)}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    with open(args.input, "r", encoding="utf-8") as f:
        feat = json.load(f)
    out = build_mock_weights(feat)
    out["_meta"] = {"mode": "mock", "note": "deterministic rule-based weights"}
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)


if __name__ == "__main__":
    main()
