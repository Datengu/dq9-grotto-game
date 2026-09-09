param([int]$Count = 1000, [switch]$Visual)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$godotExe = Join-Path $projectRoot '.tools\godot\Godot_v4.6.3-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $godotExe)) { throw 'Godot 4.6.3 is required. See README.md.' }
Push-Location $projectRoot
try {
    $env:APPDATA = Join-Path $projectRoot '.tools\runtime'
    $env:LOCALAPPDATA = $env:APPDATA
    New-Item -ItemType Directory -Force $env:APPDATA,test-output | Out-Null
    & $godotExe --headless --path . --editor --import --quit
    if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
    & $godotExe --headless --path . --script res://tests/test_runner.gd -- "--count=$Count"
    if ($LASTEXITCODE -ne 0) { throw 'Generation/state/combat tests failed.' }
    foreach ($test in @('balance_tests','version_tests','navigation_tests','doorway_tests','population_tests','exploration_tests','playthrough_3d')) {
        if ($Visual -and $test -in @('exploration_tests','playthrough_3d')) {
            & $godotExe --path . --script "res://tests/$test.gd" --fixed-fps 60 --disable-vsync -- --test-play
        } else {
            & $godotExe --headless --path . --script "res://tests/$test.gd" --fixed-fps 60 -- --test-play
        }
        if ($LASTEXITCODE -ne 0) { throw "$test failed." }
    }
} finally { Pop-Location }
