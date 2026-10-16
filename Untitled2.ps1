cls
`
# ==============================================================================
# Coal LLC - Fix Lost Expedition Stage Routing, Depth Scaling & Cache Rebuild
# ==============================================================================

 $repoRoot      = "C:\Dev\coal-llc-mods"
 $modName       = "gareth-lost_expedition_mod"
 $outerModDir   = Join-Path $repoRoot "mods-unpacked\ $modName"
 $innerModDir   = Join-Path $outerModDir "mods-unpacked\ $modName"
 $steamRoot     = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
 $steamModsDir  = Join-Path $steamRoot "mods"
 $zipPath       = Join-Path $steamModsDir " $modName.zip"
 $hookZipPath   = Join-Path $steamRoot "mod-hooks.zip"

Set-Location $repoRoot

Write-Host ">>> 1. Creating extensions/scripts directory..." -ForegroundColor Cyan
 $scriptsHookDir = Join-Path $innerModDir "extensions\scripts"
if (-not (Test-Path $scriptsHookDir)) {
    New-Item -ItemType Directory -Path $scriptsHookDir -Force | Out-Null
}

Write-Host ">>> 2. Writing Game.hooks.gd to route Level 101 to MINE_REGION..." -ForegroundColor Cyan
 $gameHooksGd = @'
extends Object

func change_stage(chain: ModLoaderHookChain, target: int, targetPosition: Vector2) -> void:
	var game = chain.reference_object
	if target == 2 and Gvars.level == 101:
		if game and "MINE_REGION" in game:
			game.target_stage = game.MINE_REGION
	chain.execute_next([target, targetPosition])
'@
 $gameHooksPath = Join-Path $scriptsHookDir "Game.hooks.gd"
Set-Content -Path $gameHooksPath -Value $gameHooksGd -Encoding UTF8
Write-Host "Created: $gameHooksPath" -ForegroundColor Green

Write-Host ">>> 3. Updating mod_main.gd with Game.gd hook registration..." -ForegroundColor Cyan
 $modMainGd = @'
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
'@
 $modMainPath = Join-Path $innerModDir "mod_main.gd"
Set-Content -Path $modMainPath -Value $modMainGd -Encoding UTF8
Write-Host "Updated: $modMainPath" -ForegroundColor Green

Write-Host ">>> 4. Updating LostExpeditionHelper.gd with smooth depth scaling..." -ForegroundColor Cyan
 $helperGd = @'
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
'@
 $helperPath = Join-Path $innerModDir "helpers\LostExpeditionHelper.gd"
Set-Content -Path $helperPath -Value $helperGd -Encoding UTF8
Write-Host "Updated: $helperPath" -ForegroundColor Green

Write-Host ">>> 5. Deleting mod-hooks.zip to instrument Game.gd..." -ForegroundColor Cyan
if (Test-Path $hookZipPath) {
	Remove-Item -Path $hookZipPath -Force
	Write-Host "mod-hooks.zip deleted." -ForegroundColor Green
}

Write-Host ">>> 6. Repackaging $modName.zip for Steam..." -ForegroundColor Cyan
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

 $zipStream = [System.IO.File]::Open( $zipPath, [System.IO.FileMode]::CreateNew)
 $archive = New-Object System.IO.Compression.ZipArchive( $zipStream, [System.IO.Compression.ZipArchiveMode]::Create)

 $filesToZip = Get-ChildItem -Path $outerModDir -Recurse -File
foreach ( $file in $filesToZip) { $relative = $file.FullName.Substring( $outerModDir.Length + 1).Replace("\", "/")
	[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile( $archive, $file.FullName, $relative) | Out-Null
}

 $archive.Dispose() 
 $zipStream.Dispose()
Write-Host "Archive re-packaged cleanly at: $zipPath" -ForegroundColor Green

Write-Host ">>> 7. Updating SESSION_PROMPT.md..." -ForegroundColor Cyan
 $sessionPromptPath = Join-Path $repoRoot "SESSION_PROMPT.md"
 $sessionContent = Get-Content $sessionPromptPath -Raw

if ( $sessionContent -notmatch "Custom Map Stage Routing") {
	 $mapStageRule = @"
7. Custom Map Stage Routing (`Game.gd:change_stage`):
   `Game.gd:change_stage` contains a hardcoded `match Gvars.level` without a default case when `target == 2` (_MINE_REGION). Custom map IDs must be intercepted via a hook on `res://scripts/Game.gd:change_stage` to set `game.target_stage = game.MINE_REGION` before `chain.execute_next()`. Without this hook, `target_stage` retains previous screens (e.g. END_OF_DAY_OVERLAY) and fails quota on frame 1.
"@
	 $sessionContent = $sessionContent -replace "(?s)(## 3\. Godot 4 & ModLoader Engine Quirks.*?)(\n## 4\. Economy)", "` $1`n $mapStageRule` $2"
	Set-Content -Path $sessionPromptPath -Value $sessionContent -Encoding UTF8
	Write-Host "SESSION_PROMPT.md updated with stage routing rule." -ForegroundColor Green
}

Write-Host ">>> 8. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Route Level 101 to MINE_REGION in Game.gd hook and smooth depth tier scaling"
git push origin main

Write-Host "`nAll updates deployed cleanly! Launch Coal LLC to play Lost Expedition." -ForegroundColor Green