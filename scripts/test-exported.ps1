param([switch]$SkipBuild, [string]$ExistingSave = '', [switch]$MotionOnly)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$godotExe = Join-Path $projectRoot '.tools/godot/Godot_v4.6.3-stable_win64_console.exe'
$validationExe = Join-Path $projectRoot 'build/Validation/LanternAtlasValidation.exe'
Push-Location $projectRoot
try {
    $env:APPDATA = Join-Path $projectRoot '.tools/runtime'
    $env:LOCALAPPDATA = $env:APPDATA
    New-Item -ItemType Directory -Force build/Validation,test-output | Out-Null
    if (-not $SkipBuild) {
        & $godotExe --headless --path . --editor --import --quit
        if ($LASTEXITCODE -ne 0) { throw 'Import failed.' }
        & $godotExe --headless --path . --export-release 'Windows Validation' $validationExe
        if ($LASTEXITCODE -ne 0) { throw 'Validation export failed.' }
    }
    function Invoke-ExportScenario($Name, $Label, $EngineArgs, $UserArgs) {
        $scenarioLog = Join-Path $projectRoot "test-output/$Label.log"
        $arguments = @($EngineArgs) + @('--disable-vsync','--log-file',('"'+$scenarioLog+'"'),'--','--test-play',"--scenario=$Name") + @($UserArgs)
        $scenarioProcess = Start-Process -FilePath $validationExe -ArgumentList $arguments -WindowStyle Hidden -PassThru
        if (-not $scenarioProcess.WaitForExit(30000)) {
            Stop-Process -Id $scenarioProcess.Id
            throw "Validation timed out: $Label"
        }
        $output = Get-Content -Raw -LiteralPath $scenarioLog
        Get-Content -LiteralPath $scenarioLog -Tail 2
        # A script exception can leave Godot's process exit code at zero.
        if ($scenarioProcess.ExitCode -ne 0 -or $output -match 'SCRIPT ERROR|Parse Error|ERROR: (?!Failed to read the root certificate store)') {
            throw "Validation failed: $Label. See $scenarioLog"
        }
    }
    if (-not $MotionOnly) {
        foreach ($scenario in @('doorway_tests','navigation_tests','population_tests','exploration_tests','version_tests','playthrough_3d')) {
            Invoke-ExportScenario $scenario "export-$scenario" @('--fixed-fps','60') @()
        }
        if ($ExistingSave) {
            $env:LANTERN_VALIDATION_SAVE = (Resolve-Path -LiteralPath $ExistingSave).Path
            Invoke-ExportScenario 'existing_save_tests' 'export-existing-save' @('--fixed-fps','60') @()
            Remove-Item Env:LANTERN_VALIDATION_SAVE
        }
    }
    # Real-time render/physics mismatch probes, not fixed-FPS movie simulation.
    foreach ($context in @('hub','grotto')) {
        foreach ($case in @(@(30,90,60),@(60,180,60),@(144,432,60),@(144,432,10))) {
            $label = "export-motion-$context-$($case[0])fps-$($case[2])ticks"
            Invoke-ExportScenario 'motion_probe' $label @('--max-fps',$case[0]) @("--frames=$($case[1])","--ticks=$($case[2])","--label=$label","--context=$context")
        }
    }
    Invoke-ExportScenario 'motion_probe' 'export-motion-interior-60fps' @('--max-fps',60) @('--frames=180','--context=interior','--label=export-motion-interior-60fps')
} finally { Pop-Location }
