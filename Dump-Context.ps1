cls
$repoRoot = "C:\Dev\coal-llc-mods"
$appDataGodot = [System.IO.Path]::Combine($env:APPDATA, "Godot\app_userdata\Coal LLC")
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

$logPath = [System.IO.Path]::Combine($appDataGodot, "logs\godot.log")
if (Test-Path $logPath) {
    $allLogLines = Get-Content $logPath
    
    # 1. Capture every error, crash, and warning across the whole session
    $errorLines = $allLogLines | Where-Object { 
        $_ -match "(SCRIPT ERROR|ERROR:|Compile Error|Parse Error|Failed to load script|Invalid call|Invalid access)" 
    }
    
    [void]$sb.AppendLine("`n=== SESSION ERRORS & WARNINGS ($($errorLines.Count) found) ===")
    if ($errorLines.Count -gt 0) {
        foreach ($line in ($errorLines | Select-Object -Last 30)) { [void]$sb.AppendLine($line) }
    } else {
        [void]$sb.AppendLine("None detected.")
    }

    # 2. Capture all log entries matching the mod currently being modified
    $activeModLines = $allLogLines | Where-Object {$_ -match "tectonic_faultline" }
    [void]$sb.AppendLine("`n=== ACTIVE MOD LOG ENTRIES ($($activeModLines.Count) found) ===")
    if ($activeModLines.Count -gt 0) {
        foreach ($line in ($activeModLines | Select-Object -Last 20)) { [void]$sb.AppendLine($line) }
    } else {
        [void]$sb.AppendLine("None detected.")
    }

    # 3. Trailing log context
    [void]$sb.AppendLine("`n=== LOG TAIL (LAST 30 LINES) ===")
    $tailLines =$allLogLines | Select-Object -Last 30
    foreach ($line in $tailLines) { [void]$sb.AppendLine($line) }
}

[System.IO.File]::WriteAllText($outputFile,$sb.ToString(), [System.Text.Encoding]::UTF8)
Set-Clipboard -Value $sb.ToString()
Write-Host "[+] Enhanced context collected in context.txt AND copied to clipboard!" -ForegroundColor Green
Write-Host "    Press Ctrl+V in the chat to share your project status." -ForegroundColor Yellow
