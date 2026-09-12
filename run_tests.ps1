$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $root "start_server.bat"))) {
    $root = "C:\Programming\grok-build\ib-server"
}
$log = Join-Path $env:USERPROFILE "OneDrive\Documents\I-Novae Studios\Infinity Battlescape Server\Logs\MissionRuntime.txt"
if (-not (Test-Path (Split-Path $log))) {
    $log = Join-Path $env:USERPROFILE "Documents\I-Novae Studios\Infinity Battlescape Server\Logs\MissionRuntime.txt"
}
$results = Join-Path $root "MissionTests\results"
New-Item -ItemType Directory -Force -Path $results | Out-Null

$tests = @(
    "Test_01_Values.xml",
    "Test_02_ControlFlow.xml",
    "Test_03_Actors.xml",
    "Test_04_AI.xml",
    "Test_05_Triggers.xml",
    "Test_06_Hardpoints.xml",
    "Test_07_Persistence.xml"
)

function Stop-TestServer {
    & cmd.exe /c "`"$(Join-Path $root 'kill_server.bat')`""
}

Stop-TestServer
Start-Sleep -Seconds 1

$summary = @()
foreach ($t in $tests) {
    $mission = Join-Path $root "MissionTests\$t"
    $name = [IO.Path]::GetFileNameWithoutExtension($t)
    Write-Host "==== START $t ===="
    if (Test-Path $log) { Remove-Item $log -Force -ErrorAction SilentlyContinue }

    & cmd.exe /c "`"$(Join-Path $root 'start_server.bat')`" mission `"$mission`""
    $startExit = $LASTEXITCODE
    if ($startExit -ne 0) {
        Write-Host "START FAIL $t exit $startExit"
        $summary += [pscustomobject]@{ Test = $t; Result = "START_FAIL"; Failures = "" }
        Stop-TestServer
        continue
    }

    $deadline = (Get-Date).AddSeconds(90)
    $complete = $null
    while ((Get-Date) -lt $deadline) {
        if (Test-Path $log) {
            $lines = @(Select-String -Path $log -Pattern "Test: COMPLETE" -ErrorAction SilentlyContinue)
            if ($lines.Count -gt 0) {
                $complete = $lines[-1].Line
                break
            }
        }
        Start-Sleep -Seconds 1
    }

    Stop-TestServer
    Start-Sleep -Seconds 1

    if (Test-Path $log) {
        Copy-Item $log (Join-Path $results "${name}_MissionRuntime.txt") -Force
        Write-Host "---- Test lines $t ----"
        Select-String -Path $log -Pattern "Test:" | ForEach-Object { $_.Line }
    }

    if ($null -eq $complete) {
        Write-Host "TIMEOUT $t"
        $summary += [pscustomobject]@{ Test = $t; Result = "TIMEOUT"; Failures = "" }
    } else {
        $fails = @()
        if (Test-Path $log) {
            $fails = @(Select-String -Path $log -Pattern "Test: \S+ Failure" | ForEach-Object { ($_.Line -replace '.*Test: ', '') })
        }
        $result = if ($complete -match "Pass") { "Pass" } else { "Failure" }
        $summary += [pscustomobject]@{ Test = $t; Result = $result; Failures = ($fails -join " | ") }
        Write-Host "RESULT $t $result"
    }
}

Write-Host "==== SUMMARY ===="
$summary | Format-Table -AutoSize | Out-String | Write-Host
$failCount = @($summary | Where-Object { $_.Result -ne "Pass" }).Count
if ($failCount -gt 0) { exit 1 } else { exit 0 }