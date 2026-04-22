"""
Export one CSV: results tables + default_config experiment params + per-map metadata.
30 algorithms from per_map_all_algorithms_long.csv + EEFOLLM-PARETO from eefo_llm_pareto_records.csv.
"""
from __future__ import annotations

import csv
import statistics as st
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LONG = ROOT / "results/tables/per_map_all_algorithms_long.csv"
PARETO = ROOT / "results/eefo_llm_pareto/eefo_llm_pareto_records.csv"
OUT = ROOT / "results/tables/eefollm_comparison_zoo30_maps5_full_config.csv"

ZOO30 = [
    "EEFOLLM",
    "SFO",
    "PSO",
    "GWO",
    "HO",
    "EEFO",
    "SBOA",
    "ARO",
    "DE",
    "WOA",
    "ABC",
    "SSA",
    "FA",
    "BA",
    "CS",
    "GA",
    "TLBO",
    "SCA",
    "HHO",
    "MFO",
    "GSA",
    "MVO",
    "AOA",
    "JAYA",
    "WCA",
    "SMA",
    "MPA",
    "EO",
    "TSA",
    "GTO",
]

MAP_META = {
    "Map1": {"MapGridN": 40, "MapObstacleDensity": 0.08},
    "Map2": {"MapGridN": 40, "MapObstacleDensity": 0.13},
    "Map3": {"MapGridN": 40, "MapObstacleDensity": 0.18},
    "Map4": {"MapGridN": 70, "MapObstacleDensity": 0.08},
    "Map5": {"MapGridN": 70, "MapObstacleDensity": 0.10},
}

# default_config.m snapshot (keep in sync manually or regenerate if config drifts)
CFG = {
    "ProjectName": "EEFOLLM-PathPlanning",
    "BaseSeed": 20260417,
    "ExpPopulation": 30,
    "ExpIterations": 100,
    "RunsPerMap": 20,
    "PathDefaultK": 5,
    "PathSampleStep": 0.5,
    "PathPostSmooth": False,
    "StaticWeight_wL": 0.35,
    "StaticWeight_wC": 0.35,
    "StaticWeight_wS": 0.18,
    "StaticWeight_wT": 0.12,
    "StageSplit_early_end": 0.30,
    "StageSplit_late_start": 0.70,
    "Penalty_collision_hard": 1e4,
    "Penalty_obstacle_proximity": 10,
    "Penalty_min_obstacle_dist": 2.0,
    "Penalty_sharp_turn_threshold_deg": 100,
    "Penalty_turn_scale": 2.0,
    "Pareto_eta_c": 15,
    "Pareto_eta_m": 20,
    "OAW_enable_default": False,
}


def pareto_rows_per_map() -> dict[str, dict]:
    rows: list[dict] = []
    if not PARETO.is_file():
        return {}
    with PARETO.open(encoding="utf-8-sig", newline="") as f:
        for r in csv.DictReader(f):
            rows.append(r)
    by: dict[str, list[dict]] = {}
    for r in rows:
        by.setdefault(r["Map"], []).append(r)
    out = {}
    for m, g in by.items():
        bf = [float(x["BestFit"]) for x in g]
        cf = [int(x["CollisionFree"]) for x in g]
        suc = [int(x["Success"]) for x in g]
        out[m] = {
            "Runs": len(g),
            "MeanBestFit": st.mean(bf),
            "MedianBestFit": st.median(bf),
            "StdBestFit": st.pstdev(bf) if len(bf) > 1 else 0.0,
            "MeanCollisionFreeRate": st.mean(cf),
            "MeanSuccessRate": st.mean(suc),
        }
    return out


def algo_order_with_pareto() -> list[str]:
    o: list[str] = []
    for a in ZOO30:
        o.append(a)
        if a == "EEFOLLM":
            o.append("EEFOLLM-PARETO")
    return o


