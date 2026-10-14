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

[void]$sb.AppendLine("`n=== ENGINE LOG (LAST 50 LINES) ===")
$logPath = [System.IO.Path]::Combine($appDataGodot, "logs\godot.log")
if (Test-Path $logPath) {
    $logTail = Get-Content $logPath -Tail 50
    foreach ($line in $logTail) { [void]$sb.AppendLine($line) }
}

[System.IO.File]::WriteAllText($outputFile, $sb.ToString(), [System.Text.Encoding]::UTF8)
Set-Clipboard -Value $sb.ToString()
Write-Host "[+] Context collected in context.txt AND copied to clipboard!" -ForegroundColor Green
Write-Host "    Press Ctrl+V in the chat to share your project status." -ForegroundColor Yellow