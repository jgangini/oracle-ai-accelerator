$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Push-Location $root
try {
    if ((Test-Path "graphify-out/graph.json") -and (Get-Command graphify -ErrorAction SilentlyContinue)) {
        graphify update .
    }

    if ((Test-Path ".sentrux/rules.toml") -and (Get-Command sentrux -ErrorAction SilentlyContinue)) {
        sentrux check .
        sentrux gate .
    }
}
finally {
    Pop-Location
}
