#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从 records_merged + 消融 records 合并，生成 ablation_result 下的表与箱线图。

用法（仓库根目录）：  python scripts/export_ablation_result.py

收敛图：运行 python scripts/plot_ablation_convergence.py（依赖 batch1 与消融的 global_results.mat；需 mat73）
"""

from __future__ import annotations

import csv
import math
import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "results" / "ablation_result"
TABLES = OUT / "tables"
FIGS = OUT / "figures" / "boxplots"
CONV = OUT / "figures" / "convergence"

MAPS = ["Map1", "Map2", "Map3", "Map4", "Map5"]
ABL_ALGOS = ["EEFO", "EEFOLLM", "EEFOLLM-NJ", "EEFOLLM-NS", "EEFOLLM-PARTIAL"]
EXPECTED_RUNS = 20


def _safe_float(x, default=float("nan")):
    try:
        return float(x)
    except (TypeError, ValueError):
        return default


def load_csv(path: Path) -> list[dict]:
    rows = []
    with path.open(newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            a = row.get("Algorithm", "").strip()
            if a == "LLM-EEFO":
                a = "EEFOLLM"
            row["Algorithm"] = a
            rows.append(row)
    return rows


def merge_records() -> list[dict]:
    merged_path = ROOT / "results" / "global_experiments_merged" / "tables" / "records_merged.csv"
    abl_path = ROOT / "results" / "ablation_eefollm_ablated_only" / "tables" / "records.csv"
    if not merged_path.is_file():
        print(f"Missing {merged_path}", file=sys.stderr)
        sys.exit(1)
    if not abl_path.is_file():
        print(f"Missing {abl_path}", file=sys.stderr)
        sys.exit(1)
    m = load_csv(merged_path)
    a = load_csv(abl_path)
    want = {"EEFO", "EEFOLLM"}
    sub_m = [r for r in m if r.get("Map", "").strip() in MAPS and r.get("Algorithm", "").strip() in want]
    sub_a = [r for r in a if r.get("Map", "").strip() in MAPS and r.get("Algorithm", "").strip() in ABL_ALGOS[2:]]
    return sub_m + sub_a


def ranks_lower_better(x: np.ndarray) -> np.ndarray:
    """Lower value -> rank 1; ties -> average rank (1-based). NaN -> NaN."""
    x = np.asarray(x, dtype=float).ravel()
    n = len(x)
    r = np.full(n, np.nan)
    idx = np.flatnonzero(np.isfinite(x))
    if idx.size == 0:
        return r
    xv = x[idx]
    order = np.argsort(xv)
    sx = xv[order]
    m = len(sx)
    rk = np.empty(m)
    t = 0
    while t < m:
        u = t
        while u < m and abs(sx[u] - sx[t]) <= 1e-9 * max(1.0, abs(sx[t])):
            u += 1
        rk[t:u] = (t + u + 1) / 2.0
        t = u
    out_sub = np.empty(m)
    for k in range(m):
        out_sub[order[k]] = rk[k]
    r[idx] = out_sub
    return r


def competition_rank(mean_ranks: np.ndarray) -> np.ndarray:
    """Lower mean rank -> FinalRank 1 (competition rank, ties same integer)."""
    x = np.asarray(mean_ranks, dtype=float)
    n = len(x)
    out = np.full(n, np.nan)
    fin = np.isfinite(x)
    if not np.any(fin):
        return out
    xi = x[fin]
    ord_idx = np.argsort(xi)
    sorted_x = xi[ord_idx]
    pr = np.empty_like(sorted_x)
    i = 0
    m = len(sorted_x)
    while i < m:
        j = i
        while j < m and abs(sorted_x[j] - sorted_x[i]) <= 1e-9 * max(1.0, abs(sorted_x[i])):
            j += 1
        pr[i:j] = i + 1
        i = j
    full = np.empty_like(xi)
    full[ord_idx] = pr
    out[fin] = full
    return out


def build_fitness_long(rows: list[dict]) -> list[dict]:
    out = []
    for m in MAPS:
        means = []
        stats = []
        for algo in ABL_ALGOS:
            vals = [
                _safe_float(r["BestFit"])
                for r in rows
                if r.get("Map", "").strip() == m and r.get("Algorithm", "").strip() == algo
            ]
            vals = [v for v in vals if math.isfinite(v)]
            if not vals:
                means.append(float("nan"))
                stats.append(None)
                continue
            arr = np.array(vals, dtype=float)
            stats.append(
                {
                    "bf": float(np.min(arr)),
                    "mn": float(np.mean(arr)),
                    "wx": float(np.max(arr)),
                    "sd": float(np.std(arr)) if len(arr) > 1 else 0.0,
                }
            )
            means.append(float(np.mean(arr)))
        mn_vec = np.array(means, dtype=float)
        rk = ranks_lower_better(mn_vec)
        for ai, algo in enumerate(ABL_ALGOS):
            if stats[ai] is None:
                out.append(
                    {
                        "Map": m,
                        "Algorithm": algo,
                        "BestFitness": "",
                        "MeanFitness": "",
                        "WorstFitness": "",
                        "StdFitness": "",
                        "RankByMean": "",
                    }
                )
                continue
            s = stats[ai]
            out.append(
                {
                    "Map": m,
                    "Algorithm": algo,
                    "BestFitness": s["bf"],
                    "MeanFitness": s["mn"],
                    "WorstFitness": s["wx"],
                    "StdFitness": s["sd"],
                    "RankByMean": float(rk[ai]) if math.isfinite(rk[ai]) else "",
                }
            )
    return out


def build_summary_ranks(flong: list[dict]) -> list[dict]:
    A = np.full((len(ABL_ALGOS), len(MAPS)), np.nan)
    for mi, m in enumerate(MAPS):
        for ai, algo in enumerate(ABL_ALGOS):
            for row in flong:
                if row["Map"] != m or row["Algorithm"] != algo:
                    continue
                rbm = row.get("RankByMean", "")
                if rbm == "" or rbm is None:
                    continue
                A[ai, mi] = float(rbm)
    mean_rk = np.nanmean(A, axis=1)
    fr = competition_rank(mean_rk)
    return [
        {
            "Algorithm": ABL_ALGOS[i],
            "MeanRank_across_maps": mean_rk[i] if np.isfinite(mean_rk[i]) else "",
            "FinalRank": int(fr[i]) if np.isfinite(fr[i]) else "",
        }
        for i in range(len(ABL_ALGOS))
    ]


def write_table2():
    rows = [
        {
            "Algorithm": "EEFO",
            "KeyParameters": (
                "Static scalar weights cfg.weights.default; full EEFO: temp=1-t/T, "
                "Gaussian shock scale 0.08 on (ub-lb), guide toward global best, "
                "random domain re-initialization with probability 0.25."
            ),
        },
        {
            "Algorithm": "EEFOLLM",
            "KeyParameters": (
                "Per-map LLM (Qwen2.5) early/mid/late stage weights; "
                "iter progress splits for stages; same full EEFO search operators as EEFO."
            ),
        },
        {
            "Algorithm": "EEFOLLM-NJ",
            "KeyParameters": (
                "Same LLM stage weights as EEFOLLM; EEFO without random re-initialization "
                "(no global uniform resample of the candidate)."
            ),
        },
        {
            "Algorithm": "EEFOLLM-NS",
            "KeyParameters": (
                "Same LLM stage weights as EEFOLLM; EEFO without Gaussian shock."
            ),
        },
        {
            "Algorithm": "EEFOLLM-PARTIAL",
            "KeyParameters": (
                "Same LLM stage weights as EEFOLLM; EEFO guide-only update "
                "(no shock, no random re-initialization)."
            ),
        },
    ]
    path = TABLES / "table2_algorithm_settings_ablation.csv"
    with path.open("w", newline="", encoding="utf-8-sig") as f:
        w = csv.DictWriter(f, fieldnames=["Algorithm", "KeyParameters"])
        w.writeheader()
        w.writerows(rows)
    print("Wrote", path)


def _format_fitness_row_for_csv(row: dict) -> dict:
    """Two decimals for fitness stats; RankByMean as integer string."""
    out = dict(row)
    for k in ("BestFitness", "MeanFitness", "WorstFitness", "StdFitness"):
        v = out.get(k, "")
        if v == "" or v is None:
            continue
        try:
            out[k] = f"{float(v):.2f}"
        except (TypeError, ValueError):
            pass
    rbm = out.get("RankByMean", "")
    if rbm != "" and rbm is not None:
        try:
            out["RankByMean"] = str(int(round(float(rbm))))
        except (TypeError, ValueError):
            pass
    return out


def write_fitness_tables(flong: list[dict], summary: list[dict]):
    p1 = TABLES / "table3_fitness_long.csv"
    with p1.open("w", newline="", encoding="utf-8-sig") as f:
        w = csv.DictWriter(
            f,
            fieldnames=[
                "Map",
                "Algorithm",
                "BestFitness",
                "MeanFitness",
                "WorstFitness",
                "StdFitness",
                "RankByMean",
            ],
        )
        w.writeheader()
        for row in flong:
            w.writerow(_format_fitness_row_for_csv(row))
    print("Wrote", p1)
    p2 = TABLES / "table3_summary_ranks.csv"
    with p2.open("w", newline="", encoding="utf-8-sig") as f:
        w = csv.DictWriter(f, fieldnames=["Algorithm", "MeanRank_across_maps", "FinalRank"])
        w.writeheader()
        w.writerows(summary)
    print("Wrote", p2)


def write_merged_records(rows: list[dict]):
    path = TABLES / "ablation_records_merged.csv"
    if not rows:
        return
    fields = list(rows[0].keys())
    with path.open("w", newline="", encoding="utf-8-sig") as f:
        w = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
        w.writeheader()
        w.writerows(rows)
    print("Wrote", path)


def plot_boxplots(rows: list[dict]):
    FIGS.mkdir(parents=True, exist_ok=True)
    for m in MAPS:
        cols = []
        for algo in ABL_ALGOS:
            vals = [
                _safe_float(r["BestFit"])
                for r in rows
                if r.get("Map", "").strip() == m and r.get("Algorithm", "").strip() == algo
            ]
            vals = [v for v in vals if math.isfinite(v) and v > 0]
            cols.append(np.array(vals, dtype=float) if vals else np.array([np.nan]))
        fig_w = max(10.0, 0.75 * len(ABL_ALGOS) + 2.0)
        fig, ax = plt.subplots(figsize=(fig_w, 4.8), dpi=120)
        # Outliers: red plus markers (not matplotlib default)
        bp = ax.boxplot(
            cols,
            positions=range(1, len(ABL_ALGOS) + 1),
            widths=0.55,
            patch_artist=True,
            showfliers=True,
            flierprops=dict(
                marker="+",
                markerfacecolor="red",
                markeredgecolor="red",
                markersize=7,
                linestyle="none",
            ),
            medianprops=dict(color="0.05", linewidth=2.2),
            whiskerprops=dict(color="0.35", linewidth=1.0, linestyle="--"),
            capprops=dict(color="0.35", linewidth=1.0),
            boxprops=dict(facecolor="#dbe0ee", edgecolor="#4a5560", linewidth=1.0),
        )
        for p in bp["boxes"]:
            p.set(facecolor="#dbe0ee", edgecolor="#4a5560")
        ax.set_xticks(range(1, len(ABL_ALGOS) + 1))
        ax.set_xticklabels(ABL_ALGOS, rotation=28, ha="right", fontsize=9)
        ax.set_ylabel("BestFit (full objective, lower is better)")
        ax.set_title(f"{m} — ablation (5 algorithms × {EXPECTED_RUNS} runs)")
        ax.grid(True, alpha=0.35)
        fig.tight_layout()
        base = FIGS / f"boxplot_{m}_abl5"
        _save_fig_png_svg(fig, base)
        plt.close(fig)
        print("Wrote", base.with_suffix(".png"), "+", base.with_suffix(".svg"))


def _save_fig_png_svg(fig, base_path: Path) -> None:
    """High-DPI raster + vector SVG (publication). base_path without suffix."""
    png = base_path.with_suffix(".png")
    svg = base_path.with_suffix(".svg")
    fig.savefig(png, dpi=300, bbox_inches="tight", facecolor="white")
    try:
        fig.savefig(svg, format="svg", bbox_inches="tight", facecolor="white", metadata={"Creator": "sfollm export_ablation_result.py"})
    except TypeError:
        fig.savefig(svg, format="svg", bbox_inches="tight", facecolor="white")


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    TABLES.mkdir(parents=True, exist_ok=True)
    FIGS.mkdir(parents=True, exist_ok=True)
    CONV.mkdir(parents=True, exist_ok=True)

    rows = merge_records()
    write_merged_records(rows)

    write_table2()
    flong = build_fitness_long(rows)
    summary = build_summary_ranks(flong)
    write_fitness_tables(flong, summary)
    plot_boxplots(rows)

    logp = OUT / "generation_log.txt"
    logp.write_text(
        "export_ablation_result.py\n"
        f"Merged rows: {len(rows)}\n"
        "Figures: boxplots -> figures/boxplots/*.png (300 dpi) + *.svg (vector)\n"
        "Convergence: requires MAT curve data.\n"
        "  Python: scripts/plot_ablation_convergence.py (PNG+SVG)\n"
        "  Or: pip install mat73 && python scripts/plot_ablation_convergence.py\n",
        encoding="utf-8",
    )
    print("Wrote", logp)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
