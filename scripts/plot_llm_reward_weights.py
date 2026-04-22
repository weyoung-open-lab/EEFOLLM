#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LLM-based reward shaping 分析图：五张 benchmark 地图 × early/mid/late 三阶段 × (wL, wC, wS, wT)。

数据来源（按优先级自动选择第一个存在的目录）：
  1) results/global_experiments_batch1/weights/weights_Map*.json
  2) results/ablation_eefollm_ablated_only/weights/weights_Map*.json

上述 JSON 由 MATLAB generate_llm_weights 管线写出（校验归一化之后、实际用于优化的阶段权重）。

若多目录均存在，默认用 batch1（与主实验一致）。无需手填权重。

输出（默认）：
  results/figures/llm_reward_analysis/reward_weights_barchart_maps.{png,svg}  （五图合一）
  results/figures/llm_reward_analysis/reward_weights_Map{1..5}_barchart.{png,svg}  （每图单独）
  results/figures/llm_reward_analysis/reward_weights_heatmap.{png,svg}

用法（仓库根目录）：
  python scripts/plot_llm_reward_weights.py
  python scripts/plot_llm_reward_weights.py --weights-dir results/global_experiments_batch1/weights
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Patch

REPO = Path(__file__).resolve().parents[1]
MAPS = [f"Map{i}" for i in range(1, 6)]
STAGES = ("early", "mid", "late")
KEYS = ("wL", "wC", "wS", "wT")
KEY_LABELS = {
    "wL": r"$w_L$ path length",
    "wC": r"$w_C$ collision",
    "wS": r"$w_S$ smoothness",
    "wT": r"$w_T$ turning",
}

# 四分量统一配色（论文用、易区分）
COLORS = {
    "wL": "#2E5B88",
    "wC": "#C45C5C",
    "wS": "#3D8E68",
    "wT": "#B8860B",
}


def resolve_weights_dir(explicit: str | None) -> Path:
    if explicit:
        p = REPO / explicit
        if not p.is_dir():
            print(f"Error: --weights-dir not found: {p}", file=sys.stderr)
            sys.exit(1)
        return p.resolve()
    candidates = [
        REPO / "results" / "global_experiments_batch1" / "weights",
        REPO / "results" / "ablation_eefollm_ablated_only" / "weights",
    ]
    for c in candidates:
        if c.is_dir() and all((c / f"weights_{m}.json").is_file() for m in MAPS):
            print(f"Using weights from: {c}", file=sys.stderr)
            return c
    print(
        "Error: No complete weights_Map1..Map5.json set found. Run batch1 or ablation pipeline first.",
        file=sys.stderr,
    )
    sys.exit(1)


def load_all_weights(wdir: Path) -> dict[str, dict]:
    data = {}
    for m in MAPS:
        fp = wdir / f"weights_{m}.json"
        with fp.open(encoding="utf-8") as f:
            data[m] = json.load(f)
        for st in STAGES:
            if st not in data[m]:
                raise ValueError(f"{fp} missing stage '{st}'")
            for k in KEYS:
                if k not in data[m][st]:
                    raise ValueError(f"{fp} missing {st}.{k}")
    return data


def _ylim_from_data(data: dict[str, dict]) -> float:
    gmax = max(float(data[m][st][k]) for m in MAPS for st in STAGES for k in KEYS)
    return max(0.32, gmax * 1.12)


def _bar_grouped_on_axes(
    ax, m: str, data: dict[str, dict], ylim_hi: float, title: str | None = None
) -> None:
    x = np.arange(len(STAGES))
    n_keys = len(KEYS)
    bar_w = 0.18
    offsets = (np.arange(n_keys) - (n_keys - 1) / 2.0) * bar_w
    for ki, key in enumerate(KEYS):
        vals = [float(data[m][st][key]) for st in STAGES]
        ax.bar(
            x + offsets[ki],
            vals,
            width=bar_w,
            color=COLORS[key],
            edgecolor="white",
            linewidth=0.4,
        )
    ax.set_xticks(x)
    ax.set_xticklabels([s.capitalize() for s in STAGES])
    ax.set_ylabel("Weight (normalized)")
    ax.set_title(m if title is None else title, fontweight="semibold", fontsize=10)
    ax.set_ylim(0, ylim_hi)
    ax.grid(axis="y", linestyle="-", alpha=0.28, linewidth=0.7)
    ax.set_axisbelow(True)


def plot_barchart(data: dict[str, dict], out_base: Path) -> None:
    """2×3 子图，五张地图；横轴 early/mid/late，每位置 4 根柱 wL..wT。"""
    fig, axes = plt.subplots(2, 3, figsize=(11.2, 7.0), dpi=120)
    axes = axes.flatten()
    plt.rcParams.update({"font.family": "DejaVu Sans"})

    ylim_hi = _ylim_from_data(data)

    for ax_idx, m in enumerate(MAPS):
        _bar_grouped_on_axes(axes[ax_idx], m, data, ylim_hi, title=None)

    axes[5].axis("off")
    fig.suptitle(
        "LLM-based stage-wise reward weights (benchmark maps)",
        fontsize=11,
        fontweight="normal",
        y=0.98,
    )
    legend_handles = [
        Patch(facecolor=COLORS[k], edgecolor="white", linewidth=0.4, label=KEY_LABELS[k]) for k in KEYS
    ]
    fig.legend(
        handles=legend_handles,
        loc="lower center",
        ncol=4,
        frameon=True,
        fontsize=8.5,
        bbox_to_anchor=(0.5, 0.02),
        columnspacing=1.2,
    )
    fig.subplots_adjust(left=0.07, right=0.98, top=0.90, bottom=0.18, hspace=0.38, wspace=0.28)
    _save_png_svg(fig, out_base.with_name(out_base.name + "_barchart_maps"))


