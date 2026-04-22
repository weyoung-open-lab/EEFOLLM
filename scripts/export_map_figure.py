#!/usr/bin/env python3
"""
Export benchmark map figure from maps/Map*.mat without MATLAB.
Matches plot_paths_all_maps map layer: free=white, obstacle=purple tint; optional start/goal markers.

Usage (from project root):
  python scripts/export_map_figure.py --map Map3
  python scripts/export_map_figure.py --map Map3 --no-markers
  python scripts/export_map_figure.py --map Map3 --out results/path_maps/map_only_Map3.png

依赖：numpy、scipy、matplotlib（若缺失会自动用当前解释器 pip 安装一次）。
也可手动：python -m pip install -r requirements-map-export.txt
"""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


def _ensure_deps() -> None:
    try:
        import numpy  # noqa: F401
        import scipy.io  # noqa: F401
        import matplotlib.pyplot  # noqa: F401
    except ImportError:
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "-q", "numpy", "scipy", "matplotlib"],
        )


_ensure_deps()

import matplotlib.colors as mcolors
import matplotlib.pyplot as plt
import numpy as np
from scipy.io import loadmat


def load_map_data(mat_path: Path):
    d = loadmat(str(mat_path), struct_as_record=False, squeeze_me=True)
    if "map_data" not in d:
        raise SystemExit(f"No map_data in {mat_path}")
    m = d["map_data"]
    grid = np.asarray(m.grid, dtype=float)
    start = np.asarray(m.start).reshape(-1)
    goal = np.asarray(m.goal).reshape(-1)
    name = str(m.name) if hasattr(m, "name") else mat_path.stem
    return name, grid, start, goal


def export_map(
    grid: np.ndarray,
    start: np.ndarray,
    goal: np.ndarray,
    out_path: Path,
    *,
    show_markers: bool,
    dpi: int = 300,
):
    out_path.parent.mkdir(parents=True, exist_ok=True)
    # Same two-color scheme as plot_paths_on_axes (MATLAB colormap row)
    colors = np.array([[1.0, 1.0, 1.0], [0.78, 0.66, 0.88]])
    cmap = mcolors.ListedColormap(colors)

    # MATLAB imagesc + YDir normal：首行在底部 → origin='lower'；extent 与轨迹图 0..N 坐标一致。
    fig, ax = plt.subplots(figsize=(6, 6))
    h, w = grid.shape
    ax.imshow(
        grid,
        cmap=cmap,
        interpolation="nearest",
        origin="lower",
        vmin=0,
        vmax=1,
        extent=(0, w, 0, h),
    )
    ax.set_aspect("equal")
    ax.set_xlabel("X")
    ax.set_ylabel("Y")
    ax.grid(True, which="both", alpha=0.25)
    ax.set_box_aspect(1)
    ax.set_xlim(0, w)
    ax.set_ylim(0, h)

    # 与 MATLAB plot_paths_on_axes 中 plot(start(1),start(2)) 一致：1-based 列/行，轴为 0..N（Map3 为 (2,2) 与 (38,38)）
    if show_markers and start.size >= 2 and goal.size >= 2:
        sx, sy = float(start[0]), float(start[1])
        gx, gy = float(goal[0]), float(goal[1])
        ax.plot(
            sx,
            sy,
            "o",
            ms=9,
            mew=2.2,
            mfc=(1.0, 0.25, 0.2),
            mec=(0.75, 0.0, 0.1),
            clip_on=False,
        )
        ax.plot(
            gx,
            gy,
            "s",
            ms=9,
            mew=2.2,
            mfc=(1.0, 0.85, 0.2),
            mec=(0.65, 0.0, 0.15),
            clip_on=False,
        )

    fig.tight_layout()
    fig.savefig(out_path, dpi=dpi, bbox_inches="tight")
    svg_path = out_path.with_suffix(".svg")
    try:
        fig.savefig(svg_path, bbox_inches="tight")
    except Exception:
        svg_path = None
    plt.close(fig)
    print(f"Wrote {out_path}")
    if svg_path and svg_path.is_file():
        print(f"Wrote {svg_path}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", default="Map3", help="Map name, e.g. Map3 (loads maps/Map3.mat)")
    ap.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
        help="Project root (parent of maps/)",
    )
    ap.add_argument(
        "--out",
        type=Path,
        default=None,
        help="Output PNG path (default: results/path_maps/map_only_<Map>.png)",
    )
    ap.add_argument("--no-markers", action="store_true", help="Obstacle grid only, no start/goal")
    ap.add_argument("--dpi", type=int, default=300)
    args = ap.parse_args()

    mat_path = args.root / "maps" / f"{args.map}.mat"
    if not mat_path.is_file():
        raise SystemExit(f"Missing {mat_path}")

    name, grid, start, goal = load_map_data(mat_path)
    out = args.out
    if out is None:
        out = args.root / "results" / "path_maps" / f"map_only_{name}.png"

    export_map(grid, start, goal, out, show_markers=not args.no_markers, dpi=args.dpi)


if __name__ == "__main__":
    main()
