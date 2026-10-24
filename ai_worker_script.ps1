Clear-Host

# ==============================================================================
# Coal LLC - Part 1: Core Stability & Save Game Fixes
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot instances..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 600

# ------------------------------------------------------------------------------
# 2. FIX VACUUM DEPOT: RESTORE DUAL UFO HOOKS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Updating vacuum_depot LootCollectorUFO.hooks.gd..." -ForegroundColor Cyan
$vdHookPath = "$repo\mods-unpacked\gareth-vacuum_depot_mod\mods-unpacked\gareth-vacuum_depot_mod\extensions\scripts\LootCollectorUFO.hooks.gd"
@'
extends Object

const DEFAULT_BASE := Vector2(50.0, -55.0)

func check_inventory_count(chain: ModLoaderHookChain) -> void:
	var ufo = chain.reference_object
	if not is_instance_valid(ufo) or not ("inventory" in ufo) or not ("maxInventoryCount" in ufo):
		chain.execute_next([])
		return

	if "StateLabel" in ufo and is_instance_valid(ufo.StateLabel):
		ufo.StateLabel.text = Gconsts.add_comma_to_float_no_dp(ufo.maxInventoryCount)

	var capacity_mult: float = 1.0
	if Gvars and ("passives" in Gvars) and Gvars.passives:
		capacity_mult += Gvars.passives.employee_collector_capacity

	var max_cap: float = float(ufo.maxInventoryCount) * capacity_mult
	if float(ufo.inventory.inventoryCount) >= max_cap:
		ufo.set_deferred("monitorable", false)
		if "States" in ufo and ("RETURNING_TO_BASE" in ufo.States):
			ufo.state = ufo.States.RETURNING_TO_BASE
		if "baseCoords" in ufo and "models" in ufo and is_instance_valid(ufo.models):
			if ufo.baseCoords.x < ufo.global_position.x:
				ufo.models.scale.x = -1
			else:
				ufo.models.scale.x = 1

func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	var ufo = chain.reference_object
	if not is_instance_valid(ufo):
		chain.execute_next([delta])
		return

	# State 2: States.RETURNING_TO_BASE
	if ufo.state == 2:
		var tree = ufo.get_tree()
		if tree:
			var target_dest := DEFAULT_BASE
			var vacs = tree.get_nodes_in_group("vacuum_cleaner")
			if vacs.size() > 0:
				var vac = vacs[0]
				if is_instance_valid(vac) and ("suck_end_physics_body" in vac) and vac.suck_end_physics_body:
					var nozzle_pos: Vector2 = vac.suck_end_physics_body.global_position
					var dist_to_base: float = ufo.global_position.distance_squared_to(DEFAULT_BASE)
					var dist_to_vac: float = ufo.global_position.distance_squared_to(nozzle_pos)
					if dist_to_vac < dist_to_base:
						target_dest = nozzle_pos

			if target_dest != DEFAULT_BASE:
				ufo.baseCoords = target_dest
				if ufo.global_position.distance_to(target_dest) <= 24.0:
					ufo.drop_off_in_stockpile()
					ufo.global_position = target_dest
					if "timer" in ufo and ufo.timer:
						ufo.timer.start(0.066)
					ufo.state = 3 # States.IDLE
					return
				else:
					var spd: float = ufo.moveSpeed * min(8.0, (1.0 + Gvars.passives.employee_collector_speed))
					ufo.movement_vector = (target_dest - ufo.global_position).normalized() * spd
					ufo.pass_point_positive = (target_dest.x - ufo.global_position.x) > 0
					ufo.y_pass_point_positive = (target_dest.y - ufo.global_position.y) > 0
					if "models" in ufo and is_instance_valid(ufo.models):
						if target_dest.x < ufo.global_position.x:
							ufo.models.scale.x = -1
						else:
							ufo.models.scale.x = 1
			else:
				ufo.baseCoords = DEFAULT_BASE
	elif ufo.state != 2 and ufo.baseCoords != DEFAULT_BASE:
		ufo.baseCoords = DEFAULT_BASE

	chain.execute_next([delta])
'@ | Set-Content -Path $vdHookPath -Encoding UTF8
Write-Host "  Updated: LootCollectorUFO.hooks.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. FIX SAVE/LOAD: PERSIST CUSTOM PROFESSIONS (KNIGHT 101, JEDI 102)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Installing custom profession serializer in mod_manager Gvars.hooks.gd..." -ForegroundColor Cyan
$gvarsHookPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scripts\Gvars.hooks.gd"
@'
extends Object

func save_Gvars(chain: ModLoaderHookChain) -> Dictionary:
	var result: Dictionary = chain.execute_next([])
	if not result.has("Gvars"):
		result["Gvars"] = {}

	var g = chain.reference_object
	if g and ("profession" in g) and g.profession and ("profession_manager" in g) and g.profession_manager:
		var pm = g.profession_manager
		for p_id in pm.all_professions.keys():
			if pm.all_professions[p_id]["profession"] == g.profession:
				result["Gvars"]["profession"] = p_id
				break
	return result

func load_Gvars(chain: ModLoaderHookChain, save: Dictionary) -> void:
	chain.execute_next([save])
	var g = chain.reference_object
	if not g or not save.has("Gvars") or not save["Gvars"].has("profession"):
		return

	var saved_id: int = int(save["Gvars"]["profession"])
	if ("profession_manager" in g) and g.profession_manager:
		var pm = g.profession_manager
		if pm.all_professions.has(saved_id):
			g.profession = pm.all_professions[saved_id]["profession"]
'@ | Set-Content -Path $gvarsHookPath -Encoding UTF8
Write-Host "  Updated: Gvars.hooks.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. PURGE HOOK CACHE & REPACK AFFECTED MODS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Purging mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
	Remove-Item -Path $hookZip -Force
	Write-Host "  Removed: $hookZip" -ForegroundColor Green
}

Write-Host "`n>>> 5. Repackaging modified mods..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$modsToRepack = @(
	"gareth-vacuum_depot_mod",
	"gareth-mod_manager_mod"
)

foreach ($m in $modsToRepack) {
	$src = "$repo\mods-unpacked\$m"
	$zip = "$steamMods\$m.zip"
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
# 6. GIT STAGING, COMMIT & PUSH
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Staging, committing and pushing Part 1 to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Part 1: Fix custom profession save serialization and restore vacuum depot UFO redirection"
git push origin main

Write-Host "`nPart 1 deployment complete!" -ForegroundColor Green