cls

# ==============================================================================
# Coal LLC - Fix Tectonic Strata, Vault Spawning, and Card Preview Texture
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$modName    = "gareth-tectonic_faultline_mod"
$outerDir   = "$repo\mods-unpacked\$modName"
$innerDir   = "$outerDir\mods-unpacked\$modName"
$zipPath    = "$steamMods\$modName.zip"
$hookZip    = "$steamRoot\mod-hooks.zip"
$helperPath = "$innerDir\helpers\TectonicFaultlineHelper.gd"
$chunkHook  = "$innerDir\extensions\scenes\tilemaps\tile_map_chunk.hooks.gd"

Set-Location $repo

Write-Host ">>> 1. Inspecting working tile_map_chunk.hooks.gd from Lost Expedition..." -ForegroundColor Cyan
$leHookPath = "$repo\mods-unpacked\gareth-lost_expedition_mod\mods-unpacked\gareth-lost_expedition_mod\extensions\scenes\tilemaps\tile_map_chunk.hooks.gd"
if (Test-Path $leHookPath) {
    Get-Content $leHookPath | Select-Object -First 30 | ForEach-Object { Write-Host "   $_" -ForegroundColor DarkCyan }
}

Write-Host "`n>>> 2. Writing compile-safe TectonicFaultlineHelper.gd..." -ForegroundColor Cyan
@'
class_name TectonicFaultlineHelper
extends RefCounted

const FAULTLINE_LEVEL_ID: int = 102
const CHUNK_SIZE: int = 16

static func is_faultline_level() -> bool:
	if Gvars and "chosen_level" in Gvars and Gvars.chosen_level == FAULTLINE_LEVEL_ID:
		return true
	if Gvars and "current_level" in Gvars and Gvars.current_level == FAULTLINE_LEVEL_ID:
		return true
	return false

func ensure_level_registered() -> void:
	register_faultline_level()

static func register_faultline_level() -> void:
	if not Gvars:
		return
	
	if "level_manager" in Gvars and Gvars.level_manager and ("all_levels" in Gvars.level_manager):
		var lvl_mgr = Gvars.level_manager
		if not lvl_mgr.all_levels.has(FAULTLINE_LEVEL_ID):
			var custom_level = GameLevel.new()
			custom_level.level_name = "Tectonic Faultline"
			custom_level.level = FAULTLINE_LEVEL_ID
			custom_level.mining_scene_path = "res://scenes/Stages/MineRegion.tscn"
			custom_level.level_description = "Seismic faultline with superheated vents, magma fissures, and elemental chambers.\n\nElemental pods contain explosive fluids and geothermal updrafts."
			custom_level.level_difficulty = GameLevel.Difficulty.HARD
			custom_level.unlock_description = ""
			
			# Load preview texture directly from mod assets
			var preview_path = "res://mods-unpacked/gareth-tectonic_faultline_mod/assets/tectonic_preview.png"
			if ResourceLoader.exists(preview_path):
				var img = Image.load_from_file(preview_path)
				if img:
					custom_level.level_image = ImageTexture.create_from_image(img)
			
			if not custom_level.level_image:
				var fallback_path = "res://mods-unpacked/gareth-tectonic_faultline_mod/assets/magma_siphon_active.png"
				if ResourceLoader.exists(fallback_path):
					var fimg = Image.load_from_file(fallback_path)
					if fimg:
						custom_level.level_image = ImageTexture.create_from_image(fimg)
			
			lvl_mgr.all_levels[FAULTLINE_LEVEL_ID] = {
				"level": custom_level,
				"is_unlocked": true
			}
	
	if "level_info" in Gvars and Gvars.level_info is Dictionary:
		if not Gvars.level_info.has(FAULTLINE_LEVEL_ID):
			Gvars.level_info[FAULTLINE_LEVEL_ID] = {
				"name": "Tectonic Faultline",
				"description": "Seismic faultline with superheated vents, magma fissures, and elemental chambers.",
				"depth": 1400,
				"cost": 0,
				"unlocked": true
			}
	
	if "level_unlocked" in Gvars and Gvars.level_unlocked is Dictionary:
		if not Gvars.level_unlocked.has(FAULTLINE_LEVEL_ID):
			Gvars.level_unlocked[FAULTLINE_LEVEL_ID] = true
	
	if "level_highscores" in Gvars and Gvars.level_highscores is Dictionary:
		if not Gvars.level_highscores.has(FAULTLINE_LEVEL_ID):
			Gvars.level_highscores[FAULTLINE_LEVEL_ID] = 0
	
	if "level_scores" in Gvars and Gvars.level_scores is Dictionary:
		if not Gvars.level_scores.has(FAULTLINE_LEVEL_ID):
			Gvars.level_scores[FAULTLINE_LEVEL_ID] = 0

