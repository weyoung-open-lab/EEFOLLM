# EEFOLLM: LLM-Guided Path Planning on Grid Maps

**EEFOLLM** uses **EEFO** (electric eel foraging–style) search and **LLM-generated stage weights** (early / mid / late) for a four-term path fitness. This repository contains the MATLAB and Python code for the benchmarks, plus fixed grid maps. **Qwen2.5-3B-Instruct** weights are **not** included (download separately; see [LLM: optional download](#llm-optional-download-qwen)).

This project is released under the [MIT License](LICENSE). The Qwen model, PyTorch, and other dependencies have their own licenses.

---

## Contents

- [Cloning and what is in the repo](#cloning-and-what-is-in-the-repo)
- [Environment](#environment)
- [LLM: optional download (Qwen)](#llm-optional-download-qwen)
- [Quick start (MATLAB)](#quick-start-matlab)
- [EEFOLLM weight pipeline (overview)](#eefollm-weight-pipeline-overview)
- [Entry points](#entry-points)
- [Reproducibility and caches](#reproducibility-and-caches)
- [Layout](#layout)
- [Dependencies](#dependencies)
- [Release zip](#release-zip)
- [Citing](#citing)

---

## Cloning and what is in the repo

| Included | Excluded (by design) |
|----------|----------------------|
| MATLAB sources, maps, `llm/` scripts and prompts (no model binaries) | `llm/models/*` except [`llm/models/README.txt`](llm/models/README.txt) |
| Python weight scripts | `.venv/`, `.hf_cache/` |
| `requirements-llm.txt`, `requirements-map-export.txt` | Qwen weight files, large `results/` / `logs/` (regenerate locally) |

---

## Environment

1. **MATLAB** — `cd` to the repository root before running entry scripts.  
2. **Python (for real Qwen)** — `python -m venv .venv` in the project root. If `.\.venv\Scripts\python.exe` exists, [`config/default_config.m`](config/default_config.m) uses it. Install with `pip install -r requirements-llm.txt` and a **PyTorch** build for your [CPU/CUDA](https://pytorch.org/get-started/locally/).

**Windows helper:** [`setup_venv_e.ps1`](setup_venv_e.ps1) installs a CUDA 12.4 PyTorch build (edit if you need CPU-only).

`generate_qwen_weights.py` sets `HF_HOME` to a project-local `.hf_cache` by default.

---

## LLM: optional download (Qwen)

- **Model:** [`Qwen/Qwen2.5-3B-Instruct`](https://huggingface.co/Qwen/Qwen2.5-3B-Instruct)  
- **Optional mirror:** [ModelScope](https://www.modelscope.cn/models/qwen/Qwen2.5-3B-Instruct)  
- **Default local path in code:** `llm/models/Qwen2.5-3B-Instruct-full` — see `cfg.llm.local_model_dir` in `config/default_config.m`

From the repository root:

```text
python -m pip install -U huggingface_hub hf_xet
python llm\download_qwen_model.py --repo Qwen/Qwen2.5-3B-Instruct --out llm\models\Qwen2.5-3B-Instruct-full
```

**No download:** set `cfg.use_real_qwen = false` in `config/default_config.m` to use the deterministic mock generator in `llm/mock_llm_weights.py`.

**Note:** per-weight bounds are applied in **Python** (`clip_norm` in `llm/generate_qwen_weights.py`); MATLAB `validate_llm_weights` checks structure, nonnegativity, and per-stage normalization.

---

## Quick start (MATLAB)

```matlab
cd <repository_root>
main_run_all
```

With the default `cfg.pipeline.run_optional_studies = false` in `config/default_config.m`, this runs **`main_run_eefollm_quick`** and writes under `results/eefollm_benchmark/`.

**Full 10-algorithm batch (example):**

```matlab
main_run_global_experiments_batch(1)
```

**Force a full recompute** if a cached `global_results.mat` would be loaded:

```matlab
main_run_global_experiments_batch(1, true)
```

Set `cfg.pipeline.run_optional_studies = true` in `config/default_config.m` to also run the optional branch in `main_run_all` (map overview, method diagrams, main batch, ablation, parameter study, seed log).

---

## EEFOLLM weight pipeline (overview)

1. Map features → `extract_map_features.m` → JSON.  
2. `llm/generate_qwen_weights.py` → JSON with `early` / `mid` / `late` and `wL,wC,wS,wT`.  
3. `fitness/validate_llm_weights` → validate; on failure, handcrafted `cfg.weights.handcrafted_stage_weights`.  
4. `run_llm_eefo` / `run_eefo` select the stage from iteration index (default splits in `cfg.stage_split`).

---

## Entry points

| Script | Role |
|--------|------|
| `main_run_all.m` | One-click: default = `main_run_eefollm_quick`; optional extended pipeline if `run_optional_studies` is true. |
| `main_run_eefollm_quick.m` | EEFOLLM only → `results/eefollm_benchmark/`. |
| `main_run_global_experiments_batch(1–3)` | 5 maps × 10 algorithms; batch 1 includes EEFOLLM + `generate_llm_weights`. |
| `main_run_paper_benchmark10_full.m` | Full 10-benchmark run consistent with the paper table setup. |
| `main_run_global_experiments.m` | 5×30×N full zoo when needed. |
| `main_regenerate_all_maps.m` / `main_regenerate_maps45.m` | Rebuild map `.mat` after changing `default_config.m`. |
| `main_run_ablation*.m` / `main_run_param_study.m` | Ablation and parameter study. |
| `main_run_zoo_screening.m` | 30-baseline screening under one config. |
| `plotting/export_paper_benchmark10_figures.m` | Figures for the 9+1 paper slice (needs `results/tables/per_map_all_algorithms_long.csv` first). |
| `generate_main_tables.m` | Tables from saved results. |

---

## Reproducibility and caches

- Global seed: `cfg.base_seed` in `config/default_config.m`.  
- `results/seeds_log.csv` may be written by pipelines that implement it.  
- If `results/global_experiments_batch1/mat/global_results.mat` exists, batch drivers may **reload** it unless you pass the **force** flag or set `cfg.rerun_global_experiments = true`.

---

## Layout

- `config/` — parameters and algorithm lists.  
- `algorithms/` — SFO, EEFO, EEFOLLM, baselines.  
- `fitness/` — metrics and `validate_llm_weights`.  
- `mapscripts/` — map generation and features.  
- `llm/` — Python bridge and prompts (no weight shards in Git).  
- `utils/`, `analysis/`, `plotting/`, `scripts/` — helpers and post-processing.  

---

## Dependencies

| Component | Notes |
|-----------|--------|
| MATLAB | Base install; Image Processing Toolbox optional. |
| Python | For real Qwen: see `requirements-llm.txt`. |
| Map export | `requirements-map-export.txt` for `scripts/export_map_figure.py`. |

---

## Release zip

[`scripts/package_release.ps1`](scripts/package_release.ps1) builds a source-oriented archive (no model weights, no vendored venv; see also [`DISTRIBUTION.txt`](DISTRIBUTION.txt) and [`llm/models/README.txt`](llm/models/README.txt)).

---

## Citing

Cite the Qwen2.5 model card, any baselines you compare, and your own paper when you publish work that uses this code.

`run_sfo.m` is a **paper-inspired** implementation (it favors clarity and fair benchmarking over a byte-for-byte match to one source). With **`run_optional_studies` true**, `main_run_all` runs map overview, diagrams, `main_run_main_experiments`, ablation, and parameter study. Smoke/tune-only drivers are not part of the public file set.
