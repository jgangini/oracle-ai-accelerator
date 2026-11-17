$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Push-Location $root
try {
    if (Test-Path "graphify-out/GRAPH_REPORT.md") {
        Get-Content "graphify-out/GRAPH_REPORT.md" -TotalCount 80 | Out-Host
    }

    if ((Test-Path ".sentrux/rules.toml") -and (Get-Command sentrux -ErrorAction SilentlyContinue)) {
        sentrux gate --save .
        sentrux check .
    }
}
finally {
    Pop-Location
}
