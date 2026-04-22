#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从 batch1 与消融实验的 global_results.mat 绘制五算法收敛曲线（与 main_plot_ablation_convergence.m 一致）。

MATLAB R2006b+ 默认保存多为 v7.3(HDF5)，需: pip install mat73
若未安装 mat73，请用 MATLAB 运行: main_plot_ablation_convergence

用法: python scripts/plot_ablation_convergence.py
"""

from __future__ import annotations

from typing import Optional

import re
import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "results" / "ablation_result" / "figures" / "convergence"
MAPS = ["Map1", "Map2", "Map3", "Map4", "Map5"]
ALGOS = ["EEFO", "EEFOLLM", "EEFOLLM-NJ", "EEFOLLM-NS", "EEFOLLM-PARTIAL"]


def _load_mat(path: Path):
    if not path.is_file():
        return None
    try:
        import mat73  # type: ignore

        return mat73.loadmat(str(path))
    except ImportError:
        pass
    try:
        from scipy.io import loadmat

        return loadmat(str(path), struct_as_record=True, squeeze_me=True)
    except Exception as e:
        print(f"Cannot load {path}: {e}", file=sys.stderr)
        return None


def _valid_field_name(algo: str) -> str:
    s = re.sub(r"\W", "_", algo)
    if s and not s[0].isalpha():
        s = "x" + s
    return s


def _pick_curve_block(curves_map: dict, map_name: str) -> Optional[dict]:
    if curves_map is None:
        return None
    cm = curves_map.get(map_name)
    if cm is None:
        return None
    if not isinstance(cm, dict):
        return None
    return cm


def _get_algo_matrix(cm: dict, algo: str) -> Optional[np.ndarray]:
    """Match MATLAB makeValidName and common aliases."""
    if cm is None:
        return None
    try_names = [
        _valid_field_name(algo),
        algo.replace("-", "_"),
        algo,
        "EEFOLLM" if algo == "EEFOLLM" else None,
        "LLM_EEFO",
        "xLLMEEFO",
    ]
    for name in try_names:
        if name is None:
            continue
        if name in cm:
            return np.asarray(cm[name], dtype=float)
    for k, v in cm.items():
        if not isinstance(v, np.ndarray):
            continue
        ks = re.sub(r"[^a-zA-Z0-9]", "", str(k)).upper()
        if algo.upper().replace("-", "") == ks.replace("_", ""):
            return np.asarray(v, dtype=float)
        if algo == "EEFOLLM" and "LLM" in ks and "EEFO" in ks:
            return np.asarray(v, dtype=float)
    return None


def mean_best_so_far(M: np.ndarray) -> np.ndarray:
    if M is None or M.size == 0:
        return np.array([])
    n, t = M.shape
    acc = np.full((n, t), np.nan)
    for r in range(n):
        best = np.inf
        for j in range(t):
            if np.isfinite(M[r, j]):
                best = min(best, M[r, j])
            acc[r, j] = best if np.isfinite(best) else np.nan
    return np.nanmean(acc, axis=0)


def merge(batch: dict, ablation: dict) -> dict:
    o1 = batch.get("out") or batch.get("OUT")
    o2 = ablation.get("out") or ablation.get("OUT")
    if isinstance(o1, np.ndarray) and o1.dtype == object:
        o1 = o1.item() if o1.size else None
    if isinstance(o2, np.ndarray) and o2.dtype == object:
        o2 = o2.item() if o2.size else None
    c1 = o1.get("curves") if isinstance(o1, dict) else getattr(o1, "curves", None)
    c2 = o2.get("curves") if isinstance(o2, dict) else getattr(o2, "curves", None)
    if isinstance(c1, np.ndarray) and c1.dtype == object:
        c1 = c1.item()
    if isinstance(c2, np.ndarray) and c2.dtype == object:
        c2 = c2.item()
    if not isinstance(c1, dict) or not isinstance(c2, dict):
        return {}
    out = {}
    for m in MAPS:
        cm1 = _pick_curve_block(c1, m)
        cm2 = _pick_curve_block(c2, m)
        if cm1 is None or cm2 is None:
            continue
        block = {}
        for algo in ALGOS:
            if algo in ("EEFO", "EEFOLLM"):
                M = _get_algo_matrix(cm1, algo)
            else:
                M = _get_algo_matrix(cm2, algo)
            if M is not None and M.size:
                block[algo] = M
        if block:
            out[m] = block
    return out


def plot_figs(merged: dict, max_iter: int = 100):
    OUT.mkdir(parents=True, exist_ok=True)
    colors = [
        (0.00, 0.45, 0.74),
        (0.85, 0.33, 0.10),
        (0.93, 0.69, 0.13),
        (0.49, 0.18, 0.56),
        (0.85, 0.10, 0.15),
    ]
    lines = ["-", "-", "--", "-.", "-"]

    fig, axes = plt.subplots(2, 3, figsize=(12, 7.2), dpi=120)
    axes = list(axes.flatten())
    for k, m in enumerate(MAPS):
        ax = axes[k]
        blk = merged.get(m, {})
        if not blk:
            ax.text(0.5, 0.5, f"No curve data: {m}", ha="center", va="center", transform=ax.transAxes)
            ax.set_title(m)
            continue
        for ai, algo in enumerate(ALGOS):
            if algo not in blk:
                continue
            y = mean_best_so_far(blk[algo])
            it = np.arange(1, len(y) + 1)
            lw = 2.4 if algo == "EEFOLLM" else 1.4
            ax.plot(it, y, color=colors[ai], linestyle=lines[ai], linewidth=lw, label=algo)
        ax.set_xlim(1, max_iter)
        ax.grid(True, alpha=0.35)
        ax.set_title(m)
        ax.set_xlabel("Iteration")
        ax.set_ylabel("Fitness (mean best-so-far)")
    axes[5].set_visible(False)
    fig.suptitle("Convergence (ablation: 5 algorithms)", fontsize=11)
    fig.tight_layout()
    base_all = OUT / "convergence_all_maps_abl5"
    _save_fig_png_svg(fig, base_all)
    plt.close(fig)
    print("Wrote", base_all.with_suffix(".png"), "+", base_all.with_suffix(".svg"))

    for m in MAPS:
        blk = merged.get(m, {})
        if not blk:
            continue
        fig, ax = plt.subplots(figsize=(6, 4.2), dpi=120)
        for ai, algo in enumerate(ALGOS):
            if algo not in blk:
                continue
            y = mean_best_so_far(blk[algo])
            it = np.arange(1, len(y) + 1)
            lw = 2.4 if algo == "EEFOLLM" else 1.4
            ax.plot(it, y, color=colors[ai], linestyle=lines[ai], linewidth=lw, label=algo)
        ax.set_xlim(1, max_iter)
        ax.legend(loc="best", fontsize=7)
        ax.grid(True, alpha=0.35)
        ax.set_title(m)
        ax.set_xlabel("Iteration")
        ax.set_ylabel("Fitness (mean best-so-far)")
        fig.tight_layout()
        base_m = OUT / f"convergence_{m}_abl5"
        _save_fig_png_svg(fig, base_m)
        plt.close(fig)
        print("Wrote", base_m.with_suffix(".png"), "+", base_m.with_suffix(".svg"))


def _save_fig_png_svg(fig, base_path: Path) -> None:
    """300 DPI PNG + vector SVG for print."""
    png = base_path.with_suffix(".png")
    svg = base_path.with_suffix(".svg")
    fig.savefig(png, dpi=300, bbox_inches="tight", facecolor="white")
    try:
        fig.savefig(
            svg,
            format="svg",
            bbox_inches="tight",
            facecolor="white",
            metadata={"Creator": "sfollm plot_ablation_convergence.py"},
        )
    except TypeError:
        fig.savefig(svg, format="svg", bbox_inches="tight", facecolor="white")


def write_readme_missing():
    OUT.mkdir(parents=True, exist_ok=True)
    txt = """Convergence figures are NOT in this folder yet.

