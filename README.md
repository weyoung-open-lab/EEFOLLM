# EEFOLLM

**EEFOLLM** is a method for path planning on grid maps. It runs inside the **EEFO** search loop ([`matlab/algorithms/run_eefo.m`](matlab/algorithms/run_eefo.m)) and uses a **large language model** to generate **stage-wise sub-objective weights** (early / mid / late) for a single **scalar fitness** with four weighted terms (path length, collision / safety, smoothness, turning; see `matlab/fitness/` and `cfg.weights` in [`matlab/config/default_config.m`](matlab/config/default_config.m)). The method is implemented in [`matlab/algorithms/run_llm_eefo.m`](matlab/algorithms/run_llm_eefo.m) (registered name **EEFOLLM**). The repository contains **MATLAB** code under [`matlab/`](matlab/) and a **Python** weight pipeline under [`llm/`](llm/). Qwen model weights are **not** included in the repository; set them up as described below.

Released under the [MIT License](LICENSE). Qwen, PyTorch, and other third-party components remain under their own licenses.

---

## Framework

<p align="center">
  <img src="docs/images/eefollm_framework.png" alt="EEFOLLM framework" width="820"/>
</p>

---

## Method and contributions

**Method**

- **Encoding**: a continuous path is represented by **K waypoints** (search dimension \(2K\); see `cfg.path.default_k` in `default_config.m`).  
- **Fitness**: sub-objectives are combined into one scalar per generation; **early / mid / late** stages may use different weights. For **EEFOLLM**, these weights are produced by an **LLM** from **map features** in Python before optimization, then validated in MATLAB and applied per stage (see `llm/generate_qwen_weights.py`).  
- **Optimizer**: `run_llm_eefo` shares the same EEFO population update as `run_eefo`, with `use_stage_weights` enabled and `stage_weights` from the LLM.

**Contributions**

1. **Map-conditioned stage weights**: the LLM maps **environment and task features** to **three** weight sets (early, mid, late), reshaping the same scalar fitness across the run instead of using one static set or a hand-tuned table for all stages.  
2. **End-to-end integration**: those weights are wired into the existing `run_eefo` loop on a **unified path encoding** under **grid and collision** constraints, so language-derived priors and continuous path optimization share one reproducible pipeline.

---

## Reproducing experiments

1. Set the **MATLAB** current folder to the **repository root** (the directory that contains `matlab/`, `llm/`, and `maps/`).  
2. Run:  
   `addpath('matlab');`  
   then `run_experiment` (main entry; it calls [`matlab/run_global_experiments_batch1.m`](matlab/run_global_experiments_batch1.m)).  
3. To **force a full re-run** (ignore cached results): `run_experiment(true)`, or set `cfg.rerun_global_experiments = true` in `default_config.m`, or delete `results/global_experiments_batch1/mat/global_results.mat` and run again.  
4. **Experiment scale and options** in [`matlab/config/default_config.m`](matlab/config/default_config.m): e.g. `cfg.exp.runs_per_map` (default **20**), `cfg.exp.population`, `cfg.exp.iterations`; `cfg.use_real_qwen` toggles the real Qwen model (`false` uses a mock weight generator for machines without a local model or GPU).

**Where outputs are written (created at run time; not tracked by default)**

- Tables and `mat/`: `results/global_experiments_batch1/`  
- Figures: `figures/global_experiments_batch1/`  
- Logs: `logs/`

In exported tables or figures, filter rows or series where the algorithm is **`EEFOLLM`** to read off the proposed method.

---

## LLM setup (real Qwen)

- **Model:** [Qwen2.5-3B-Instruct](https://huggingface.co/Qwen/Qwen2.5-3B-Instruct) (optional mirror: [ModelScope](https://www.modelscope.cn/models/qwen/Qwen2.5-3B-Instruct)).  
- **Local model path:** `cfg.llm.local_model_dir` in `default_config.m`. Download example:  

```text
python -m pip install -U huggingface_hub hf_xet
python llm\download_qwen_model.py --repo Qwen/Qwen2.5-3B-Instruct --out llm\models\Qwen2.5-3B-Instruct-full
```

- Create a **`.venv`** in the repo root; if `.\.venv\Scripts\python.exe` exists, `default_config` will prefer it. Install `pip install -r requirements-llm.txt` and a suitable **PyTorch** build. See [`setup_venv_e.ps1`](setup_venv_e.ps1) for a Windows + CUDA example.  
- Weights are clipped in Python and revalidated / renormalized per stage in MATLAB (`llm/generate_qwen_weights.py`).

---

## Repository layout

| Path | Role |
|------|------|
| `matlab/` | All **`.m`** code: `run_experiment.m`, `config/default_config.m`, `algorithms/run_llm_eefo.m`, `algorithms/run_eefo.m`, `fitness/`, `llm_bridge/`, … |
| `llm/` | Python scripts, prompts, `io/` runtime files (models are not in Git; see `llm/models/README.txt`) |
| `maps/` | Fixed benchmark maps |
| `docs/images/` | Framework figure (tracked) |

`results/`, `logs/`, and `figures/` are listed in `.gitignore` as local run artifacts.

---

## Citation

If you use this repository, please cite the **Qwen** model and its report, the **EEFO** method as appropriate, and your own publication for this work.