static func calculate_faultline_tier(global_cell: Vector2i) -> int:
	var y_tile: int = global_cell.y
	if y_tile <= 0:
		return 0
	elif y_tile < 24:
		return 1
	elif y_tile < 48:
		return 2
	elif y_tile < 80:
		return 3
	elif y_tile < 120:
		return 4
	elif y_tile < 170:
		return 5
	elif y_tile < 230:
		return 6
	elif y_tile < 300:
		return 7
	else:
		return min(12, 8 + int((y_tile - 300) / 80))

static func pick_faultline_block(chunk: Node, global_cell: Vector2i, noise: FastNoiseLite) -> int:
	if global_cell.y <= 0:
		return chunk.Tiles.EMPTY
	
	var tier: int = calculate_faultline_tier(global_cell)
	
	var rift_noise: float = abs(noise.get_noise_2d(float(global_cell.x) * 4.5, float(global_cell.y) * 1.2))
	if rift_noise < 0.09 and global_cell.y > 10:
		return chunk.Tiles.EMPTY
	
	var fissure_noise: float = noise.get_noise_2d(float(global_cell.x) * 2.8 + 50.0, float(global_cell.y) * 2.8)
	if fissure_noise > 0.42 and global_cell.y > 18:
		return chunk.Tiles.HARD_FIRE
	
	var base_tile: int = chunk.chest_block_from_level(tier)
	if base_tile == chunk.Tiles.EMPTY:
		base_tile = chunk.Tiles.HARD_FIRE
	return base_tile

static func tag_seismic_seams(_chunk: Node) -> void:
	pass

static func spawn_magma_siphons(chunk: Node, current_locs: Array[Vector2i]) -> Array[Vector2i]:
	# 75% spawn chance per eligible chunk so pods are plentiful
	if randf() > 0.75:
		return current_locs
	
	if "chunk_pos" in chunk and chunk.chunk_pos.y < 0:
		return current_locs
	
	var width: int = 3
	var height: int = 3
	var start_tile: Vector2i = Vector2i(
		randi_range(0, chunk.chunk_size - width),
		randi_range(0, chunk.chunk_size - height)
	)
	
	var global_cell: Vector2i = Vector2i(chunk.to_global(chunk.map_to_local(start_tile)) / 16.0)
	# Allow pods anywhere below surface dirt (y >= 6)
	if global_cell.y < 6:
		return current_locs
	
	# Vault perimeter walls (+2 tier harder rock)
	var pod_tier: int = calculate_faultline_tier(global_cell)
	var wall_tier: int = min(pod_tier + 2, 12)
	var wall_tile: int = chunk.chest_block_from_level(wall_tier)
	if wall_tile == chunk.Tiles.EMPTY:
		if global_cell.y > 50:
			wall_tile = chunk.Tiles.HARD_DARK
		elif global_cell.y > 25:
			wall_tile = chunk.Tiles.HARD_FIRE
		else:
			wall_tile = chunk.Tiles.HARD_ORANGE
	
	for n in range(5):
		if start_tile in current_locs:
			start_tile = Vector2i(
				randi_range(0, chunk.chunk_size - width),
				randi_range(0, chunk.chunk_size - height)
			)
	
	for x in range(start_tile.x - width, start_tile.x + width):
		for y in range(start_tile.y - height, start_tile.y + height):
			current_locs.append(Vector2i(x, y))
	
	# Carve 3x3 vault and build outer perimeter walls
	for x in range(start_tile.x, start_tile.x + width):
		for y in range(start_tile.y, start_tile.y + height):
			var local_coord: Vector2i = Vector2i(x, y)
			var idx: int = -1
			if chunk.has_method("local_pos_to_array"):
				idx = chunk.local_pos_to_array(local_coord)
			elif chunk.has_method("pos_to_array"):
				idx = chunk.pos_to_array(local_coord)
			else:
				idx = local_coord.x + local_coord.y * chunk.chunk_size
			
			if idx >= 0 and idx < chunk.tiles.size():
				if x == start_tile.x or x == start_tile.x + width - 1 or y == start_tile.y or y == start_tile.y + height - 1:
					chunk.tiles[idx] = wall_tile
				else:
					chunk.tiles[idx] = chunk.Tiles.EMPTY
	
	# Spawn elemental pod entity inside chamber
	var SiphonScene = load("res://mods-unpacked/gareth-tectonic_faultline_mod/entities/MagmaSiphon.gd")
	if SiphonScene:
		var siphon = SiphonScene.new()
		var center_tile: Vector2i = Vector2i(start_tile.x + 1, start_tile.y + 1)
		siphon.position = chunk.map_to_local(center_tile)
		
		var roll = randf()
		if roll < 0.40:
			siphon.set_element("fire")
		elif roll < 0.70:
			siphon.set_element("water")
		else:
			siphon.set_element("poison")
		
		chunk.add_child(siphon)
	
	return current_locs
