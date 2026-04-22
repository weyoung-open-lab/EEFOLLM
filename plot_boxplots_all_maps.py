#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
plot_boxplots_all_maps.py — 论文主图：5 张地图 × 10 算法箱线图（matplotlib）。

与 MATLAB 版同源数据：records_merged.csv；LLM-EEFO → EEFOLLM。

纵轴指标（--metric）：
  bestfit_feasible（默认）— 仅 CollisionFree=1 的 run 上的 BestFit（与常见论文里「十几～几十」的路径代价量级一致，
    不含碰撞硬惩罚 1e4 量级）。
  bestfit — 全部 run 的 BestFit（含碰撞项，可达数千～数万，用于展示失败/碰撞时的完整目标）。
  path_length — 路径长度（PathLength 列，网格单位，通常几十～百余）。

说明：若某列 IQR=0，箱高为 0 属正常。对数纵轴按数据跨度自动选择；零方差列加粗中位线。

依赖：numpy, matplotlib
  pip install numpy matplotlib

用法（仓库根目录）：
  python plot_boxplots_all_maps.py
  python plot_boxplots_all_maps.py --metric bestfit
  python plot_boxplots_all_maps.py --csv path/to/records.csv
"""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

ALGOS10 = [
    "AOA",
    "EO",
    "GTO",
    "HHO",
    "HO",
    "MPA",
    "SBOA",
    "SMA",
    "SSA",
    "EEFOLLM",
]
MAPS = ["Map1", "Map2", "Map3", "Map4", "Map5"]
EXPECTED_RUNS = 20
LOG_RATIO_THRESH = 50.0


def repo_root() -> Path:
    return Path(__file__).resolve().parent


def load_records(csv_path: Path):
    rows = []
    with csv_path.open(newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            a = row.get("Algorithm", "").strip()
            if a == "LLM-EEFO":
                a = "EEFOLLM"
            row["Algorithm"] = a
            rows.append(row)
    return rows


def _collision_free(row: dict) -> bool:
    v = row.get("CollisionFree", "")
    if v is None or v == "":
        return False
    try:
        return float(v) >= 0.5
    except (TypeError, ValueError):
        return str(v).strip().lower() in ("1", "true", "yes")


def build_matrix(
    rows: list[dict],
    map_name: str,
    algos: list[str],
    expected_runs: int,
    metric: str = "bestfit_feasible",
) -> np.ndarray:
    """Shape (expected_runs, n_algo), rows = run index 1..expected_runs."""
    na = len(algos)
    M = np.full((expected_runs, na), np.nan, dtype=float)
    for ai, algo in enumerate(algos):
        sub = [r for r in rows if r.get("Map") == map_name and r.get("Algorithm") == algo]
        for r in sub:
            try:
                run = int(float(r.get("Run", "nan")))
            except (TypeError, ValueError):
                continue
            if not (1 <= run <= expected_runs):
                continue
            try:
                if metric == "bestfit":
                    M[run - 1, ai] = float(r["BestFit"])
                elif metric == "bestfit_feasible":
                    if _collision_free(r):
                        M[run - 1, ai] = float(r["BestFit"])
                elif metric == "path_length":
                    M[run - 1, ai] = float(r["PathLength"])
                else:
                    M[run - 1, ai] = float(r["BestFit"])
            except (KeyError, TypeError, ValueError):
                pass
    return M


def metric_ylabel_title_suffix(metric: str) -> tuple[str, str]:
    if metric == "bestfit":
        return (
            "Fitness value (full objective, incl. collision penalty)",
            " — full objective",
        )
    if metric == "path_length":
        return ("Path length (grid units)", " — path length")
    return (
        "Best fitness (collision-free runs only)",
        " — feasible runs",
    )


def pick_y_scale(M: np.ndarray, mode: str) -> bool:
    if mode == "log":
        return True
    if mode == "linear":
        return False
    v = M[np.isfinite(M) & (M > 0)]
    if v.size < 2:
        return False
    r = float(np.max(v) / np.min(v))
    return np.isfinite(r) and r >= LOG_RATIO_THRESH


def plot_one_map(
    M: np.ndarray,
    map_name: str,
    algos: list[str],
    use_log: bool,
    out_paths: list,
    metric: str,
) -> None:
    n = len(algos)
    fig_w = max(12.0, 0.95 * n + 2.0)
    fig, ax = plt.subplots(figsize=(fig_w, 5.2), dpi=120)
    fig.patch.set_facecolor("white")

    # 列数据列表（matplotlib boxplot 要 list of 1d）
    cols = [M[:, j].astype(float) for j in range(n)]
    cols_plot = []
    for c in cols:
        x = c[np.isfinite(c) & (c > 0)]
        cols_plot.append(x if x.size else np.array([np.nan]))

    positions = np.arange(1, n + 1)
    vpos = M[np.isfinite(M) & (M > 0)]

    if vpos.size == 0:
        ax.text(
            0.5,
            0.5,
            "No usable Y values for this metric on this map.\n"
            "For --metric bestfit_feasible: no collision-free runs.\n"
            "Try:  python plot_boxplots_all_maps.py --metric bestfit",
            transform=ax.transAxes,
            ha="center",
            va="center",
            fontsize=10,
            color="0.35",
        )
    else:
        ax.boxplot(
            cols_plot,
            positions=positions,
            widths=0.55,
            patch_artist=True,
            showfliers=True,
            flierprops=dict(marker="+", markerfacecolor="red", markersize=7, linestyle="none"),
            medianprops=dict(color="0.05", linewidth=2.2),
            whiskerprops=dict(color="0.35", linewidth=1.0, linestyle="--"),
            capprops=dict(color="0.35", linewidth=1.0),
            boxprops=dict(facecolor="#dbe0ee", edgecolor="#4a5560", linewidth=1.0),
        )

        # 零方差列：加粗中位线区段（避免“看不见箱体”时仍有一条细线）
        for j, c in enumerate(cols):
            arr = c[np.isfinite(c) & (c > 0)]
            if arr.size < 2:
                continue
            u = np.unique(arr)
            spread = float(np.max(arr) - np.min(arr))
            if u.size == 1 or spread < 1e-12 * max(1.0, float(np.median(arr))):
                m = float(np.median(arr))
                ax.plot(
                    [positions[j] - 0.38, positions[j] + 0.38],
                    [m, m],
                    color="#1a3a5c",
                    linewidth=5.0,
                    solid_capstyle="butt",
                    zorder=4,
                    alpha=0.85,
                )

        if use_log:
            ax.set_yscale("log")
            lo = float(np.nanmin(vpos))
            hi = float(np.nanmax(vpos))
            if np.isfinite(lo) and np.isfinite(hi) and lo > 0:
                if hi <= lo * 1.001:
                    hi = lo * 1.15
                ax.set_ylim(lo * 0.88, hi * 1.12)
        else:
            lo = float(np.nanmin(M[np.isfinite(M)]))
            hi = float(np.nanmax(M[np.isfinite(M)]))
            if np.isfinite(lo) and np.isfinite(hi):
                pad = (hi - lo) * 0.06 + 1e-9
                if pad < 1e-12:
                    pad = max(abs(lo), 1.0) * 0.05
                ax.set_ylim(lo - pad, hi + pad)

        # 仅「可行 run」指标下：无碰撞自由路径的算法在数据上就是全 NaN，不是漏画
        if metric == "bestfit_feasible":
            lo_a, hi_a = ax.get_ylim()
            if ax.get_yscale() == "log":
                y_note = float(np.sqrt(lo_a * hi_a))
            else:
                y_note = (lo_a + hi_a) / 2
            for j in range(n):
                c = cols[j]
                good = np.isfinite(c) & (c > 0)
                if np.any(good):
                    continue
                ax.text(
                    positions[j],
                    y_note,
                    "No feasible\npath (0/20)",
                    ha="center",
                    va="center",
                    fontsize=7.5,
                    color="0.4",
                    zorder=10,
                )

    ax.set_xticks(positions)
    ax.set_xticklabels(algos, rotation=40, ha="right")
    ax.grid(True, which="major", linestyle="-", alpha=0.35)
    ax.grid(True, which="minor", linestyle=":", alpha=0.2)
    ax.set_axisbelow(True)

    ylab, title_suffix = metric_ylabel_title_suffix(metric)
    if use_log:
        ylab += " (log-scaled Y; lower is better)"
    else:
        ylab += " (lower is better)"
    ax.set_ylabel(ylab, fontsize=11)
    ax.set_title(
        f"{map_name} — distribution over 20 independent runs{title_suffix}",
        fontsize=12,
        fontweight="normal",
    )

    plt.tight_layout()
    for p in out_paths:
        p = Path(p)
        p.parent.mkdir(parents=True, exist_ok=True)
        if p.suffix.lower() == ".png":
            fig.savefig(p, dpi=300, bbox_inches="tight", facecolor="white")
        elif p.suffix.lower() == ".svg":
            try:
                fig.savefig(p, format="svg", bbox_inches="tight", facecolor="white")
            except Exception as e:
                print(f"Warning: SVG save failed {p}: {e}", file=sys.stderr)
    plt.close(fig)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", type=str, default="", help="records CSV path")
    ap.add_argument(
        "--y-scale",
        choices=("auto", "log", "linear"),
        default="auto",
        help="Y axis scale policy",
    )
    ap.add_argument(
        "--metric",
        choices=("bestfit_feasible", "bestfit", "path_length"),
        default="bestfit_feasible",
        help="Y value: feasible BestFit (default, ~10^1), full BestFit (large if collisions), or PathLength",
    )
    args = ap.parse_args()

    root = repo_root()
    if args.csv:
        csv_path = Path(args.csv)
    else:
        csv_path = root / "results" / "global_experiments_merged" / "tables" / "records_merged.csv"
    if not csv_path.is_file():
        print(f"Error: CSV not found: {csv_path}", file=sys.stderr)
        return 1

    rows = load_records(csv_path)
    fig_dir = root / "figures" / "paper_main"
    res_dir = root / "results" / "boxplot_maps"
    fig_dir.mkdir(parents=True, exist_ok=True)
    res_dir.mkdir(parents=True, exist_ok=True)

    metric_tag = {
        "bestfit_feasible": "fitness",
        "bestfit": "fitness_full",
        "path_length": "pathlength",
    }[args.metric]

    for map_name in MAPS:
        M = build_matrix(rows, map_name, ALGOS10, EXPECTED_RUNS, args.metric)
        use_log = pick_y_scale(M, args.y_scale)
        base = f"boxplot_{metric_tag}_{map_name}"
        base2 = f"boxplot_{metric_tag}_{map_name}_all10"
        outs = [
            fig_dir / f"{base}.png",
            fig_dir / f"{base}.svg",
            res_dir / f"{base2}.png",
            res_dir / f"{base2}.svg",
        ]
        plot_one_map(M, map_name, ALGOS10, use_log, outs, args.metric)
        print(f"Saved: {base}.png/.svg -> figures/paper_main + results/boxplot_maps")

    print("Done.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
