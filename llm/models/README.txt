================================================================================
  Qwen2.5-3B-Instruct — local weight directory (NOT shipped with the repo)
================================================================================

This directory is intentionally empty in the public / source-only repository.
Model weights are several GB; you must download them after cloning.

Default path expected by the project (see config/default_config.m):
  llm/local_model_dir ->  llm/models/Qwen2.5-3B-Instruct-full

Official model card (Hugging Face):
  https://huggingface.co/Qwen/Qwen2.5-3B-Instruct

Mirror (ModelScope, often faster in some regions):
  https://www.modelscope.cn/models/qwen/Qwen2.5-3B-Instruct

License of the Qwen model: see the model card and files LICENSE in the
downloaded folder (e.g. Apache-2.0 for Qwen2.5). This research codebase is
separate; comply with the model license when you download and use it.

--- Download (from repository root) -------------------------------------------

  python -m pip install -U huggingface_hub hf_xet
  python llm/download_qwen_model.py --repo Qwen/Qwen2.5-3B-Instruct --out llm/models/Qwen2.5-3B-Instruct-full

The script is resumable. After success you should have at least:
  config.json, tokenizer.json, model.safetensors.index.json,
  model-00001-of-00002.safetensors, model-00002-of-00002.safetensors

If you use a different folder name, set cfg.llm.local_model_dir in
config/default_config.m, or pass a local path that contains the files above
(generate_llm_weights.m will pass it to Python as --model).

--- Without local weights -----------------------------------------------------

Set cfg.use_real_qwen = false in default_config.m to use the deterministic
mock weight generator (no GPU / large download required). Experiments then
use mock_llm_weights.py instead of loading Qwen.

================================================================================
  本目录不随仓库提供权重（需自行下载，约数 GB）
================================================================================

见上方英文。要点：在工程根目录执行 download_qwen_model.py 下载到
  llm/models/Qwen2.5-3B-Instruct-full
与 default_config.m 中 cfg.llm.local_model_dir 一致即可。
