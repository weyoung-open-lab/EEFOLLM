"""Plot summary charts from results/sfo_smoke.csv (no pandas)."""
import csv
from pathlib import Path

import matplotlib.pyplot as plt


def main():
    root = Path(__file__).resolve().parents[1]
    csv_path = root / "results" / "sfo_smoke.csv"
    out_path = root / "figures" / "sfo_smoke_summary.png"

    maps = ["Map1", "Map2", "Map3", "Map4", "Map5"]
    agg = {m: {"bf": [], "rt": [], "cf": [], "sm": []} for m in maps}

    with csv_path.open(newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            m = row["Map"]
            if m not in agg:
                continue
            agg[m]["bf"].append(float(row["BestFit"]))
            agg[m]["rt"].append(float(row["Runtime"]))
            agg[m]["cf"].append(float(row["CollisionFree"]))
            s = row.get("Smoothness", "")
            if s not in ("", "NaN"):
                try:
                    agg[m]["sm"].append(float(s))
                except ValueError:
                    pass

    def mean(xs):
        return sum(xs) / len(xs) if xs else float("nan")

    mbf = [mean(agg[m]["bf"]) for m in maps]
    mrt = [mean(agg[m]["rt"]) for m in maps]
    mcf = [mean(agg[m]["cf"]) for m in maps]
    msm = [mean(agg[m]["sm"]) for m in maps]

    fig, ax = plt.subplots(2, 2, figsize=(10, 8))
    ax[0, 0].bar(maps, mbf, color="#4472C4")
    ax[0, 0].set_title("Mean BestFit (lower is better)")
    ax[0, 0].tick_params(axis="x", rotation=45)

    ax[0, 1].bar(maps, mrt, color="#ED7D31")
    ax[0, 1].set_title("Mean Runtime (s)")
    ax[0, 1].tick_params(axis="x", rotation=45)

    ax[1, 0].bar(maps, mcf, color="#70AD47")
    ax[1, 0].set_ylim(0, 1.05)
    ax[1, 0].set_title("Collision-free rate")
    ax[1, 0].tick_params(axis="x", rotation=45)

    ax[1, 1].bar(maps, msm, color="#FFC000")
    ax[1, 1].set_title("Mean Smoothness (valid runs only)")
    ax[1, 1].tick_params(axis="x", rotation=45)

    plt.tight_layout()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=150)
    plt.close(fig)
    print(f"saved: {out_path}")


if __name__ == "__main__":
    main()
