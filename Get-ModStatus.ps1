cls
$repoRoot = "C:\Dev\coal-llc-mods"
$appDataGodot = [System.IO.Path]::Combine($env:APPDATA, "Godot\app_userdata\Coal LLC")

Write-Host "=== GIT STATUS ===" -ForegroundColor Cyan
Push-Location $repoRoot
git status --short
Pop-Location

Write-Host "`n=== LAST 25 LINES OF GODOT.LOG ===" -ForegroundColor Cyan
$logPath = [System.IO.Path]::Combine($appDataGodot, "logs", "godot.log")
if (Test-Path $logPath) {
    Get-Content $logPath -Tail 25
}