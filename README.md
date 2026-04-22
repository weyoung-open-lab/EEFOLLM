# EEFOLLM: LLM-Guided Path Planning on Grid Maps

**EEFOLLM** couples **EEFO** (electric eel foraging–style) search with **LLM-generated stage weights** (early / mid / late) for a four-term path fitness. This repository is the full MATLAB + Python **research code** and experiment drivers for grid-based path planning benchmarks.

- **In this repo:** algorithm sources, map pipeline, feature extraction, LLM **weight scripts** (no model binaries), baselines, analysis scripts, and configuration.
- **Not in this repo:** **Qwen2.5-3B-Instruct** weight files (multi-GB). Download separately; paths and commands are documented below and in [`llm/models/README.txt`](llm/models/README.txt).

**License:** this project is released under the [MIT License](LICENSE). Third-party components (the **Qwen** model, **PyTorch**, MATLAB toolboxes, etc.) remain under their respective licenses; we do not redistribute Qwen weights in Git.

**Copyright:** the `LICENSE` file contains a copyright line you should replace with your **organization or legal entity** name before publishing (see [License and copyright](#license-and-copyright)).

---

## Table of contents

- [Cloning and what you get](#cloning-and-what-you-get)
- [Environment](#environment)
- [LLM: optional download (Qwen)](#llm-optional-download-qwen)
- [Quick start (MATLAB)](#quick-start-matlab)
- [EEFOLLM weight pipeline (concept)](#eefollm-weight-pipeline-concept)
- [Main experiment entry points](#main-experiment-entry-points)
- [Reproducibility and caches](#reproducibility-and-caches)
- [Project layout](#project-layout)
- [Dependencies](#dependencies)
- [Packaging a release zip](#packaging-a-release-zip)
- [Additional notes](#additional-notes)
- [License and copyright](#license-and-copyright)

---

## Cloning and what you get

| Included | Excluded (by design) |
|----------|----------------------|
| MATLAB sources (`algorithms/`, `fitness/`, `mapscripts/`, `utils/`, `config/`, `main_*.m`, …) | `llm/models/*` **weight shards** (only [`llm/models/README.txt`](llm/models/README.txt) is tracked) |
| Python: `llm/generate_qwen_weights.py`, `llm/mock_llm_weights.py`, `llm/download_qwen_model.py`, prompts, sample I/O | `.venv/`, `.hf_cache/`, local caches |
| Fixed benchmark maps under `maps/` | Large `results/`, `figures/`, `logs/` (not required to publish; you regenerate them) |
| `requirements-llm.txt`, `requirements-map-export.txt` | **Qwen** model files (user download) |

After clone, add **Python 3.9+** and either **(A)** local Qwen as below or **(B)** `cfg.use_real_qwen = false` for mock weights only.

---

## Environment

1. **MATLAB** — project root = this repository root; add the root to the path or `cd` there before running `main_*.m`.
2. **Python (optional, for EEFOLLM real LLM path)**  
   - Create a venv in the project root, e.g. `python -m venv .venv`  
   - `config/default_config.m` will use `.\.venv\Scripts\python.exe` (Windows) if it exists, else `python` on `PATH`.  
   - Install LLM stack: `pip install -r requirements-llm.txt` and **PyTorch** suitable for your CPU/CUDA (see [PyTorch install](https://pytorch.org/get-started/locally/)).

**Windows one-shot (PowerShell, from project root):** this repo includes [`setup_venv_e.ps1`](setup_venv_e.ps1) (installs a **CUDA 12.4** torch wheel; edit if you need CPU-only):

```powershell
powershell -ExecutionPolicy Bypass -File .\setup_venv_e.ps1
```

`generate_qwen_weights.py` sets `HF_HOME` / `HF_HUB_CACHE` to a project-local **`.hf_cache`** so Hugging Face cache does not fill the user home drive by default on Windows.

---

## LLM: optional download (Qwen)

**Model ID (Hub):** `Qwen/Qwen2.5-3B-Instruct`  
**Hugging Face page:** <https://huggingface.co/Qwen/Qwen2.5-3B-Instruct>  
**ModelScope (mirror, optional):** <https://www.modelscope.cn/models/qwen/Qwen2.5-3B-Instruct>

**Default local directory in code:** `llm/models/Qwen2.5-3B-Instruct-full`  
(`cfg.llm.local_model_dir` in [`config/default_config.m`](config/default_config.m))

**Download (resumable), from repository root:**

```text
python -m pip install -U huggingface_hub hf_xet
python llm\download_qwen_model.py --repo Qwen/Qwen2.5-3B-Instruct --out llm\models\Qwen2.5-3B-Instruct-full
```

**Completion check:** directory should contain (among others) `config.json`, `tokenizer.json`, `model.safetensors.index.json`, `model-00001-of-00002.safetensors`, `model-00002-of-00002.safetensors`.  
If download is incomplete, MATLAB+Python can still fall back to **mock** weights when `use_real_qwen` is true (see `generate_qwen_weights.py` auto path).

**Run without any large download:** in `config/default_config.m` set

```matlab
cfg.use_real_qwen = false;
```

so only `mock_llm_weights.py` is used (deterministic, map-feature–based stage weights).

**Where clipping happens:** per-weight **Python** `clip_norm` in `llm/generate_qwen_weights.py` (then MATLAB `validate_llm_weights` normalizes and validates structure).

---

## Quick start (MATLAB)

```matlab
cd <your_clone_root>
main_run_all
```

By default (`cfg.pipeline.run_optional_studies = false` in `config/default_config.m`), `main_run_all` runs `main_run_eefollm_quick` (EEFOLLM only) and writes under `results/eefollm_benchmark/`.

**First full 10-algorithm paper-style batch (example):**

```matlab
main_run_global_experiments_batch(1)
```

Set `cfg.pipeline.run_optional_studies = true` to pull in additional legacy one-click stages (map overview, SFO smoke, 8-baseline run, ablation, parameter study) if present in your tree.

**Force recompute** when a cached `global_results.mat` would otherwise be loaded:

```matlab
main_run_global_experiments_batch(1, true)   % second arg = force
```

or delete the cached mat, or set `cfg.rerun_global_experiments = true` in `config/default_config.m`.

---

## EEFOLLM weight pipeline (concept)

1. **Map features** → `extract_map_features.m` → JSON (see `config` paths).  
2. **Python** `generate_qwen_weights.py` → JSON with `early` / `mid` / `late` and `wL,wC,wS,wT`.  
3. **MATLAB** `validate_llm_weights` — structure, finite, nonnegative, **per-stage normalize to sum 1**; on failure, **handcrafted** `cfg.weights.handcrafted_stage_weights`.  
4. **Optimization** `run_llm_eefo` / `run_eefo` selects the stage from iteration progress (defaults: early ≤ 30% *T*, late > 70% *T*; see `get_stage_weights` and `cfg.stage_split`).

---

## Main experiment entry points

| Script | Role |
|--------|------|
| `main_run_all.m` | One-click; default: quick EEFOLLM. |
| `main_run_eefollm_quick.m` | EEFOLLM only → `results/eefollm_benchmark/`. |
| `main_run_global_experiments_batch(1)` (or 2, 3) | 5 maps × 10 algorithms × `runs_per_map`; batch 1 includes EEFOLLM + `generate_llm_weights`. |
| `main_run_paper_benchmark10_full.m` | Full 10-benchmark driver (as in paper config). |
| `main_run_global_experiments.m` | 5×30×N (large zoo) when you need the full 30-baseline set. |
| `main_regenerate_maps45.m` | Rebuild Map4/5 after changing complexity in `default_config.m`. |
| `generate_main_tables.m` / `analysis/*` | Tables and figures from saved results. |

---

## Reproducibility and caches

- Global seed: `cfg.base_seed` in `config/default_config.m`.  
- Per-run seeds: exported to `results/seeds_log.csv` (when the corresponding pipeline writes it).  
- Maps: deterministic under `maps/*.mat` once generated.  
- **Batch re-run note:** if `results/global_experiments_batch1/mat/global_results.mat` exists, some drivers load it unless you force a rerun (see above).

---

## Project layout

- `config/default_config.m` — central parameters and paths.  
- `algorithms/` — SFO, EEFO, EEFOLLM (`run_llm_eefo.m`), baselines, etc.  
- `fitness/` — path decoding, L/C/S/T fitness, `validate_llm_weights.m`.  
- `mapscripts/` — `generate_maps.m`, `extract_map_features.m`.  
- `llm/` — weight generation, **no** model weights in Git (see [`.gitignore`](.gitignore)).  
- `utils/` — `generate_llm_weights.m`, experiment batch helpers.  
- `analysis/`, `scripts/` — post-processing, plotting (Python + MATLAB).  
- `results/`, `figures/`, `logs/` — run outputs (optional to commit).  

---

## Dependencies

| Component | Need |
|-----------|------|
| MATLAB | Base; Image Processing Toolbox optional (distance transforms have a fallback). |
| Python | Optional; required for real Qwen: `transformers`, `torch`, `huggingface_hub`, etc. (`requirements-llm.txt`). |
| Map figure export (optional) | `requirements-map-export.txt` for `scripts/export_map_figure.py`. |

---

## Packaging a release zip

[`scripts/package_release.ps1`](scripts/package_release.ps1) builds a **source-only** zip: strips `llm/models` weights, `results`, `.venv`, large caches, etc. For notes on what is excluded, see [`DISTRIBUTION.txt`](DISTRIBUTION.txt) and [`llm/models/README.txt`](llm/models/README.txt).

---

## Additional notes

**Optional legacy drivers**

- `main_tune_llm_sfo_map45` — budget tuning for difficult maps; CSV under `results/tune_*.csv`; `parse_tune_log_to_csv` can recover rows from logs.  
- `main_run_zoo_screening` — 30-baseline screening.  
- `main_run_sfo_smoke` / `main_run_algorithm_smoke` — quick smoke tests.

**SFO implementation**

`run_sfo.m` is a **paper-inspired** implementation (fast swim, gather, dispersal, escape). It prioritizes clarity and fair benchmarking over a byte-for-byte match to a single reference.

**Citing**

If you use this code, cite your own publication and the **Qwen2.5** model card and any metaheuristic baselines you compare against, per their original papers.

---

## License and copyright

- **What MIT means:** the MIT License is a short, permissive open-source license. It allows others to use, copy, modify, and distribute your code, as long as they keep the copyright notice and the license text with any copy. It comes **without warranty**; liability sits with the user (see the all-caps paragraph in `LICENSE`).

- **How to add your organization name:** open [`LICENSE`](LICENSE) and replace the line  
  `Copyright (c) 2026 [Replace with your organization or legal entity name]`  
  with your official name, for example:  
  `Copyright (c) 2026 Example University`  
  or  
  `Copyright (c) 2026 Example Corp.`

  You only need **one** copyright line for the main entity that holds rights to this codebase; if multiple institutions contributed, your legal team may want multiple lines or a `NOTICE` file—follow your organization’s policy.

- **Other materials:** the Qwen model, PyTorch, and other dependencies are **not** covered by this project’s `LICENSE`; comply with their licenses when you use them.
