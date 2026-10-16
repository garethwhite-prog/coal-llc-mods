cls
`
# ==============================================================================
# Coal LLC - Clean Deploy for Lost Expedition (No Asset Regen, Safe Paths)
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$modName    = "gareth-lost_expedition_mod"
$outerDir   = "$repo\mods-unpacked\$modName"
$innerDir   = "$outerDir\mods-unpacked\$modName"
$zipPath    = "$steamMods\$modName.zip"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Removing space-prefixed folder and stray zip..." -ForegroundColor Cyan
git rm -r -f --ignore-unmatch "mods-unpacked/ gareth-lost_expedition_mod" 2>$null
if (Test-Path "$repo\mods-unpacked\ gareth-lost_expedition_mod") {
    Remove-Item -Path "$repo\mods-unpacked\ gareth-lost_expedition_mod" -Recurse -Force
}
if (Test-Path "$steamMods\ gareth-lost_expedition_mod.zip") {
    Remove-Item "$steamMods\ gareth-lost_expedition_mod.zip" -Force
}

Write-Host ">>> 2. Ensuring directories exist..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path "$innerDir\extensions\scripts" -Force | Out-Null
New-Item -ItemType Directory -Path "$innerDir\helpers" -Force | Out-Null

Write-Host ">>> 3. Writing Game.hooks.gd (routes ID 101 to MINE_REGION)..." -ForegroundColor Cyan
@'
extends Object

func change_stage(chain: ModLoaderHookChain, target: int, targetPosition: Vector2) -> void:
	var game = chain.reference_object
	if target == 2 and Gvars.level == 101:
		if game and "MINE_REGION" in game:
			game.target_stage = game.MINE_REGION
	chain.execute_next([target, targetPosition])
'@ | Set-Content -Path "$innerDir\extensions\scripts\Game.hooks.gd" -Encoding UTF8

Write-Host ">>> 4. Writing mod_main.gd with Game.gd hook..." -ForegroundColor Cyan
@'
extends Node

const MOD_DIR := "gareth-lost_expedition_mod"

func _init() -> void:
	ModLoaderLog.info("Lost Expedition Mod initializing...", MOD_DIR)
	var mod_dir_path: String = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/Menus/level_select.gd",
		mod_dir_path.path_join("extensions/scenes/Interfaces/Menus/level_select.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/tilemaps/tile_map_chunk.gd",
		mod_dir_path.path_join("extensions/scenes/tilemaps/tile_map_chunk.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/Game.gd",
		mod_dir_path.path_join("extensions/scripts/Game.hooks.gd")
	)

func _ready() -> void:
	ModLoaderLog.info("Lost Expedition Custom Map Mod (ID 101) online!", MOD_DIR)
'@ | Set-Content -Path "$innerDir\mod_main.gd" -Encoding UTF8

Write-Host ">>> 5. Writing LostExpeditionHelper.gd with smoothed depth scaling..." -ForegroundColor Cyan
@'
class_name LostExpeditionHelper
extends RefCounted

const EXPEDITION_LEVEL_ID: int = 101

func ensure_level_registered() -> void:
	var lvl_mgr = Gvars.level_manager
	if not lvl_mgr:
		return
	
	if not lvl_mgr.all_levels.has(EXPEDITION_LEVEL_ID):
		var custom_level = GameLevel.new()
		custom_level.level_name = "Lost Expedition"
		custom_level.level = EXPEDITION_LEVEL_ID
		custom_level.mining_scene_path = "res://scenes/Stages/MineRegion.tscn"
		custom_level.level_description = "Abandoned subterranean expedition.\nDeep strata riddled with volatile unexploded ordnance.\nCryo-shelters contain trapped mining personnel."
		custom_level.level_difficulty = GameLevel.Difficulty.HARD
		custom_level.unlock_description = ""
		
		var img = Image.load_from_file("res://mods-unpacked/gareth-lost_expedition_mod/assets/lost_expedition_card.png")
		if img:
			custom_level.level_image = ImageTexture.create_from_image(img)
		
		lvl_mgr.all_levels[EXPEDITION_LEVEL_ID] = {
			"level": custom_level,
			"is_unlocked": true
		}

func calculate_tier(pos: Vector2i) -> int:
	var depth: float = float(pos.y)
	if depth < 0.0:
		return -2
	
	var wave: float = sin(float(pos.x) * 0.12) * 5.0
	var effective_y: float = depth + wave
	
	if effective_y < 12.0:
		return 0
	elif effective_y < 35.0:
		return 1
	elif effective_y < 70.0:
		return 2
	elif effective_y < 120.0:
		return 3
	elif effective_y < 200.0:
		return 4
	elif effective_y < 300.0:
		return 5
	elif effective_y < 450.0:
		return 6
	elif effective_y < 600.0:
		return 7
	elif effective_y < 750.0:
		return 8
	elif effective_y < 900.0:
		return 9
	elif effective_y < 1050.0:
		return 10
	elif effective_y < 1200.0:
		return 11
	else:
		return 12

func tag_uxo_tiles(chunk: Node) -> void:
	var uxo: Dictionary = {}
	var total_cells: int = chunk.chunk_size * chunk.chunk_size
	for idx in range(total_cells):
		var tile_id = chunk.tiles[idx]
		if tile_id != chunk.Tiles.EMPTY and chunk.TILE_PROPERTIES[tile_id]["breakable"]:
			if randf() < 0.035:
				uxo[idx] = true
	chunk.set_meta("expedition_uxo", uxo)

func handle_tile_destroyed(chunk: Node, idx: int) -> void:
	if chunk.has_meta("expedition_uxo"):
		var uxo: Dictionary = chunk.get_meta("expedition_uxo")
		if uxo.has(idx):
			uxo.erase(idx)
			detonate_uxo(chunk, idx)

func detonate_uxo(chunk: Node, idx: int) -> void:
	var local_pos: Vector2 = chunk.map_to_local(chunk.array_to_pos(idx))
	var world_center: Vector2 = chunk.to_global(local_pos)
	var manager = chunk.get_parent()
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			var offset_world: Vector2 = world_center + Vector2(dx * 16.0, dy * 16.0)
			if manager and manager.has_method("damageTile"):
				manager.damageTile(offset_world, 450)

func spawn_cryo_pods(chunk: Node, current_locs: Array[Vector2i]) -> Array[Vector2i]:
	if randf() > 0.60:
		return current_locs
	
	var width: int = 3
	var height: int = 3
	var start_tile: Vector2i = Vector2i(
		randi_range(0, chunk.chunk_size - width),
		randi_range(0, chunk.chunk_size - height)
	)
	
	for n in range(5):
		if start_tile in current_locs:
			start_tile = Vector2i(
				randi_range(0, chunk.chunk_size - width),
				randi_range(0, chunk.chunk_size - height)
			)
	
	for x in range(start_tile.x - width, start_tile.x + width):
		for y in range(start_tile.y - height, start_tile.y + height):
			current_locs.append(Vector2i(x, y))
	
	for x in range(start_tile.x, start_tile.x + width):
		for y in range(start_tile.y, start_tile.y + height):
			var c_idx: int = chunk.pos_to_array(Vector2i(x, y))
			if (x == start_tile.x + 1) and (y == start_tile.y + 1):
				chunk.tiles[c_idx] = chunk.Tiles.EMPTY
				chunk.build_tile(c_idx)
				var pod_script = load("res://mods-unpacked/gareth-lost_expedition_mod/entities/CryoPod.gd")
				if pod_script:
					var pod = pod_script.new()
					pod.position = chunk.map_to_local(Vector2i(x, y))
					chunk.add_child.call_deferred(pod)
			else:
				chunk.tiles[c_idx] = chunk.chest_block_from_level(8)
				chunk.build_tile(c_idx)
	
	return current_locs
'@ | Set-Content -Path "$innerDir\helpers\LostExpeditionHelper.gd" -Encoding UTF8

Write-Host ">>> 6. Flushing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 7. Packaging mod archive for Steam..." -ForegroundColor Cyan
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$zipStream = [System.IO.File]::Open($zipPath, [System.IO.FileMode]::CreateNew)
$archive   = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create)
$allFiles  = Get-ChildItem -Path $outerDir -Recurse -File

foreach ($f in $allFiles) {
    $entryName = $f.FullName.Substring($outerDir.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$zipStream.Dispose()

Write-Host ">>> 8. Git committing and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Route Level 101 to MINE_REGION and smooth strata tiers"
git push origin main

Write-Host "`nDone! All files deployed cleanly." -ForegroundColor Green