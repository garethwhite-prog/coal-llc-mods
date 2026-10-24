param (
    [switch]$RunTests = $true,
    [switch]$LaunchGame = $false
)

Clear-Host
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "             COAL LLC MOD PLATFORM 2.0 ORCHESTRATOR              " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

$repo = "C:\Dev\coal-llc-mods"
$steamMods = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mods"
$steamRepo = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mods_repository"
$godotLog  = "$env:APPDATA\Godot\app_userdata\Coal LLC\logs\godot.log"

# 1. GIT STATUS & HEAD COMMIT
Write-Host "`n>>> 1. REPOSITORY STATE" -ForegroundColor Yellow
Set-Location $repo
$head = git log -1 --oneline
Write-Host "  HEAD Commit: $head" -ForegroundColor Green
$status = git status --short
if ($status) {
    Write-Host "  Modified Files:`n$status" -ForegroundColor Magenta
} else {
    Write-Host "  Working tree clean." -ForegroundColor Green
}

# 2. STAGING & DECOUPLED STORAGE
Write-Host "`n>>> 2. STAGING DIRECTORY STATUS" -ForegroundColor Yellow
$activeZips = (Get-ChildItem -Path $steamMods -Filter "*.zip" -ErrorAction SilentlyContinue).Count
$vaultZips  = (Get-ChildItem -Path $steamRepo -Filter "*.zip" -ErrorAction SilentlyContinue).Count
Write-Host "  Active Mods (Coal LLC/mods):            $activeZips archives" -ForegroundColor Green
Write-Host "  Master Catalog (Coal LLC/mods_repo):   $vaultZips archives" -ForegroundColor Green

# 3. AUTOMATED TEST RUNNER
if ($RunTests) {
    Write-Host "`n>>> 3. RUNNING REGRESSION & CI/CD CHECKS" -ForegroundColor Yellow
    & "$repo\tests\test_runner.ps1" -RepoPath $repo
}

# 4. RUNTIME LOG FORENSICS
if (Test-Path $godotLog) {
    Write-Host "`n>>> 4. RUNTIME LOG AUDIT (LAST 5 ERRORS/WARNINGS)" -ForegroundColor Yellow
    $logLines = Get-Content $godotLog
    $errs = $logLines | Select-String -Pattern 'SCRIPT ERROR|ERROR:' | Select-Object -Last 5
    if ($errs) {
        foreach ($e in $errs) { Write-Host "  $($e.Line.Trim())" -ForegroundColor Red }
    } else {
        Write-Host "  Zero errors found in latest runtime log!" -ForegroundColor Green
    }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "Pipeline check complete. Ready for development or gameplay." -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

if ($LaunchGame) {
    Write-Host "`nLaunching Coal LLC..." -ForegroundColor Green
    Start-Process -FilePath "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\Coal LLC.exe"
}
