Clear-Host

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "COAL LLC - SAFE LOG AUDITOR & TEST RUNNER" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$repoRoot   = "C:\Dev\coal-llc-mods"
$logDir     = [System.IO.Path]::Combine($env:APPDATA, "Godot\app_userdata\Coal LLC\logs")
$godotLog   = [System.IO.Path]::Combine($logDir, "godot.log")
$conciseOut = [System.IO.Path]::Combine($repoRoot, "tests_concise.txt")

if (-not [System.IO.File]::Exists($godotLog)) {
    Write-Host "godot.log not found at $godotLog" -ForegroundColor Yellow
    exit 0
}

Write-Host "Reading $godotLog (safe shared read)..." -ForegroundColor Cyan

# Read shared stream even if Godot is currently holding the file open
$fileStream = [System.IO.FileStream]::new($godotLog, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
$reader     = [System.IO.StreamReader]::new($fileStream, [System.Text.Encoding]::UTF8)
$lines      = [System.Collections.Generic.List[string]]::new()
while (-not $reader.EndOfStream) {
    $lines.Add($reader.ReadLine())
}
$reader.Dispose()
$fileStream.Dispose()

Write-Host "Audited $($lines.Count) log lines. Processing concise telemetry..." -ForegroundColor Green

# Use StreamWriter to directly generate tests_concise.txt without intermediate files
$writer = [System.IO.StreamWriter]::new($conciseOut, $false, [System.Text.Encoding]::UTF8)

$currentKey = $null
$firstLine  = $null
$lastLine   = $null
$count      = 0

function Flush-Run {
    param($key, $first, $last, [int]$cnt)
    if ($cnt -eq 1) {
        $writer.WriteLine($first)
    } elseif ($cnt -eq 2) {
        $writer.WriteLine($first)
        $writer.WriteLine($last)
    } else {
        $writer.WriteLine("[Repeated $cnt times]")
        $writer.WriteLine("  First: $first")
        $writer.WriteLine("  Last:  $last")
    }
}

$telemetry = [System.Collections.Generic.List[string]]::new()

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ([string]::IsNullOrWhiteSpace($line)) { continue }

    if ($line.Contains("SCRIPT ERROR") -or $line.Contains("Invalid get index") -or $line.Contains("Invalid call")) {
        if (-not $line.Contains("der_floh-performance_mod")) {
            $formatted = ("{0,4}: {1}" -f ($i + 1), $line)
            $key = if ($formatted -match '^\s*\d+:\s*(.*)$') { $Matches[1].Trim() } else { $formatted.Trim() }

            if ($null -ne $currentKey -and $key -eq $currentKey) {
                $lastLine = $formatted
                $count++
            } else {
                if ($count -gt 0) { Flush-Run -key $currentKey -first $firstLine -last $lastLine -cnt $count }
                $currentKey = $key
                $firstLine  = $formatted
                $lastLine   = $formatted
                $count      = 1
            }
        }
    }

    if ($line.Contains("[KnightSword]") -or $line.Contains("Auto choosing") -or $line.Contains("Transmutation")) {
        $telemetry.Add(("{0,4}: {1}" -f ($i + 1), $line))
    }
}

if ($count -gt 0) { Flush-Run -key $currentKey -first $firstLine -last $lastLine -cnt $count }

if ($telemetry.Count -gt 0) {
    $writer.WriteLine("Telemetry Highlights (Last 15):")
    $start = [Math]::Max(0, $telemetry.Count - 15)
    for ($t = $start; $t -lt $telemetry.Count; $t++) {
        $writer.WriteLine($telemetry[$t])
    }
}

$writer.Dispose()

Write-Host "Summarized telemetry automatically saved to: $conciseOut" -ForegroundColor Green
Get-Content $conciseOut | Select-Object -First 25 | ForEach-Object { Write-Host "  $_" }
