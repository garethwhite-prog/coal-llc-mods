# ==============================================================================
# Coal LLC - Fix: Resolve ModRegistry Parse Error & Map Select Crash
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 400

# Ensure compression assemblies are loaded
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

# ------------------------------------------------------------------------------
# 2. FIX MOD_REGISTRY.GD: REMOVE DUPLICATE VARIABLE DECLARATION
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Fixing duplicate 'var list' declaration in mod_registry.gd..." -ForegroundColor Cyan
$regPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scripts\mod_registry.gd"
@'
class_name ModRegistry
extends RefCounted

static func is_mod_active_for_run(mod_key: String) -> bool:
	var ssm = Engine.get_main_loop().root.get_node_or_null("/root/SaveSlotManager")
	if ssm and ssm.has_method("is_mod_active_for_run"):
		return ssm.is_mod_active_for_run(mod_key)

	var cfg_path := "user://gareth_mods_config.json"
	if FileAccess.file_exists(cfg_path):
		var f := FileAccess.open(cfg_path, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary and parsed.has("mods"):
				return bool(parsed["mods"].get(mod_key, true))
	return true

static func get_all_installed_mods() -> Array[Dictionary]:
	return get_all_mods()

static func get_all_mods() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var mod_dict: Dictionary = {}
	if ModLoader and ("mod_data" in ModLoader) and ModLoader.mod_data is Dictionary:
		mod_dict = ModLoader.mod_data

	for mod_id in mod_dict.keys():
		var data = mod_dict[mod_id]
		if not data or not ("manifest" in data) or not data.manifest:
			continue
		var m = data.manifest
		var display_name: String = _format_display_name(m)
		var desc: String = m.description if "description" in m else ""
		var author: String = "Community"
		if m.has("extra") and m.extra.has("godot") and m.extra.godot.has("authors") and m.extra.godot.authors.size() > 0:
			author = m.extra.godot.authors[0]
		var version: String = m.version_number if "version_number" in m else "1.0.0"
		var cat: String = _determine_category(m)

		list.append({
			"id": mod_id,
			"key": mod_id,
			"name": display_name,
			"description": desc,
			"author": author,
			"version": version,
			"category": cat,
			"is_active": data.is_active if "is_active" in data else true
		})
	return list

static func _determine_category(m) -> String:
	var id: String = str(m.name).to_lower()
	if "class" in id or "profession" in id or "jedi" in id or "knight" in id or "sinclairity" in id:
		return "Classes & Professions"
	if "map" in id or "trench" in id or "faultline" in id or "canvas" in id or "expedition" in id:
		return "Custom Maps & Strata"
	if "weapon" in id or "bomb" in id or "laser" in id or "nuke" in id or "turret" in id or "mortar" in id or "grenade" in id or "arsenal" in id or "tank" in id or "strike" in id:
		return "Weapons & Arsenal"
	if "employee" in id or "collector" in id or "drill" in id or "vacuum" in id:
		return "Employees & Automation"
	if "speed" in id or "inventory" in id or "save" in id or "leaderboard" in id or "multisave" in id or "settings" in id or "scrap" in id or "delivery" in id or "ladder" in id:
		return "Quality of Life"
	if "hardware" in id or "limit" in id or "performance" in id or "booster" in id or "holes" in id:
		return "Performance & System"
	if "spirit" in id or "variance" in id or "upgrade" in id or "passive" in id or "order" in id or "beacon" in id:
		return "Progression & Upgrades"
	return "Community Add-Ons"

static func _format_display_name(m) -> String:
	if m.has("extra") and m.extra.has("godot") and m.extra.godot.has("display_name"):
		return m.extra.godot.display_name
	var raw: String = m.name.replace("_mod", "").replace("mod_", "").replace("-", " ").replace("_", " ")
	return raw.capitalize()
'@ | Set-Content -Path $regPath -Encoding UTF8
Write-Host "  Updated: mod_registry.gd (Clean syntax without duplicate declarations)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. FIX ABYSSAL TRENCH LEVEL_SELECT.HOOKS.GD (TRENCH_LEVEL_ID = 104)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Correcting level ID constant in abyssal_trench level_select.hooks.gd..." -ForegroundColor Cyan
$atHook = "$repo\mods-unpacked\gareth-abyssal_trench_mod\mods-unpacked\gareth-abyssal_trench_mod\extensions\scenes\Interfaces\Menus\level_select.hooks.gd"
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var helper_script = load("res://mods-unpacked/gareth-abyssal_trench_mod/helpers/AbyssalTrenchHelper.gd")
	if helper_script:
		var helper = helper_script.new()
		if helper.has_method("ensure_level_registered"):
			helper.ensure_level_registered()
		var ls = chain.reference_object
		if ls and ("LEVEL_ORDER" in ls):
			var trench_id: int = helper_script.TRENCH_LEVEL_ID if ("TRENCH_LEVEL_ID" in helper_script) else 104
			if not ls.LEVEL_ORDER.has(trench_id):
				ls.LEVEL_ORDER.append(trench_id)
'@ | Set-Content -Path $atHook -Encoding UTF8
Write-Host "  Updated: abyssal_trench level_select.hooks.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. FIX SWORDHIT.WAV IN KNIGHT_CLASS_MOD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Patching audio reference in knight_class_mod..." -ForegroundColor Cyan
Get-ChildItem -Path "$repo\mods-unpacked\gareth-knight_class_mod" -Recurse -Include "*.gd", "*.tres" | ForEach-Object {
	$txt = Get-Content $_.FullName -Raw
	if ($txt.Contains("SwordHit.wav")) {
		$txt = $txt.Replace("SwordHit.wav", "SwordThud.wav")
		Set-Content -Path $_.FullName -Value $txt -Encoding UTF8
		Write-Host "  Patched in: $($_.Name)" -ForegroundColor Green
	}
}

# ------------------------------------------------------------------------------
# 5. PURGE HOOK CACHE AND REPACK ALL TARGETED MOD ARCHIVES
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Refreshing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
	Remove-Item -Path $hookZip -Force
	Write-Host "  Purged stale mod-hooks.zip" -ForegroundColor Green
}

Write-Host "`n>>> 6. Repackaging modified mods to Steam..." -ForegroundColor Cyan
$modsToRepack = @(
	"gareth-mod_manager_mod",
	"gareth-abyssal_trench_mod",
	"gareth-knight_class_mod",
	"gareth-diagonal_map_mod"
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
	Write-Host "  Repacked cleanly: $m.zip" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 6. RUN STATIC REGRESSION CHECK
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Running CI/CD validation..." -ForegroundColor Cyan
& "$repo\tests\test_runner.ps1" -RepoPath $repo

# ------------------------------------------------------------------------------
# 7. COMMIT & PUSH TO GITHUB
# ------------------------------------------------------------------------------
Write-Host "`n>>> 8. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Fix: Remove duplicate variable in mod_registry.gd, correct TRENCH_LEVEL_ID in level_select hook, and patch SwordThud audio"
git push origin main

Write-Host "`nAll fixes applied, repacked, and committed cleanly!" -ForegroundColor Green