def plot_barchart_per_map(data: dict[str, dict], out_dir: Path) -> None:
    """每张地图单独保存一张柱状图（与组合图相同标尺 ylim_hi）。"""
    plt.rcParams.update({"font.family": "DejaVu Sans"})
    ylim_hi = _ylim_from_data(data)
    legend_handles = [
        Patch(facecolor=COLORS[k], edgecolor="white", linewidth=0.4, label=KEY_LABELS[k]) for k in KEYS
    ]
    for m in MAPS:
        fig, ax = plt.subplots(figsize=(4.6, 3.6), dpi=120)
        _bar_grouped_on_axes(
            ax,
            m,
            data,
            ylim_hi,
            title=f"{m} — LLM stage-wise reward weights",
        )
        fig.legend(
            handles=legend_handles,
            loc="lower center",
            ncol=4,
            frameon=True,
            fontsize=7.5,
            bbox_to_anchor=(0.5, -0.02),
            columnspacing=1.0,
        )
        fig.subplots_adjust(bottom=0.22, left=0.12, right=0.97, top=0.88)
        stem = out_dir / f"reward_weights_{m}_barchart"
        _save_png_svg(fig, stem)


def plot_heatmap(data: dict[str, dict], out_base: Path) -> None:
    rows: list[list[float]] = []
    row_labels: list[str] = []
    for m in MAPS:
        for st in STAGES:
            row_labels.append(f"{m} — {st}")
            rows.append([float(data[m][st][k]) for k in KEYS])

    Z = np.asarray(rows, dtype=float)
    fig, ax = plt.subplots(figsize=(5.2, 8.0), dpi=120)
    im = ax.imshow(Z, aspect="auto", cmap="YlOrRd", vmin=0, vmax=max(0.45, float(Z.max())))

    ax.set_xticks(np.arange(4))
    ax.set_xticklabels([r"$w_L$", r"$w_C$", r"$w_S$", r"$w_T$"])
    ax.set_yticks(np.arange(len(row_labels)))
    ax.set_yticklabels(row_labels, fontsize=7)
    ax.set_xlabel("Reward component", fontsize=9)
    ax.set_title("LLM stage weights heatmap (maps × stages)", fontsize=10)

    cbar = fig.colorbar(im, ax=ax, fraction=0.046, pad=0.04)
    cbar.set_label("Weight", fontsize=9)

    fig.tight_layout()
    _save_png_svg(fig, out_base.with_name(out_base.name + "_heatmap"))


def _save_png_svg(fig, base_stem: Path) -> None:
    """base_stem: path without extension, e.g. .../reward_barchart_maps"""
    png = Path(str(base_stem) + ".png")
    svg = Path(str(base_stem) + ".svg")
    png.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(png, dpi=300, bbox_inches="tight", facecolor="white")
    try:
        fig.savefig(svg, format="svg", bbox_inches="tight", facecolor="white")
    except Exception:
        fig.savefig(svg, format="svg", bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print("Wrote", png)
    print("Wrote", svg)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--weights-dir",
        type=str,
        default="",
        help="Folder containing weights_Map1.json … weights_Map5.json",
    )
    ap.add_argument(
        "--out-dir",
        type=str,
        default="results/figures/llm_reward_analysis",
        help="Output directory (under repo root unless absolute)",
    )
    args = ap.parse_args()

    wdir = resolve_weights_dir(args.weights_dir or None)
    data = load_all_weights(wdir)

    out_dir = REPO / args.out_dir.strip("/\\")
    out_dir.mkdir(parents=True, exist_ok=True)
    stem = out_dir / "reward_weights"
    plot_barchart(data, stem)
    plot_barchart_per_map(data, out_dir)
    plot_heatmap(data, stem)

    note = out_dir / "DATA_SOURCE.txt"
    note.write_text(
        "Weights loaded from (per-map stage weights used in optimization):\n"
        f"  {wdir}\n\n"
        "Each JSON has keys early/mid/late with wL,wC,wS,wT (post-validation).\n"
        "Single set per map — no averaging across runs (weights fixed per map for a given generation).\n\n"
        "If Map1/Map2 look uniform (e.g. 0.25 each): check logs — batch1 uses fallback=0 when Python+validation\n"
        "succeed; flat bars then mean validated LLM vectors were near-uniform on easy maps, not\n"
        "a missing JSON. To resample weights: MATLAB main_regenerate_llm_weights_maps, then re-run this script.\n",
        encoding="utf-8",
    )
    print("Wrote", note)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
