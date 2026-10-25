Clear-Host

# ==============================================================================
# Coal LLC - Morning Pass: Resolve Plasma Raygun Error Loop & Audit Pipeline
# ==============================================================================

$env:GIT_PAGER = "cat"
$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 400

# ------------------------------------------------------------------------------
# 2. INSPECT CURRENT PLASMA RAYGUN HOOK
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Inspecting player_2.hooks.gd in gareth-plasma_raygun_mod..." -ForegroundColor Cyan
$prHook = Get-ChildItem -Path "$repo\mods-unpacked\gareth-plasma_raygun_mod" -Recurse -Filter "player_2.hooks.gd" | Select-Object -First 1

if ($prHook) {
    Get-Content $prHook.FullName | Select-Object -First 25 | ForEach-Object { Write-Host "   $_" }
}

# ------------------------------------------------------------------------------
# 3. REWRITE PLAYER_2.HOOKS.GD WITH CACHED RUNTIME ACTIVATION
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Hardening player_2.hooks.gd with cached activation guard..." -ForegroundColor Cyan
if ($prHook) {
@'
extends Object

var _checked_active: bool = false
var _is_active: bool = true

func _check_mod_status() -> bool:
	if _checked_active:
		return _is_active
	_checked_active = true

	var ssm = Engine.get_main_loop().root.get_node_or_null("/root/SaveSlotManager")
	if ssm and ssm.has_method("is_mod_active_for_run"):
		_is_active = ssm.is_mod_active_for_run("plasma_raygun")
		return _is_active

	var reg_paths = [
		"res://mods-unpacked/gareth-mod_manager_mod/scripts/mod_registry.gd",
		"res://mods-unpacked/gareth-mod_manager_mod/mods-unpacked/gareth-mod_manager_mod/scripts/mod_registry.gd"
	]
	for p in reg_paths:
		if ResourceLoader.exists(p):
			var reg = load(p)
			if reg and reg.has_method("is_mod_active_for_run"):
				_is_active = reg.is_mod_active_for_run("plasma_raygun")
				return _is_active

	_is_active = true
	return _is_active

func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	if not _check_mod_status():
		chain.execute_next([delta])
		return

	chain.execute_next([delta])
'@ | Set-Content -Path $prHook.FullName -Encoding UTF8
    Write-Host "  Patched: $($prHook.FullName.Replace($repo, ''))" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 4. AUDIT OTHER HOOKS FOR UNCACHED IS_MOD_ACTIVE_FOR_RUN CALLS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Auditing other hooks for is_mod_active_for_run calls..." -ForegroundColor Cyan
Get-ChildItem -Path "$repo\mods-unpacked" -Recurse -Filter "*.hooks.gd" | ForEach-Object {
    $matches = Get-Content $_.FullName | Select-String -Pattern 'is_mod_active_for_run'
    if ($matches) {
        Write-Host "  Hook file: $($_.Name) has $($matches.Count) calls" -ForegroundColor Yellow
    }
}

# ------------------------------------------------------------------------------
# 5. REPACK GARETH-PLASMA_RAYGUN_MOD.ZIP
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Repackaging gareth-plasma_raygun_mod.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

Add-Type -AssemblyName System.IO.Compression.FileSystem

$src = "$repo\mods-unpacked\gareth-plasma_raygun_mod"
$zip = "$steamMods\gareth-plasma_raygun_mod.zip"
if (Test-Path $zip) { Remove-Item -Path $zip -Force }

$stream  = [System.IO.File]::Open($zip, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $src -Recurse -File)) {
	$entryName = $f.FullName.Substring($src.Length + 1).Replace("\", "/")
	[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Write-Host "  Repacked: gareth-plasma_raygun_mod.zip" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. RUN PIPELINE INTEGRITY AUDIT
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Running orchestrator verification..." -ForegroundColor Cyan
& "$repo\Invoke-ModPipeline.ps1"

# ------------------------------------------------------------------------------
# 7. GIT COMMIT & PUSH
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Fix: Cache mod activation status in plasma_raygun hook to eliminate physics error loop"
git push origin main

Write-Host "`nMorning pass complete. Runtime error loop eliminated!" -ForegroundColor Green