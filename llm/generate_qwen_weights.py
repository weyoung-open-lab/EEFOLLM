#!/usr/bin/env python3
"""Qwen2.5-3B-Instruct reward-weight generator (real-first, mock-fallback)."""
import argparse
import json
import os
import re
import subprocess
import sys

# Keep large caches on the project drive (E:) instead of C:\Users\...\.cache
_REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_HF_CACHE = os.path.join(_REPO_ROOT, ".hf_cache")
os.makedirs(_HF_CACHE, exist_ok=True)
os.environ.setdefault("HF_HOME", _HF_CACHE)
os.environ.setdefault("HF_HUB_CACHE", _HF_CACHE)
os.environ.setdefault("TRANSFORMERS_CACHE", _HF_CACHE)


def clip_norm(stage):
    vals = [max(0.05, min(0.85, float(stage[k]))) for k in ("wL", "wC", "wS", "wT")]
    s = sum(vals) if sum(vals) > 0 else 1.0
    vals = [v / s for v in vals]
    return {"wL": vals[0], "wC": vals[1], "wS": vals[2], "wT": vals[3]}


def parse_first_json(text):
    m = re.search(r"\{.*\}", text, flags=re.S)
    if not m:
        raise ValueError("No JSON object found in model output")
    return json.loads(m.group(0))


def validate_stage_weights(w):
    for stage in ("early", "mid", "late"):
        if stage not in w:
            raise ValueError(f"Missing stage {stage}")
        for key in ("wL", "wC", "wS", "wT"):
            if key not in w[stage]:
                raise ValueError(f"Missing key {stage}.{key}")
            v = float(w[stage][key])
            if v < 0 or not (v == v):
                raise ValueError(f"Invalid value {stage}.{key}={v}")
        w[stage] = clip_norm(w[stage])
    return w


def run_real_qwen(features, prompt_path, model_id):
    from transformers import AutoModelForCausalLM, AutoTokenizer
    import torch

    use_cuda = torch.cuda.is_available()
    print(f"[device] cuda_available={use_cuda}", flush=True)
    if use_cuda:
        print(f"[device] device={torch.cuda.get_device_name(0)}", flush=True)

    prompt_tpl = ""
    if prompt_path and os.path.exists(prompt_path):
        with open(prompt_path, "r", encoding="utf-8") as f:
            prompt_tpl = f.read()
    if not prompt_tpl.strip():
        prompt_tpl = (
            "Given map features JSON, output ONLY valid JSON with keys early/mid/late and "
            "weights wL,wC,wS,wT for each stage."
        )
    user_prompt = (
        f"{prompt_tpl}\n\nMap features:\n{json.dumps(features, ensure_ascii=False, indent=2)}\n"
    )
    tokenizer = AutoTokenizer.from_pretrained(model_id, trust_remote_code=True)
    model = AutoModelForCausalLM.from_pretrained(
        model_id,
        trust_remote_code=True,
        torch_dtype=torch.float16 if use_cuda else torch.float32,
        device_map="auto",
    )
    inputs = tokenizer.apply_chat_template(
        [{"role": "user", "content": user_prompt}],
        tokenize=True,
        add_generation_prompt=True,
        return_tensors="pt",
    )
    inputs = inputs.to(model.device)
    out = model.generate(inputs, max_new_tokens=400, do_sample=False, temperature=0.0)
    text = tokenizer.decode(out[0][inputs.shape[-1]:], skip_special_tokens=True)
    parsed = parse_first_json(text)
    parsed = validate_stage_weights(parsed)
    parsed["_meta"] = {"mode": "real_qwen", "model": model_id}
    return parsed


def run_mock_subprocess(input_path, output_path):
    mock_path = os.path.join(os.path.dirname(__file__), "mock_llm_weights.py")
    cmd = [sys.executable, mock_path, "--input", input_path, "--output", output_path]
    subprocess.check_call(cmd)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--mode", default="auto", choices=["auto", "real", "mock"])
    parser.add_argument("--prompt", default="")
    parser.add_argument("--model", default="Qwen/Qwen2.5-3B-Instruct")
    args = parser.parse_args()

    with open(args.input, "r", encoding="utf-8") as f:
        feat = json.load(f)

    if args.mode == "mock":
        run_mock_subprocess(args.input, args.output)
        return

    try:
        result = run_real_qwen(feat, args.prompt, args.model)
        with open(args.output, "w", encoding="utf-8") as f:
            json.dump(result, f, ensure_ascii=False, indent=2)
    except Exception as e:
        if args.mode == "real":
            raise
        run_mock_subprocess(args.input, args.output)
        with open(args.output, "r", encoding="utf-8") as f:
            data = json.load(f)
        data["_meta"] = {"mode": "mock_fallback", "reason": str(e)}
        with open(args.output, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)


if __name__ == "__main__":
    main()
