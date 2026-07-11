$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$rscript = Get-Command Rscript -ErrorAction SilentlyContinue
if (-not $rscript) { throw 'Rscript was not found on PATH. Run scripts/render_paper.R with your local Rscript executable.' }
& $rscript.Source 'scripts/render_paper.R'
