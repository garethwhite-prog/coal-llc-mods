Clear-Host

$repoRoot = "C:\Dev\coal-llc-mods"
$appDataGodot = [System.IO.Path]::Combine($env:APPDATA, "Godot\app_userdata\Coal LLC")
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$outputFile = [System.IO.Path]::Combine($repoRoot, "context.txt")

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("=== GIT STATUS ===")
Push-Location $repoRoot
$gitStatus = git status --short
foreach ($line in $gitStatus) { [void]$sb.AppendLine($line) }

[void]$sb.AppendLine("`n=== RECENT COMMITS ===")
$gitLog = git log -n 3 --oneline
foreach ($line in $gitLog) { [void]$sb.AppendLine($line) }
Pop-Location

# 1. Capture ModLoader.log
$mlLog = [System.IO.Path]::Combine($steamRoot, "modloader.log")
if (Test-Path $mlLog) {
    $mlLines = Get-Content $mlLog
    $mlErrors = $mlLines | Where-Object { $_ -match "(ERROR|CRITICAL|failed|cannot be loaded)" }
    [void]$sb.AppendLine("`n=== MODLOADER LOG AUDIT ($($mlErrors.Count) errors found) ===")
    if ($mlErrors.Count -gt 0) {
        foreach ($line in ($mlErrors | Select-Object -Last 15)) { [void]$sb.AppendLine($line) }
    } else {
        [void]$sb.AppendLine("All active mods verified by ModLoader cleanly.")
    }
}

# 2. Capture godot.log
$logPath = [System.IO.Path]::Combine($appDataGodot, "logs\godot.log")
if (Test-Path $logPath) {
    # Open with FileShare.ReadWrite to avoid locking collisions
    $stream = [System.IO.FileStream]::new($logPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::UTF8)
    $allLogLines = [System.Collections.Generic.List[string]]::new()
    while (-not $reader.EndOfStream) { $allLogLines.Add($reader.ReadLine()) }
    $reader.Dispose()
    $stream.Dispose()

    $errorLines = $allLogLines | Where-Object {
        $_ -match "(SCRIPT ERROR|ERROR:|Compile Error|Parse Error|Failed to load script|Invalid call|Invalid access)"
    }

    [void]$sb.AppendLine("`n=== SESSION ERRORS & WARNINGS ($($errorLines.Count) found) ===")
    if ($errorLines.Count -gt 0) {
        foreach ($line in ($errorLines | Select-Object -Last 25)) { [void]$sb.AppendLine($line) }
    } else {
        [void]$sb.AppendLine("None detected.")
    }

    [void]$sb.AppendLine("`n=== LOG TAIL (LAST 25 LINES) ===")
    $tailLines = $allLogLines | Select-Object -Last 25
    foreach ($line in $tailLines) { [void]$sb.AppendLine($line) }
}

[System.IO.File]::WriteAllText($outputFile, $sb.ToString(), [System.Text.Encoding]::UTF8)
Set-Clipboard -Value $sb.ToString()
Write-Host "Context written to context.txt and copied to clipboard." -ForegroundColor Green
