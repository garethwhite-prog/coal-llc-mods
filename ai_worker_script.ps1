# ==============================================================================
# Coal LLC - Discovery Phase 57: Stockpile Crash, Vanilla Shop, & HUD Bounds
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$dumpRoot   = "$steamRoot\_dump"

Set-Location $repo

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ">>> 1. Inspecting Stockpile.gd around line 59 in _dump..." -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
$sp = "$dumpRoot\scripts\Stockpile.gd"
if (Test-Path $sp) {
    $lines = Get-Content $sp
    for ($i = [Math]::Max(0, 45); $i -lt [Math]::Min($lines.Count, 75); $i++) {
        Write-Host ("  {0,3}: {1}" -f ($i + 1), $lines[$i])
    }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host ">>> 2. Inspecting vanilla AddToInventory.gd in _dump..." -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
$ati = "$dumpRoot\resources\BuyEffects\Scripts\AddToInventory.gd"
if (Test-Path $ati) {
    Get-Content $ati | ForEach-Object { Write-Host "   $_" }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host ">>> 3. Inspecting vanilla End Day button layout in MineRegion or in_game HUD..." -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Get-ChildItem -Path "$dumpRoot" -Recurse -Include "*MineRegion*.tscn", "*in_game*.tscn", "*hud*.tscn" | ForEach-Object {
    $matches = Get-Content $_.FullName | Select-String -Pattern 'EndDay|end_day|Speed|button' -Context 0,4
    if ($matches) {
        Write-Host "File: $($_.Name)" -ForegroundColor Yellow
        $matches | ForEach-Object { Write-Host "   $_" }
    }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host ">>> 4. Inspecting Collector Priority settings hook implementation..." -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
$cp = Get-ChildItem -Path "$repo\mods-unpacked\gareth-collector_priority_mod" -Recurse -Filter "*.gd"
foreach ($f in $cp) {
    Write-Host "Script: $($f.Name)" -ForegroundColor Yellow
    Get-Content $f.FullName | Select-String -Pattern 'func _ready|priority|settings|ore' -Context 0,4 | ForEach-Object {
        Write-Host "   $_"
    }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host ">>> 5. Inspecting level_select.hooks.gd across custom maps 101-105..." -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Get-ChildItem -Path "$repo\mods-unpacked" -Recurse -Filter "*level_select*.gd" | ForEach-Object {
    Write-Host "File: $($_.FullName.Replace($repo, ''))" -ForegroundColor Green
    Get-Content $_.FullName | Select-String -Pattern 'LEVEL_ORDER|append|register|trench|canvas|diagonal' -Context 0,3 | ForEach-Object {
        Write-Host "   $_"
    }
}

Write-Host "`nDiscovery Phase 57 complete. Zero files modified." -ForegroundColor Cyan