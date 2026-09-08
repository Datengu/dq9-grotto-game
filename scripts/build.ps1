$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$godotExe = Join-Path $projectRoot '.tools\godot\Godot_v4.6.3-stable_win64_console.exe'
$destination = Join-Path $projectRoot 'build\LanternAtlas'
Push-Location $projectRoot
try {
    if (-not (Test-Path '.tools\templates\windows_release_x86_64.exe')) {
        node scripts/fetch-template.mjs
        if ($LASTEXITCODE -ne 0) { throw 'Official template download failed.' }
    }
    New-Item -ItemType Directory -Force $destination | Out-Null
    $env:APPDATA = Join-Path $projectRoot '.tools\runtime'
    $env:LOCALAPPDATA = $env:APPDATA
    & $godotExe --headless --path . --export-release 'Windows Desktop' (Join-Path $destination 'LanternAtlas.exe')
    if ($LASTEXITCODE -ne 0) { throw 'Windows export failed.' }
    Copy-Item -LiteralPath '.tools\templates\GODOT-LICENSE.txt','.tools\templates\GODOT-COPYRIGHT.txt' -Destination $destination
    Copy-Item -LiteralPath 'docs\PLAYER-GUIDE.txt' -Destination $destination
    Copy-Item -LiteralPath 'docs\CHANGELOG.md' -Destination $destination
    $exeHash = (Get-FileHash -Algorithm SHA256 (Join-Path $destination 'LanternAtlas.exe')).Hash
    [ordered]@{
        version = '0.2.0'
        engine = 'Godot 4.6.3'
        built_utc = (Get-Date).ToUniversalTime().ToString('o')
        executable_sha256 = $exeHash
        save_version = 2
        supported_generators = @(1,2)
    } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $destination 'build-info.json')
    Compress-Archive -Path "$destination\*" -DestinationPath 'build\LanternAtlas-Windows.zip' -Force
    Get-FileHash -Algorithm SHA256 (Join-Path $destination 'LanternAtlas.exe')
} finally { Pop-Location }
