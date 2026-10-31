Clear-Host

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "COAL LLC - DEEP LOG AUDITOR" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$repoRoot      = "C:\Dev\coal-llc-mods"
$steamRoot     = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$appDataGodot  = [System.IO.Path]::Combine($env:APPDATA, "Godot\app_userdata\Coal LLC")
$modloaderLog  = [System.IO.Path]::Combine($steamRoot, "modloader.log")
$godotLog      = [System.IO.Path]::Combine($appDataGodot, "logs\godot.log")
$conciseOut    = [System.IO.Path]::Combine($repoRoot, "tests_concise.txt")

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
$errorContext = [System.Collections.Generic.List[string]]::new()

# 1. Audit godot.log
if ([System.IO.File]::Exists($godotLog)) {
    Write-Host "Auditing godot.log..." -ForegroundColor Cyan
    $godotLines = Read-LogFileSafely -FilePath $godotLog

    for ($i = 0; $i -lt $godotLines.Count; $i++) {
        $l = $godotLines[$i]
        if ([string]::IsNullOrWhiteSpace($l)) { continue }

        # Match any line containing ERROR or runtime execution breaks
        if ($l -match "ERROR|CRITICAL|failed to load script|Parse Error|Compile Error|Invalid call|Invalid get index|Invalid access|Invalid assignment|Invalid type") {
            if (-not $l.Contains("der_floh-performance_mod")) {
                $rawEntries.Add(("{0,4}: {1}" -f ($i + 1), $l.Trim()))
                $godotCount++
                
                # Capture context around the error if it involves a specific script file
                if ($l -match "res://mods-unpacked/([^/]+)/scripts/([^.]+).gd") {
                    $modName = $matches[1]
                    $scriptName = $matches[2]
                    $errorContext.Add("--- Error Context: $scriptName ---")
                    $errorContext.Add($l.Trim())
                    
                    # Look ahead for a line number
                    for ($j = $i + 1; $j -le $i + 3 -and $j -lt $godotLines.Count; $j++) {
                         if ($godotLines[$j] -match "at: (\w+) \((.*?):(\d+)\)") {
                            $errorContext.Add("Line Number Found: " + $godotLines[$j].Trim())
                            break
                         }
                    }
                }
            }
        }
    }
}

# 2. Append Error Context
if ($errorContext.Count -gt 0) {
    $rawEntries.Add("")
    $rawEntries.Add("==========================================")
    $rawEntries.Add("DETAILED SCRIPT ERROR CONTEXT")
    $rawEntries.Add("==========================================")
    $rawEntries.AddRange($errorContext)
}

# 3. Write concise matching entries to tests_concise.txt
[System.IO.File]::WriteAllLines($conciseOut, $rawEntries, [System.Text.Encoding]::UTF8)

# 4. Display concise results
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Audit Results: $mlCount ModLoader errors | $godotCount Godot errors" -ForegroundColor $(if ($mlCount + $godotCount -gt 0) { "Yellow" } else { "Green" })
Write-Host "Deep telemetry output written to: tests_concise.txt" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan

if (Test-Path $conciseOut) {
    Get-Content $conciseOut -Tail 30 | ForEach-Object { Write-Host "  $_" }
}