def main() -> None:
    long_rows: list[dict] = []
    with LONG.open(encoding="utf-8-sig", newline="") as f:
        long_rows = list(csv.DictReader(f))

    key = lambda r: (r["Map"], r["Algorithm"])
    db = {key(r): r for r in long_rows}

    pareto_stats = pareto_rows_per_map()
    order = algo_order_with_pareto()
    maps = [f"Map{i}" for i in range(1, 6)]

    fieldnames = [
        "Map",
        "MapGridN",
        "MapObstacleDensity",
        "Algorithm",
        "AlgorithmIndex",
        "Runs",
        "MeanBestFit",
        "MedianBestFit",
        "StdBestFit",
        "MeanCollisionFreeRate",
        "MeanSuccessRate",
        "ProjectName",
        "BaseSeed",
        "ExpPopulation",
        "ExpIterations",
        "RunsPerMap",
        "PathDefaultK",
        "PathSampleStep",
        "PathPostSmooth",
        "StaticWeight_wL",
        "StaticWeight_wC",
        "StaticWeight_wS",
        "StaticWeight_wT",
        "StageSplit_early_end",
        "StageSplit_late_start",
        "Penalty_collision_hard",
        "Penalty_obstacle_proximity",
        "Penalty_min_obstacle_dist",
        "Penalty_sharp_turn_threshold_deg",
        "Penalty_turn_scale",
        "Pareto_eta_c",
        "Pareto_eta_m",
        "OAW_enable_default",
        "WeightingMode",
        "DataSourceCSV",
    ]

    out_rows: list[dict] = []
    for mi, m in enumerate(maps):
        meta = MAP_META[m]
        for ai, algo in enumerate(order):
            if algo == "EEFOLLM-PARETO":
                if m not in pareto_stats:
                    continue
                p = pareto_stats[m]
                row = {
                    "Map": m,
                    "Algorithm": algo,
                    "Runs": p["Runs"],
                    "MeanBestFit": p["MeanBestFit"],
                    "MedianBestFit": p["MedianBestFit"],
                    "StdBestFit": p["StdBestFit"],
                    "MeanCollisionFreeRate": p["MeanCollisionFreeRate"],
                    "MeanSuccessRate": p["MeanSuccessRate"],
                    "WeightingMode": "LLM stage weights; NSGA-II multi-objective (L,C,S,T); scalarize for best report",
                    "DataSourceCSV": str(PARETO.relative_to(ROOT)).replace("\\", "/"),
                }
            else:
                k = (m, algo)
                if k not in db:
                    raise KeyError(f"missing row for {k}")
                r = db[k]
                row = {
                    "Map": m,
                    "Algorithm": algo,
                    "Runs": r["Runs"],
                    "MeanBestFit": r["MeanBestFit"],
                    "MedianBestFit": r["MedianBestFit"],
                    "StdBestFit": r["StdBestFit"],
                    "MeanCollisionFreeRate": r["MeanCollisionFreeRate"],
                    "MeanSuccessRate": r["MeanSuccessRate"],
                    "WeightingMode": (
                        "LLM validated stage weights (early/mid/late)"
                        if algo == "EEFOLLM"
                        else "Static cfg.weights.default for fitness scalar"
                    ),
                    "DataSourceCSV": str(LONG.relative_to(ROOT)).replace("\\", "/"),
                }

            row["MapGridN"] = meta["MapGridN"]
            row["MapObstacleDensity"] = meta["MapObstacleDensity"]
            row["AlgorithmIndex"] = ai + 1
            row["ProjectName"] = CFG["ProjectName"]
            row["BaseSeed"] = CFG["BaseSeed"]
            row["ExpPopulation"] = CFG["ExpPopulation"]
            row["ExpIterations"] = CFG["ExpIterations"]
            row["RunsPerMap"] = CFG["RunsPerMap"]
            row["PathDefaultK"] = CFG["PathDefaultK"]
            row["PathSampleStep"] = CFG["PathSampleStep"]
            row["PathPostSmooth"] = CFG["PathPostSmooth"]
            row["StaticWeight_wL"] = CFG["StaticWeight_wL"]
            row["StaticWeight_wC"] = CFG["StaticWeight_wC"]
            row["StaticWeight_wS"] = CFG["StaticWeight_wS"]
            row["StaticWeight_wT"] = CFG["StaticWeight_wT"]
            row["StageSplit_early_end"] = CFG["StageSplit_early_end"]
            row["StageSplit_late_start"] = CFG["StageSplit_late_start"]
            row["Penalty_collision_hard"] = CFG["Penalty_collision_hard"]
            row["Penalty_obstacle_proximity"] = CFG["Penalty_obstacle_proximity"]
            row["Penalty_min_obstacle_dist"] = CFG["Penalty_min_obstacle_dist"]
            row["Penalty_sharp_turn_threshold_deg"] = CFG["Penalty_sharp_turn_threshold_deg"]
            row["Penalty_turn_scale"] = CFG["Penalty_turn_scale"]
            row["Pareto_eta_c"] = CFG["Pareto_eta_c"]
            row["Pareto_eta_m"] = CFG["Pareto_eta_m"]
            row["OAW_enable_default"] = CFG["OAW_enable_default"]
            out_rows.append(row)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        w.writeheader()
        for row in out_rows:
            w.writerow(row)

    print(f"Wrote {len(out_rows)} rows to {OUT}")


if __name__ == "__main__":
    main()
