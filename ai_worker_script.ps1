cls

# ==============================================================================
# Coal LLC - Apply Discovered Sky (-2) & Vault build_tile Contracts
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

Write-Host ">>> 1. Updating TectonicFaultlineHelper.gd with -2 sky code & build_tile..." -ForegroundColor Cyan
@'
class_name TectonicFaultlineHelper
extends RefCounted

const FAULTLINE_LEVEL_ID: int = 102
const CHUNK_SIZE: int = 16

static func is_faultline_level() -> bool:
	if Gvars:
		if "level" in Gvars and Gvars.level == FAULTLINE_LEVEL_ID:
			return true
		if "chosen_level" in Gvars and Gvars.chosen_level == FAULTLINE_LEVEL_ID:
			return true
		if "current_level" in Gvars and Gvars.current_level == FAULTLINE_LEVEL_ID:
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
			
			var preview_path = "res://mods-unpacked/gareth-tectonic_faultline_mod/assets/tectonic_preview.png"
			var bytes = FileAccess.get_file_as_bytes(preview_path)
			if bytes and bytes.size() > 0:
				var f_img = Image.new()
				if f_img.load_png_from_buffer(bytes) == OK:
					custom_level.level_image = ImageTexture.create_from_image(f_img)
			
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

static func calculate_faultline_tier(pos: Vector2i) -> int:
	var y_tile: int = pos.y
	# Contract Discovery: Vanilla returns -2 for sky / surface air
	if y_tile < 0:
		return -2
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
	if tier < 0:
		return chunk.Tiles.EMPTY
	
	# Primary vertical chasm slicing through strata
	var rift_noise: float = abs(noise.get_noise_2d(float(global_cell.x) * 4.5, float(global_cell.y) * 1.2))
	if rift_noise < 0.09 and global_cell.y > 10:
		return chunk.Tiles.EMPTY
	
	# Secondary magma fissures
	var fissure_noise: float = noise.get_noise_2d(float(global_cell.x) * 2.8 + 50.0, float(global_cell.y) * 2.8)
	if fissure_noise > 0.42 and global_cell.y > 18:
		return chunk.Tiles.HARD_FIRE
	
	var base_tile: int = chunk.chest_block_from_level(tier)
	if base_tile == chunk.Tiles.EMPTY:
		base_tile = chunk.Tiles.HARD_FIRE
	return base_tile

static func generate_faultline_strata(chunk: Node, noise: FastNoiseLite) -> void:
	if not ("tiles" in chunk) or not ("chunk_size" in chunk):
		return
	
	for x in range(chunk.chunk_size):
		for y in range(chunk.chunk_size):
			var local_pos = Vector2i(x, y)
			var global_posi: Vector2i = Vector2i(chunk.to_global(chunk.map_to_local(local_pos)) / 16.0)
			
			# Leave surface grass and top dirt intact (y <= 3)
			if global_posi.y > 3:
				var idx: int = chunk.pos_to_array(local_pos) if chunk.has_method("pos_to_array") else (x + y * chunk.chunk_size)
				if idx >= 0 and idx < chunk.tiles.size():
					if chunk.tiles[idx] != chunk.Tiles.EMPTY:
						var new_block = pick_faultline_block(chunk, global_posi, noise)
						chunk.tiles[idx] = new_block
						chunk.build_tile(idx)

