# ==============================================================================
# Coal LLC - Stabilization Pass: Fix Unregistered "fire" Action & Turret Inference
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 400

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

# ------------------------------------------------------------------------------
# 2. FIX UNREGISTERED "fire" ACTION ACROSS ALL 4 EQUIP SCRIPTS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Replacing unregistered 'fire' with 'rightMouseClick'..." -ForegroundColor Cyan

# 2a. Airstrike Equip Effect
$aee = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\airstrike_equip_effect.gd"
if (Test-Path $aee) {
	$code = Get-Content $aee -Raw
	$code = $code.Replace('Input.is_action_just_pressed("fire")', 'Input.is_action_just_pressed("rightMouseClick")')
	Set-Content -Path $aee -Value $code -Encoding UTF8
	Write-Host "  Patched: airstrike_equip_effect.gd" -ForegroundColor Green
}

# 2b. Laser Equip Effect
$lee = "$repo\mods-unpacked\gareth-laser_beam_mod\mods-unpacked\gareth-laser_beam_mod\scripts\laser_equip_effect.gd"
if (Test-Path $lee) {
	$code = Get-Content $lee -Raw
	$code = $code.Replace('Input.is_action_pressed("fire")', 'Input.is_action_pressed("rightMouseClick")')
	Set-Content -Path $lee -Value $code -Encoding UTF8
	Write-Host "  Patched: laser_equip_effect.gd" -ForegroundColor Green
}

# 2c. Heavy Turret Equip
$hte = "$repo\mods-unpacked\gareth-heavy_turrets_mod\mods-unpacked\gareth-heavy_turrets_mod\scripts\heavy_turret_equip.gd"
if (Test-Path $hte) {
	$code = Get-Content $hte -Raw
	$code = $code.Replace('Input.is_action_just_pressed("fire")', 'Input.is_action_just_pressed("rightMouseClick")')
	Set-Content -Path $hte -Value $code -Encoding UTF8
	Write-Host "  Patched: heavy_turret_equip.gd" -ForegroundColor Green
}

# 2d. Void Siphon Equip (Across both unpacked locations)
Get-ChildItem -Path "$repo\mods-unpacked" -Recurse -Filter "void_siphon_equip.gd" | ForEach-Object {
	$code = Get-Content $_.FullName -Raw
	if ($code.Contains('"fire"')) {
		$code = $code.Replace('Input.is_action_just_pressed("fire")', 'Input.is_action_just_pressed("rightMouseClick")')
		Set-Content -Path $_.FullName -Value $code -Encoding UTF8
		Write-Host "  Patched: $($_.FullName.Replace($repo, ''))" -ForegroundColor Green
	}
}

# ------------------------------------------------------------------------------
# 3. FIX HEAVY_TURRET_ENTITY.GD WALRUS TYPE INFERENCE
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Fixing static type inference in heavy_turret_entity.gd..." -ForegroundColor Cyan
$ht = "$repo\mods-unpacked\gareth-heavy_turrets_mod\mods-unpacked\gareth-heavy_turrets_mod\scripts\heavy_turret_entity.gd"
if (Test-Path $ht) {
	$code = Get-Content $ht -Raw
	$code = $code.Replace('var center := tilemap.local_to_map(global_position)', 'var center: Vector2i = tilemap.local_to_map(global_position)')
	$code = $code.Replace('var check_pos := center + Vector2i(dx, dy)', 'var check_pos: Vector2i = center + Vector2i(dx, dy)')
	$code = $code.Replace('var target_world := tilemap.map_to_local(best_target)', 'var target_world: Vector2 = tilemap.map_to_local(best_target)')
	Set-Content -Path $ht -Value $code -Encoding UTF8
	Write-Host "  Patched: heavy_turret_entity.gd (clean compile guaranteed)" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 4. REPACK ONLY THE 4 AFFECTED MODS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Repackaging strictly targeted mods to Steam..." -ForegroundColor Cyan
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

$modsToRepack = @(
	"gareth-elemental_airstrikes_mod",
	"gareth-laser_beam_mod",
	"gareth-heavy_turrets_mod",
	"gareth-custom_classes_mod",
	"gareth-void_siphon_mod"
)

foreach ($m in $modsToRepack) {
	$src = "$repo\mods-unpacked\$m"
	$zip = "$steamMods\$m.zip"

	if (-not (Test-Path $src)) { continue }
	if (Test-Path $zip) { Remove-Item -Path $zip -Force }

	$stream  = [System.IO.File]::Open($zip, [System.IO.FileMode]::CreateNew)
	$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
	foreach ($f in (Get-ChildItem -Path $src -Recurse -File)) {
		$entryName = $f.FullName.Substring($src.Length + 1).Replace("\", "/")
		[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
	}
	$archive.Dispose()
	$stream.Dispose()
	Write-Host "  Repacked: $m.zip" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 5. COMMIT AND RUN AUDIT
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Targeted Fix: Replace unregistered 'fire' action with 'rightMouseClick' and fix heavy_turret static inference"
git push origin main

Write-Host "`n>>> 6. Running ModSuite log auditor..." -ForegroundColor Cyan
& "$repo\Run-ModSuiteTest.ps1"

Write-Host "`nStabilization pass complete!" -ForegroundColor Green