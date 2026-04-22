#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Schematic: LLM stage weights (conceptual; no script paths).

Output:
  results/figures/llm_reward_analysis/reward_pipeline_llm_detail.{png,svg}

From repo root:
  python scripts/plot_llm_reward_pipeline_diagram.py
"""

from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch

REPO = Path(__file__).resolve().parents[1]
OUT_DIR = REPO / "results" / "figures" / "llm_reward_analysis"


def _setup_font() -> None:
    plt.rcParams["font.sans-serif"] = ["DejaVu Sans", "Arial", "Helvetica"]
    plt.rcParams["axes.unicode_minus"] = False


def _box(ax, x: float, y: float, w: float, h: float, text: str, fc: str = "#f0f4f8", ec: str = "#334155") -> None:
    p = FancyBboxPatch(
        (x, y),
        w,
        h,
        boxstyle="round,pad=0.015,rounding_size=0.08",
        linewidth=1.2,
        edgecolor=ec,
        facecolor=fc,
        zorder=2,
    )
    ax.add_patch(p)
    ax.text(
        x + w / 2,
        y + h / 2,
        text,
        ha="center",
        va="center",
        fontsize=8.0,
        color="#1e293b",
        linespacing=1.16,
        zorder=3,
    )


def _arrow(ax, x1: float, y1: float, x2: float, y2: float) -> None:
    arr = FancyArrowPatch(
        (x1, y1),
        (x2, y2),
        arrowstyle="-|>",
        mutation_scale=12,
        linewidth=1.1,
        color="#475569",
        zorder=1,
    )
    ax.add_patch(arr)


def main() -> int:
    _setup_font()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    stem = OUT_DIR / "reward_pipeline_llm_detail"

    fig, ax = plt.subplots(figsize=(6.8, 7.95), dpi=120)
    ax.set_xlim(0, 6.8)
    ax.set_ylim(0, 7.95)
    ax.axis("off")

    ax.text(
        3.4,
        7.58,
        "LLM stage weights: offline build → runtime use",
        ha="center",
        va="top",
        fontsize=10.5,
        fontweight="semibold",
        color="#0f172a",
    )
    ax.text(
        3.4,
        7.22,
        "(schematic; optional post-processing omitted)",
        ha="center",
        va="top",
        fontsize=7.5,
        color="#64748b",
    )

    ax.text(0.32, 6.88, "A. Once per map (before search)", fontsize=8.5, fontweight="bold", color="#0f172a")

    w, h = 6.0, 0.58
    positions = [
        (0.4, 6.22, "1  Map features\nReproducible map statistics as LLM context."),
        (0.4, 5.44, "2  LLM\nConditional generation of stage-wise weights; no gradient update on weights."),
        (0.4, 4.66, "3  Validate\nNonnegative, sum-to-1 per stage; clip or fallback."),
        (0.4, 3.88, "4  Store\nearly / mid / late saved; LLM not called in the search loop."),
    ]
    for i, (px, py, txt) in enumerate(positions):
        _box(ax, px, py, w, h, txt)
        if i < len(positions) - 1:
            _arrow(ax, px + w / 2, py, px + w / 2, positions[i + 1][1] + h + 0.02)

    ax.text(0.32, 3.42, "B. Each iteration", fontsize=8.5, fontweight="bold", color="#0f172a")
    _box(
        ax,
        0.4,
        0.62,
        6.0,
        0.78,
        "5  Runtime\nStage by progress; weighted sum of reward terms. EEFO searches paths; weights fixed.",
        fc="#ecfdf5",
        ec="#059669",
    )
    _arrow(ax, 3.4, 3.88, 3.4, 1.42)

    fig.tight_layout()
    png = stem.with_suffix(".png")
    svg = stem.with_suffix(".svg")
    fig.savefig(png, dpi=300, bbox_inches="tight", facecolor="white")
    fig.savefig(svg, format="svg", bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print("Wrote", png)
    print("Wrote", svg)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
