Clear-Host

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "COAL LLC - SAFE LOG AUDITOR & TEST RUNNER" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$repoRoot      = "C:\Dev\coal-llc-mods"
$steamRoot     = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$appDataGodot  = [System.IO.Path]::Combine($env:APPDATA, "Godot\app_userdata\Coal LLC")
$modloaderLog  = [System.IO.Path]::Combine($steamRoot, "modloader.log")
$godotLog      = [System.IO.Path]::Combine($appDataGodot, "logs\godot.log")
$testsTxt      = [System.IO.Path]::Combine($repoRoot, "tests.txt")
$conciseOut    = [System.IO.Path]::Combine($repoRoot, "tests_concise.txt")
$reducerScript = [System.IO.Path]::Combine($repoRoot, "Reduce_Test_Output.ps1")

function Read-LogFileSafely {
    param([string]$FilePath)
    if (-not [System.IO.File]::Exists($FilePath)) { return @() }
    try {
        $fs = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $sr = [System.IO.StreamReader]::new($fs, [System.Text.Encoding]::UTF8)
        $lines = [System.Collections.Generic.List[string]]::new()
        while (-not $sr.EndOfStream) {
            $lines.Add($sr.ReadLine())
        }
        $sr.Dispose()
        $fs.Dispose()
        return $lines
    } catch {
        Write-Warning "Could not read $FilePath : $_"
        return @()
    }
}

$rawEntries = [System.Collections.Generic.List[string]]::new()
$mlCount = 0
$godotCount = 0

if ([System.IO.File]::Exists($modloaderLog)) {
    Write-Host "Auditing modloader.log..." -ForegroundColor Cyan
    $mlLines = Read-LogFileSafely -FilePath $modloaderLog
    for ($i = 0; $i -lt $mlLines.Count; $i++) {
        $l = $mlLines[$i]
        if ([string]::IsNullOrWhiteSpace($l)) { continue }
        if ($l -match "ERROR|CRITICAL|failed|cannot be loaded") {
            $rawEntries.Add(("{0,4}: [ModLoader] {1}" -f ($i + 1), $l.Trim())))
            $mlCount++
        }
    }
}

if ([System.IO.File]::Exists($godotLog)) {
    Write-Host "Auditing godot.log..." -ForegroundColor Cyan
    $godotLines = Read-LogFileSafely -FilePath $godotLog
    $telemetry = [System.Collections.Generic.List[string]]::new()

    for ($i = 0; $i -lt $godotLines.Count; $i++) {
        $l = $godotLines[$i]
        if ([string]::IsNullOrWhiteSpace($l)) { continue }

        if ($l -match "ERROR|CRITICAL|failed to load script|Parse Error|Compile Error|Invalid call|Invalid get index|Invalid access|Invalid assignment|Invalid type") {
            if (-not $l.Contains("der_floh-performance_mod")) {
                $rawEntries.Add(("{0,4}: {1}" -f ($i + 1), $l.Trim())))
                $godotCount++
                
                # NEW: Capture the stack trace line immediately following the error
                if ($i + 1 -lt $godotLines.Count -and $godotLines[$i+1] -match "^\s*at:") {
                    $rawEntries.Add(("{0,4}:   {1}" -f ($i + 2), $godotLines[$i+1].Trim())))
                }
            }
        }

        if ($l.Contains("[KnightSword]") -or $l.Contains("Auto choosing") -or $l.Contains("Transmutation") -or $l.Contains("[Frenzy]")) {
            $telemetry.Add(("{0,4}: {1}" -f ($i + 1), $l.Trim())))
        }
    }

    if ($telemetry.Count -gt 0) {
        $rawEntries.Add("Telemetry Highlights (Last 15):")
        $start = [Math]::Max(0, $telemetry.Count - 15)
        for ($t = $start; $t -lt $telemetry.Count; $t++) {
            $rawEntries.Add($telemetry[$t])
        }
    }
}

[System.IO.File]::WriteAllLines($testsTxt, $rawEntries, [System.Text.Encoding]::UTF8)

if (Test-Path $reducerScript) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $reducerScript -InputPath $testsTxt -OutputPath $conciseOut
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Audit Results: $mlCount ModLoader errors | $godotCount Godot errors" -ForegroundColor $(if ($mlCount + $godotCount -gt 0) { "Yellow" } else { "Green" })
Write-Host "Summarized telemetry output written to: tests_concise.txt" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan

if (Test-Path $conciseOut) {
    Get-Content $conciseOut | ForEach-Object { Write-Host "  $_" }
}
