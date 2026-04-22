# package_release.ps1 — 生成分发用压缩包（排除实验结果、日志、环境、缓存及部分一次性脚本）
# 作用：在项目根目录的上级或本目录生成 sfollm-release-YYYYMMDD.zip，便于开源或外发。
# 用法：在 PowerShell 中执行:  cd <项目根目录>;  .\scripts\package_release.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$Stamp = Get-Date -Format "yyyyMMdd"
$StagingRoot = Join-Path $ProjectRoot "_release_staging"
$Staging = Join-Path $StagingRoot "sfollm"
$ZipName = "sfollm-release-$Stamp.zip"
$ZipPath = Join-Path $ProjectRoot $ZipName

$ExcludeTopDirs = @(
    "results",
    "logs",
    ".venv",
    ".hf_cache",
    ".pip_cache",
    "figures",
    "_release_staging",
    "__pycache__",
    ".git"
)

$ExcludeRootFiles = @(
    $ZipName
)

# 不打包的一次性/补跑脚本（相对项目根）
# 仅剔除作者本地补跑、合并旧结果的入口脚本
$ExcludeRelFiles = @(
    "main_rerun_eefollm_map35_merge_batch1.m",
    "main_rerun_eefollm_map2_merge_batch1.m",
    "main_rerun_eefollm_maps_merge_batch1.m",
    "main_rerun_eefollm_map12_merge_batch1.m"
)

Write-Host "Project root: $ProjectRoot"
Write-Host "Staging:      $Staging"
Write-Host "Output zip:   $ZipPath"

if (Test-Path $StagingRoot) {
    Remove-Item $StagingRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $Staging -Force | Out-Null

Get-ChildItem -LiteralPath $ProjectRoot -Force | ForEach-Object {
    $name = $_.Name
    if ($ExcludeTopDirs -contains $name) { return }
    if ($ExcludeRootFiles -contains $name) { return }
    if ($name -like "sfollm-release-*.zip") { return }
    $dest = Join-Path $Staging $name
    Copy-Item -LiteralPath $_.FullName -Destination $dest -Recurse -Force
}

foreach ($rel in $ExcludeRelFiles) {
    $p = Join-Path $Staging $rel
    if (Test-Path -LiteralPath $p) {
        Remove-Item -LiteralPath $p -Force
        Write-Host "Removed from staging: $rel"
    }
}

# 不打包 LLM 权重本体（体积过大）：清空 llm\models，仅保留说明文件
$ModelsStaging = Join-Path $Staging "llm\models"
$ReadmeModels = Join-Path $ProjectRoot "llm\models\README.txt"
if (Test-Path -LiteralPath $ModelsStaging) {
    Remove-Item -LiteralPath $ModelsStaging -Recurse -Force
}
New-Item -ItemType Directory -Path $ModelsStaging -Force | Out-Null
if (Test-Path -LiteralPath $ReadmeModels) {
    Copy-Item -LiteralPath $ReadmeModels -Destination (Join-Path $ModelsStaging "README.txt") -Force
    Write-Host "Replaced llm\models with README only (no weights)."
}

# 删除嵌套的 Python 缓存与 Hugging Face 下载缓存
Get-ChildItem -Path $Staging -Recurse -Directory -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -eq "__pycache__" -or $_.Name -eq ".cache" } |
    ForEach-Object {
        Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }

$DistSrc = Join-Path $ProjectRoot "DISTRIBUTION.txt"
$DistDst = Join-Path $Staging "DISTRIBUTION.txt"
if (Test-Path -LiteralPath $DistSrc) {
    Copy-Item -LiteralPath $DistSrc -Destination $DistDst -Force
}

$bytesStaging = (Get-ChildItem -Path $Staging -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
Write-Host ("Staging uncompressed: {0:N2} MB (expect ~0.5–3 MB without models/venv/results)" -f ($bytesStaging / 1MB))
Write-Host "Included: config/, algorithms/, fitness/, maps/, llm/ (no weights), scripts/, *.m at root, etc."

if (Test-Path -LiteralPath $ZipPath) {
    Remove-Item -LiteralPath $ZipPath -Force
}

# 压缩后解压得到顶层文件夹 sfollm\
Compress-Archive -LiteralPath $Staging -DestinationPath $ZipPath -CompressionLevel Optimal

Write-Host "Done: $ZipPath"
$sizeMb = [math]::Round((Get-Item -LiteralPath $ZipPath).Length / 1MB, 2)
Write-Host "Size: $sizeMb MB"
