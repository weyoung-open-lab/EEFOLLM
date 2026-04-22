# EEFOLLM

**EEFOLLM** 是在栅格地图上做路径规划的方法：在 **EEFO**（`matlab/algorithms/run_eefo.m`）框架内，用**大语言模型**为早/中/晚迭代阶段生成**分阶段子目标权重**，驱动同一套**四项加权和标量适应度**（路长、碰撞/安全、平滑、转弯等；见 `matlab/fitness/` 与 `matlab/config/default_config.m` 中的 `cfg.weights`）。实现入口为 `matlab/algorithms/run_llm_eefo.m`（注册名 **EEFOLLM**）。仓库含 **MATLAB**（`matlab/`）与 **Python 权重侧**（`llm/`）；Qwen 权重文件**不入库**，需按下文安装。

本仓库在 [MIT](LICENSE) 下发布。Qwen、PyTorch 等第三方仍遵循各自协议。

---

## 算法框架

<p align="center">
  <img src="docs/images/eefollm_framework.png" alt="EEFOLLM 算法框架" width="820"/>
</p>

---

## 方法要点与创新点

**方法要点**

- **表示**：用 **K 个路点** 编码连续曲线路径（搜索维度 \(2K\)，`cfg.path.default_k` 等见 `default_config.m`）。  
- **适应度**：多子目标在每一代合成**一个标量**，并可按**迭代早/中/晚**使用**不同权重**；**EEFOLLM** 的权重由 **LLM** 根据**地图/特征**在优化前由 Python 生成，MATLAB 校验收敛后按阶段使用（`llm/generate_qwen_weights.py` 等）。  
- **优化器**：`run_llm_eefo` 内部与 **EEFO** 共用的种群更新，区别是打开 `use_stage_weights` 与 LLM 产生的 `stage_weights`。

**创新点（写作时可结合代码与实现细节展开）**

1. **由地图到分阶段标量权向量**：用 LLM 将**环境/任务特征**映射为 **early / mid / late 三套**目标权重，在搜索进程中对同一适应度**动态塑形**，区别于全程单一静态权或手调分阶段表。  
2. **与统一路径编码及约束型适应度闭环**：在**可微/可仿真**的栅格与碰撞约束下，将上述权重接入已有 `run_eefo` 搜索循环，使「语言侧先验」与「路径数值优化」同一管线可复现。

---

## 按 README 复现实验

1. **工作目录**设为**仓库根目录**（含 `matlab/`、`llm/`、`maps/`）。  
2. 在 **MATLAB** 中：  
   `addpath('matlab');`  
   然后 `run_experiment`（可复现的**主实验**入口，内部调用 `matlab/run_global_experiments_batch1.m`）。  
3. **已跑过、想强制重算**：`run_experiment(true)`，或在 `default_config.m` 中设 `cfg.rerun_global_experiments = true`，或删除 `results/global_experiments_batch1/mat/global_results.mat` 后重跑。  
4. **主实验量与开关**在 [`matlab/config/default_config.m`](matlab/config/default_config.m)：`cfg.exp.runs_per_map`（默认 **20** 次/图/算法）、`cfg.exp.population`、`cfg.exp.iterations`；`cfg.use_real_qwen` 控制是否用真实 Qwen 生成权重（`false` 时为 mock，便于无 GPU/无模型时跑通流程）。

**输出位置（运行后生成，默认不入 Git）**

- 数据与表：`results/global_experiments_batch1/`（如 `mat/global_results.mat`，`tables/*.csv`，`features/`，`weights/`）  
- 图：`figures/global_experiments_batch1/`  
- 日志：`logs/`

在表格或图中筛选 **算法名为 `EEFOLLM`** 的行/曲线，即为所提出方法的结果。

---

## LLM 权重环境（真机 Qwen 时）

- **模型**：[Qwen2.5-3B-Instruct](https://huggingface.co/Qwen/Qwen2.5-3B-Instruct)（[ModelScope 镜像](https://www.modelscope.cn/models/qwen/Qwen2.5-3B-Instruct) 可选）  
- **本地模型目录**见 `default_config.m` 中 `cfg.llm.local_model_dir`；可下载：  

```text
python -m pip install -U huggingface_hub hf_xet
python llm\download_qwen_model.py --repo Qwen/Qwen2.5-3B-Instruct --out llm\models\Qwen2.5-3B-Instruct-full
```

- 建议在仓库根建 **`.venv`**；若存在 `.\.venv\Scripts\python.exe`，配置会优先使用。安装 `pip install -r requirements-llm.txt` 与适合的 **PyTorch**；也可参考 [`setup_venv_e.ps1`](setup_venv_e.ps1)（Windows/CUDA 示例）。  
- Python 端对权重做裁剪，MATLAB 再校验/按阶段重归一化（见 `llm/generate_qwen_weights.py`）。

---

## 目录（复现需关注）

| 路径 | 说明 |
|------|------|
| `matlab/` | 全部 **`.m`**：入口 `run_experiment.m`、`config/default_config.m`、`algorithms/run_llm_eefo.m`、`algorithms/run_eefo.m`、`fitness/`、`llm_bridge/` 等 |
| `llm/` | Python 与提示词、`io/` 运行时文件（模型不提交；见 `llm/models/README.txt`） |
| `maps/` | 固定 benchmark 地图 |
| `docs/images/` | 本 README 中的框架图，**可提交** |

`results/`、`logs/`、`figures/` 在 `.gitignore` 中，为本地跑实验产出。

---

## 引用

若使用本仓库，请**引用**所用 **Qwen** 的论文/技术报告、**EEFO** 的原始文献（若成文），以及**你自己的工作/本项目**在文中给出的条目。
