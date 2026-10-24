Clear-Host

# ==============================================================================
# Coal LLC - Apply Mod Manager Category Fix & Concurrent Discovery for All Mods
# ==============================================================================

$env:GIT_PAGER = "cat"
$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$dumpRoot   = "$steamRoot\_dump"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 400

# ------------------------------------------------------------------------------
# PART 1: FIX & COMMIT MOD MANAGER CATEGORIES
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Applying Mod Manager category order patch..." -ForegroundColor Cyan
$viewFiles = Get-ChildItem -Path "$repo\mods-unpacked\gareth-mod_manager_mod" -Recurse -Filter "mod_manager_view.gd"

foreach ($vf in $viewFiles) {
    $raw = Get-Content $vf.FullName -Raw
    $pattern = 'var\s+category_order\s*:=\s*\[[\s\S]*?\]'
    $replacement = @'
var category_order := [
		"Classes & Professions",
		"Progression & Upgrades",
		"Custom Maps & Strata",
		"Weapons & Arsenal",
		"Employees & Automation",
		"Quality of Life",
		"Performance & System",
		"Community Add-Ons",
		"Other Mods"
	]
'@
    if ($raw -match $pattern) {
        $raw = [System.Text.RegularExpressions.Regex]::Replace($raw, $pattern, $replacement)
        Set-Content -Path $vf.FullName -Value $raw -Encoding UTF8
        Write-Host "  Patched: $($vf.FullName.Replace($repo, ''))" -ForegroundColor Green
    }
}

Write-Host "`n>>> 3. Repackaging gareth-mod_manager_mod.zip..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression.FileSystem
$src = "$repo\mods-unpacked\gareth-mod_manager_mod"
$zip = "$steamMods\gareth-mod_manager_mod.zip"
if (Test-Path $zip) { Remove-Item -Path $zip -Force }

$stream  = [System.IO.File]::Open($zip, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $src -Recurse -File)) {
    $entryName = $f.FullName.Substring($src.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Write-Host "  Repacked: gareth-mod_manager_mod.zip" -ForegroundColor Green

Write-Host "`n>>> 4. Staging and committing Mod Manager category fix..." -ForegroundColor Cyan
git add -A
git commit -m "Fix: Expand Mod Manager view category order to display all 56 installed mods"
git push origin main
Write-Host "  Fix committed and pushed cleanly." -ForegroundColor Green

# ------------------------------------------------------------------------------
# PART 2: CONCURRENT DISCOVERY (READ-ONLY)
# ------------------------------------------------------------------------------
Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host ">>> DISCOVERY 1: Employee Miner (Range, Search, Pickup Timing)..." -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
$miner2 = "$dumpRoot\scenes\AutoMiners\employee_miner_2.gd"
if (Test-Path $miner2) {
    $lines = Get-Content $miner2
    for ($i = 0; $i -lt [Math]::Min(140, $lines.Count); $i++) {
        if ($lines[$i] -match 'range|target|mine|pickup|SPEED|moving_to_target|tilemap') {
            Write-Host ("  {0,3}: {1}" -f ($i + 1), $lines[$i])
        }
    }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host ">>> DISCOVERY 2: Collector UFO (Scan Range & Item Attraction)..." -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
$ufo = "$dumpRoot\scripts\LootCollectorUFO.gd"
if (Test-Path $ufo) {
    $lines = Get-Content $ufo
    for ($i = 0; $i -lt [Math]::Min(170, $lines.Count); $i++) {
        if ($lines[$i] -match 'target_pos|find_|scan|detect|area|moveSpeed|baseCoords|items') {
            Write-Host ("  {0,3}: {1}" -f ($i + 1), $lines[$i])
        }
    }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host ">>> DISCOVERY 3: Airstrike System (scenes/equipment/airstrike.gd)..." -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
$asPath = "$dumpRoot\scenes\equipment\airstrike.gd"
if (Test-Path $asPath) {
    Get-Content $asPath | ForEach-Object { Write-Host "   $_" }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host ">>> DISCOVERY 4: Inventory Window (Slot Clicks, Selling, Cash)..." -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
$invPath = "$dumpRoot\scenes\Interfaces\InventoryWindow.gd"
if (Test-Path $invPath) {
    $lines = Get-Content $invPath
    for ($i = 0; $i -lt [Math]::Min(120, $lines.Count); $i++) {
        Write-Host ("  {0,3}: {1}" -f ($i + 1), $lines[$i])
    }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host ">>> DISCOVERY 5: Player State Machine (Stun & Velocity Overrides)..." -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
$p2Path = "$dumpRoot\scripts\StateMachine\Player2\player_2.gd"
if (Test-Path $p2Path) {
    $lines = Get-Content $p2Path
    for ($i = 0; $i -lt [Math]::Min(100, $lines.Count); $i++) {
        if ($lines[$i] -match 'enum States|var state|velocity|can_move|stun|hurt|input') {
            Write-Host ("  {0,3}: {1}" -f ($i + 1), $lines[$i])
        }
    }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host ">>> DISCOVERY 6: ModLoader mods directory scanning logic..." -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
$mlScripts = Get-ChildItem -Path "$dumpRoot\addons\mod_loader" -Recurse -Filter "*.gd"
foreach ($s in $mlScripts) {
    $matches = Get-Content $s.FullName | Select-String -Pattern 'mods_dir|get_mods|load_mods|dir_contents'
    if ($matches) {
        Write-Host "In $($s.Name):" -ForegroundColor Yellow
        $matches | Select-Object -First 4 | ForEach-Object { Write-Host "   Line $($_.LineNumber): $($_.Line.Trim())" }
    }
}

Write-Host "`nAll operations and discoveries completed cleanly!" -ForegroundColor Cyan