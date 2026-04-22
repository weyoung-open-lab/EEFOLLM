# EEFOLLM: LLM-Guided Path Planning on Grid Maps

EEFOLLM combines **EEFO**-style search with **LLM-generated stage weights** (early / mid / late) for a four-term path fitness. The **MATLAB** implementation lives under [`matlab/`](matlab/); Qwen2.5-3B weights are **not** in Git—see [LLM setup](#llm-optional). **Python** scripts remain in [`llm/`](llm/).

Released under the [MIT License](LICENSE). Qwen, PyTorch, and other third-party parts keep their own licenses.

---

## How to run the main experiment (5 maps × 20 runs × 10 algorithms)

Repetitions, population size, and iterations are in [`matlab/config/default_config.m`](matlab/config/default_config.m) (`cfg.exp.runs_per_map` default **20**, `cfg.exp.population`, `cfg.exp.iterations`). The 10 algorithms are the first ten entries in `cfg.exp.algorithms_zoo30` (including **EEFOLLM** and nine baselines).

1. **MATLAB** — set the *Current Folder* to the **repository root** (the folder that contains `matlab/`, `llm/`, and `maps/`).
2. **Path** — `addpath('matlab');` then call the single entry (or add `matlab` permanently with `Set Path`).
3. **Optional: no Qwen download** — in `default_config.m` set `cfg.use_real_qwen = false` to use the mock weight generator.
4. **Run**

```matlab
addpath('matlab');
run_experiment          % or run_experiment(true) to ignore cached mat and recompute
```

**Outputs (data and figures):**  
`results/global_experiments_batch1/` — `mat/global_results.mat`, `tables/*.csv`, `features/`, `weights/`, and logs. Figures are written to `figures/global_experiments_batch1/`. If `mat/global_results.mat` already exists, the script reloads it unless you pass `true` or set `cfg.rerun_global_experiments = true`.

---

## LLM (optional)

- **Model card:** [Qwen2.5-3B-Instruct](https://huggingface.co/Qwen/Qwen2.5-3B-Instruct) (optional mirror: [ModelScope](https://www.modelscope.cn/models/qwen/Qwen2.5-3B-Instruct))
- **Local directory** (see `cfg.llm.local_model_dir` in `default_config.m`):

```text
python -m pip install -U huggingface_hub hf_xet
python llm\download_qwen_model.py --repo Qwen/Qwen2.5-3B-Instruct --out llm\models\Qwen2.5-3B-Instruct-full
```

- **Python** — create `.venv` in the repo root; if `.\.venv\Scripts\python.exe` exists, `default_config` uses it. Install `pip install -r requirements-llm.txt` and a suitable **PyTorch** build. See [`setup_venv_e.ps1`](setup_venv_e.ps1) for a CUDA 12.4 example on Windows.
- Weights are clipped in **Python** (`llm/generate_qwen_weights.py`); MATLAB validates and renormalizes per stage.

---

## Layout (high level)

| Path | Content |
|------|---------|
| `matlab/` | All **`.m`** code: `run_experiment.m`, `run_global_experiments_batch1.m`, `config/`, `algorithms/`, `fitness/`, `mapscripts/`, `utils/`, `plotting/`, `analysis/`, `llm_bridge/` |
| `llm/` | **Python** weight generation, prompts, `io/` (no model weights in Git; see `llm/models/README.txt`) |
| `maps/` | Fixed benchmark map `.mat` / figures |
| `results/`, `figures/`, `logs/` | **Not** in Git; created when you run the experiment |
| `scripts/` | Optional **Python** helpers (ablation export, etc.); not required for `run_experiment` |

---

## Citing and SFO

Cite the Qwen model, baselines you compare, and your own work. `run_sfo.m` is a **paper-inspired** SFO (clarity and fair benchmarking, not a line-by-line match to one reference).

---

## Package zip

[`scripts/package_release.ps1`](scripts/package_release.ps1) builds a small archive; see also [`DISTRIBUTION.txt`](DISTRIBUTION.txt).
