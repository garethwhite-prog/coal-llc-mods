Clear-Host

# ==============================================================================
# Coal LLC - Pure Read-Only Discovery Phase 15 (ZERO WRITES, ZERO COMMITS)
# ==============================================================================

$repo      = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$dumpRoot  = "$steamRoot\_dump"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ">>> 1. Retrieving initial Vacuum Depot implementation from Git history..." -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Set-Location $repo
$vdCommits = git log --oneline -- "mods-unpacked/gareth-vacuum_depot_mod"
Write-Host "Commits affecting vacuum_depot_mod:" -ForegroundColor Yellow
$vdCommits | Select-Object -First 5 | ForEach-Object { Write-Host "   $_" }
$firstVdCommit = ($vdCommits | Select-Object -Last 1).Split(" ")[0]
if ($firstVdCommit) {
    Write-Host "`nFull original LootCollectorUFO.hooks.gd from commit $firstVdCommit :" -ForegroundColor Green
    git show "${firstVdCommit}:mods-unpacked/gareth-vacuum_depot_mod/mods-unpacked/gareth-vacuum_depot_mod/extensions/scripts/LootCollectorUFO.hooks.gd"
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host ">>> 2. Inspecting management_screen.gd Passive Effects panel (lines 200 to 320)..." -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
$mgmtPath = "$dumpRoot\scenes\Stages\management_screen.gd"
if (Test-Path $mgmtPath) {
    $mLines = Get-Content $mgmtPath
    $start = [Math]::Max(0, 200)
    $end   = [Math]::Min($mLines.Count - 1, 330)
    for ($i = $start; $i -le $end; $i++) {
        Write-Host ("{0,3}: {1}" -f ($i + 1), $mLines[$i])
    }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host ">>> 3. Inspecting profession saving/loading in Gvars.gd (lines 380 to 450)..." -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
$gvarsPath = "$dumpRoot\scripts\Gvars.gd"
if (Test-Path $gvarsPath) {
    $gLines = Get-Content $gvarsPath
    $startG = [Math]::Max(0, 375)
    $endG   = [Math]::Min($gLines.Count - 1, 445)
    for ($i = $startG; $i -le $endG; $i++) {
        Write-Host ("{0,3}: {1}" -f ($i + 1), $gLines[$i])
    }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host ">>> 4. Inspecting Equipment panel layout in management_screen.tscn..." -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
$mgmtTscn = "$dumpRoot\scenes\Stages\management_screen.tscn"
if (Test-Path $mgmtTscn) {
    $tLines = Get-Content $mgmtTscn
    for ($i = 0; $i -lt $tLines.Count; $i++) {
        if ($tLines[$i] -match 'name="EquipmentItems"|name="Equipment"|name="PurchasedEquipment"|name="Bonus"') {
            $s = [Math]::Max(0, $i - 1)
            $e = [Math]::Min($tLines.Count - 1, $i + 10)
            for ($k = $s; $k -le $e; $k++) {
                Write-Host ("   {0,3}: {1}" -f ($k + 1), $tLines[$k])
            }
            Write-Host "   ---"
        }
    }
}

Write-Host "`nDiscovery Phase 15 complete. Zero files modified." -ForegroundColor Cyan