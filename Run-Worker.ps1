# Executes ai_worker_script.ps1, displays live output, and auto-saves to output.txt
$scriptPath = "C:\Dev\coal-llc-mods\ai_worker_script.ps1"
$outputPath = "C:\Dev\coal-llc-mods\output.txt"

if (-not (Test-Path $scriptPath)) {
    Write-Error "ai_worker_script.ps1 not found!"
    exit 1
}

Write-Host ">>> Executing ai_worker_script.ps1 and capturing to output.txt..." -ForegroundColor Cyan
& powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath *>&1 | Tee-Object -FilePath $outputPath
Write-Host "`nExecution finished. Output automatically written to output.txt" -ForegroundColor Green