'@ | Set-Content -Path $helperPath -Encoding UTF8
Write-Host "Updated: $helperPath" -ForegroundColor Green

Write-Host "`n>>> 3. Writing tile_map_chunk.hooks.gd (preloaded Helper, all 4 hook methods)..." -ForegroundColor Cyan
@'
extends Object

const HelperScript = preload("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")

func lvl_from_global_pos(pos, chain: ModLoaderHookChain) -> int:
	if HelperScript.is_faultline_level():
		return HelperScript.calculate_faultline_tier(Vector2i(pos))
	return chain.execute_next([pos])

func generate_chunk(chain: ModLoaderHookChain) -> void:
	var chunk = chain.reference_object
	if not chunk or not HelperScript.is_faultline_level():
		chain.execute_next([])
		return
	
	# Pass through sky chunks cleanly
	if "chunk_pos" in chunk and chunk.chunk_pos.y < 0:
		chain.execute_next([])
		return
	
	chain.execute_next([])
	
	# Generate faultline matrix below surface
	if "chunk_pos" in chunk and chunk.chunk_pos.y >= 0:
		var noise = FastNoiseLite.new()
		noise.seed = Gvars.map_seed if "map_seed" in Gvars else 1337
		noise.frequency = 0.035
		
		for x in range(chunk.chunk_size):
			for y in range(chunk.chunk_size):
				var local_pos = Vector2i(x, y)
				var global_posi: Vector2i = Vector2i(chunk.to_global(chunk.map_to_local(local_pos)) / 16.0)
				
				if global_posi.y > 0:
					var idx: int = -1
					if chunk.has_method("local_pos_to_array"):
						idx = chunk.local_pos_to_array(local_pos)
					elif chunk.has_method("pos_to_array"):
						idx = chunk.pos_to_array(local_pos)
					else:
						idx = x + y * chunk.chunk_size
					
					if idx >= 0 and idx < chunk.tiles.size():
						if chunk.tiles[idx] != chunk.Tiles.EMPTY:
							chunk.tiles[idx] = HelperScript.pick_faultline_block(chunk, global_posi, noise)
		
		HelperScript.tag_seismic_seams(chunk)

func generate_chests(current_locs: Array[Vector2i], chain: ModLoaderHookChain) -> Array[Vector2i]:
	var chunk = chain.reference_object
	if not chunk or not HelperScript.is_faultline_level():
		return chain.execute_next([current_locs])
	
	current_locs = HelperScript.spawn_magma_siphons(chunk, current_locs)
	return chain.execute_next([current_locs])

func destroy_tile(idx: int, tile_properties: Dictionary, chain: ModLoaderHookChain) -> void:
	chain.execute_next([idx, tile_properties])
'@ | Set-Content -Path $chunkHook -Encoding UTF8
Write-Host "Updated: $chunkHook" -ForegroundColor Green

Write-Host "`n>>> 4. Flushing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 5. Repackaging mod archive for Steam..." -ForegroundColor Cyan
if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force
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
Write-Host "Packed archive at: $zipPath" -ForegroundColor Green

Write-Host ">>> 6. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Fix compile error in TectonicFaultlineHelper, implement preloaded chunk hooks, and enable surface-depth pod spawning"
git push origin main

Write-Host "`nDeploy complete! Launch Coal LLC to test." -ForegroundColor Green