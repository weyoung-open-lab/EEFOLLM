# Install Python deps into <project>/.venv (packages + pip cache under project)
$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
$env:PIP_CACHE_DIR = Join-Path $Root ".pip_cache"
New-Item -ItemType Directory -Force -Path $env:PIP_CACHE_DIR | Out-Null
$Py = Join-Path $Root ".venv\Scripts\python.exe"
if (-not (Test-Path $Py)) {
    python -m venv (Join-Path $Root ".venv")
}
& $Py -m pip install --upgrade pip
& $Py -m pip install torch --index-url https://download.pytorch.org/whl/cu124
& $Py -m pip install numpy transformers==4.46.3 accelerate safetensors huggingface_hub hf_xet tokenizers==0.20.3 regex pyyaml
