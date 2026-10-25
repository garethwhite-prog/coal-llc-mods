Clear-Host

$scriptPath = "C:\Dev\coal-llc-mods\ai_worker_script.ps1"
$outputPath = "C:\Dev\coal-llc-mods\output.txt"

if (-not (Test-Path $scriptPath)) {
    Write-Error "ai_worker_script.ps1 not found at $scriptPath"
    exit 1
}

# Pre-load both required .NET compression assemblies
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

Write-Host ">>> Executing ai_worker_script.ps1 and streaming to output.txt..." -ForegroundColor Cyan

# Execute in-process and tee output stream to output.txt automatically
& $scriptPath *>&1 | Tee-Object -FilePath $outputPath

Write-Host "`n>>> Done! Output automatically captured in output.txt" -ForegroundColor Green