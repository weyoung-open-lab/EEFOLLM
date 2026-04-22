#!/usr/bin/env python3
"""Download helper for Qwen2.5-3B-Instruct with resume and completion check."""
import argparse
import os
from huggingface_hub import snapshot_download


def is_complete(model_dir: str) -> bool:
    need_files = [
        "config.json",
        "tokenizer.json",
        "tokenizer_config.json",
        "model.safetensors.index.json",
        "model-00001-of-00002.safetensors",
        "model-00002-of-00002.safetensors",
    ]
    return all(os.path.exists(os.path.join(model_dir, x)) for x in need_files)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", default="Qwen/Qwen2.5-3B-Instruct")
    parser.add_argument("--out", default="llm/models/Qwen2.5-3B-Instruct")
    args = parser.parse_args()

    out_dir = os.path.abspath(args.out)
    os.makedirs(out_dir, exist_ok=True)

    if is_complete(out_dir):
        print("status=already_complete")
        print(f"model_dir={out_dir}")
        return

    path = snapshot_download(
        repo_id=args.repo,
        local_dir=out_dir,
        resume_download=True,
        local_dir_use_symlinks=False,
    )
    print("status=download_finished")
    print(f"model_dir={path}")
    print(f"complete={is_complete(out_dir)}")


if __name__ == "__main__":
    main()