static func spawn_magma_siphons(chunk: Node, current_locs: Array[Vector2i]) -> Array[Vector2i]:
	if randf() > 0.65:
		return current_locs
	
	if "chunk_pos" in chunk and chunk.chunk_pos.y < 1:
		return current_locs
	
	var width: int = 3
	var height: int = 3
	var start_tile: Vector2i = Vector2i(
		randi_range(0, chunk.chunk_size - width),
		randi_range(0, chunk.chunk_size - height)
	)
	
	var local_start: Vector2 = chunk.map_to_local(start_tile)
	var world_start: Vector2 = chunk.to_global(local_start)
	var global_cell: Vector2i = Vector2i(world_start / 16.0)
	if global_cell.y < 10:
		return current_locs
	
	# Vault perimeter walls (+2 tier harder rock)
	var pod_tier: int = calculate_faultline_tier(global_cell)
	var wall_tier: int = min(max(1, pod_tier + 2), 12)
	var wall_tile: int = chunk.chest_block_from_level(wall_tier)
	if wall_tile == chunk.Tiles.EMPTY:
		wall_tile = chunk.Tiles.HARD_DARK if global_cell.y > 40 else chunk.Tiles.HARD_FIRE
	
	for n in range(5):
		if start_tile in current_locs:
			start_tile = Vector2i(
				randi_range(0, chunk.chunk_size - width),
				randi_range(0, chunk.chunk_size - height)
			)
	
	# Reserve room tiles so chests do not spawn inside
	for x in range(start_tile.x - width, start_tile.x + width):
		for y in range(start_tile.y - height, start_tile.y + height):
			current_locs.append(Vector2i(x, y))
	
	# Contract Discovery: Update tiles array AND rebuild via chunk.build_tile(c_idx)
	for x in range(start_tile.x, start_tile.x + width):
		for y in range(start_tile.y, start_tile.y + height):
			var local_coord = Vector2i(x, y)
			var c_idx: int = chunk.pos_to_array(local_coord)
			var is_wall = (x == start_tile.x or x == start_tile.x + width - 1 or y == start_tile.y or y == start_tile.y + height - 1)
			
			if is_wall:
				chunk.tiles[c_idx] = wall_tile
				chunk.build_tile(c_idx)
			else:
				chunk.tiles[c_idx] = chunk.Tiles.EMPTY
				chunk.build_tile(c_idx)
	
	# Spawn elemental pod entity inside hollowed vault center
	var SiphonScene = load("res://mods-unpacked/gareth-tectonic_faultline_mod/entities/MagmaSiphon.gd")
	if SiphonScene:
		var siphon = SiphonScene.new()
		var center_tile = Vector2i(start_tile.x + 1, start_tile.y + 1)
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

Write-Host "`n>>> 2. Updating tile_map_chunk.hooks.gd (matching LostExpedition hook pattern)..." -ForegroundColor Cyan
@'
extends Object

func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	if Gvars.level == 102:
		var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
		if helper_script:
			return helper_script.calculate_faultline_tier(pos)
	return chain.execute_next([pos])

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	chain.execute_next([noise])
	if Gvars.level == 102:
		var chunk = chain.reference_object
		if chunk and "chunk_pos" in chunk and chunk.chunk_pos.y >= 0:
			var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
			if helper_script:
				var fnl = FastNoiseLite.new()
				fnl.seed = Gvars.map_seed if ("map_seed" in Gvars) else 1337
				fnl.frequency = 0.035
				helper_script.generate_faultline_strata(chunk, fnl)

func generate_chests(chain: ModLoaderHookChain, current_block_chest_locations: Array[Vector2i]) -> Array[Vector2i]:
	var locs: Array[Vector2i] = chain.execute_next([current_block_chest_locations])
	if Gvars.level == 102:
		var chunk = chain.reference_object
		if chunk:
			var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
			if helper_script:
				locs = helper_script.spawn_magma_siphons(chunk, locs)
	return locs

func destroy_tile(chain: ModLoaderHookChain, idx: int, tile_properties: Dictionary) -> void:
	chain.execute_next([idx, tile_properties])
'@ | Set-Content -Path $chunkHook -Encoding UTF8
Write-Host "Updated: $chunkHook" -ForegroundColor Green

Write-Host "`n>>> 3. Flushing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 4. Repackaging mod archive for Steam..." -ForegroundColor Cyan
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

Write-Host ">>> 5. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Align Map 102 generation with LostExpedition contracts: -2 sky return, chunk.build_tile GPU sync, and generate_chests vault placement"
git push origin main

Write-Host "`nDeploy complete! Launch Coal LLC to test." -ForegroundColor Green