Why:
  1) Curve data lives in MATLAB binary files:
       results/global_experiments_batch1/mat/global_results.mat
       results/ablation_eefollm_ablated_only/mat/ablation_eefollm_ablated_only.mat
  2) Either run MATLAB on the project root:
       main_plot_ablation_convergence
     Or install mat73 and run:
       pip install mat73
       python scripts/plot_ablation_convergence.py

Boxplots do not need these MAT files; only convergence curves do.
"""
    (OUT / "README_convergence.txt").write_text(txt, encoding="utf-8")


def main() -> int:
    batch_p = ROOT / "results" / "global_experiments_batch1" / "mat" / "global_results.mat"
    abl_p = (
        ROOT / "results" / "ablation_eefollm_ablated_only" / "mat" / "ablation_eefollm_ablated_only.mat"
    )
    if not batch_p.is_file() or not abl_p.is_file():
        write_readme_missing()
        print(
            "Missing MAT files. Wrote", OUT / "README_convergence.txt",
            file=sys.stderr,
        )
        return 1
    b = _load_mat(batch_p)
    a = _load_mat(abl_p)
    if b is None or a is None:
        write_readme_missing()
        return 1
    merged = merge(b, a)
    if not merged:
        print("Merged curves empty — check MAT structure or use MATLAB main_plot_ablation_convergence.", file=sys.stderr)
        write_readme_missing()
        return 1
    plot_figs(merged)
    (OUT / "README_convergence.txt").write_text(
        "Generated by scripts/plot_ablation_convergence.py\n", encoding="utf-8"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
