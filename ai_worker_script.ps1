cls

# ==============================================================================
# Coal LLC - Fix Tectonic Ground Generation, Vault Spawning & Card Image
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

Write-Host ">>> 1. Writing TectonicFaultlineHelper.gd with procedural preview fallback..." -ForegroundColor Cyan
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
			
			# 1. Try loading disk PNG buffer
			var preview_tex: Texture2D = null
			var preview_path = "res://mods-unpacked/gareth-tectonic_faultline_mod/assets/tectonic_preview.png"
			var bytes = FileAccess.get_file_as_bytes(preview_path)
			if bytes and bytes.size() > 0:
				var f_img = Image.new()
				if f_img.load_png_from_buffer(bytes) == OK:
					preview_tex = ImageTexture.create_from_image(f_img)
			
			# 2. Procedural guaranteed fallback texture
			if not preview_tex:
				var p_img = Image.create(280, 150, false, Image.FORMAT_RGBA8)
				p_img.fill(Color(0.1, 0.08, 0.12))
				for x in range(0, 280, 16):
					for y in range(0, 150, 16):
						var col = Color(0.18, 0.14, 0.2) if ((x + y) / 16) % 2 == 0 else Color(0.14, 0.11, 0.16)
						for bx in range(1, 15):
							for by in range(1, 15):
								p_img.set_pixel(x + bx, y + by, col)
				for y in range(150):
					var cx = int(140 + sin(y * 0.08) * 22 + (y - 75) * 0.45)
					for x in range(cx - 16, cx + 17):
						if x >= 0 and x < 280:
							p_img.set_pixel(x, y, Color(0.9, 0.35, 0.05))
					for x in range(cx - 6, cx + 7):
						if x >= 0 and x < 280:
							p_img.set_pixel(x, y, Color(1.0, 0.85, 0.25))
					for x in range(cx - 2, cx + 3):
						if x >= 0 and x < 280:
							p_img.set_pixel(x, y, Color(1.0, 0.98, 0.8))
				for y in range(14):
					for x in range(280):
						if ((x + y) / 10) % 2 == 0:
							p_img.set_pixel(x, y, Color(0.85, 0.2, 0.15))
				preview_tex = ImageTexture.create_from_image(p_img)
			
			custom_level.level_image = preview_tex
			
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

static func generate_faultline_strata(chunk: Node, noise: FastNoiseLite) -> void:
	if not ("tiles" in chunk) or not ("chunk_size" in chunk):
		return
	
	for x in range(chunk.chunk_size):
		for y in range(chunk.chunk_size):
			var local_pos = Vector2i(x, y)
			var global_posi: Vector2i = Vector2i(chunk.to_global(chunk.map_to_local(local_pos)) / 16.0)
			
			# Leave surface grass and top dirt intact (y <= 3) so spawn structures stand firm
			if global_posi.y > 3:
				var idx = x + y * chunk.chunk_size
				if idx >= 0 and idx < chunk.tiles.size():
					if chunk.tiles[idx] != chunk.Tiles.EMPTY:
						chunk.tiles[idx] = pick_faultline_block(chunk, global_posi, noise)

static func spawn_magma_siphons(chunk: Node) -> void:
	if "chunk_pos" in chunk and chunk.chunk_pos.y < 0:
		return
	
	# 80% chance of vault per underground chunk
	if randf() > 0.80:
		return
	
	var width: int = 3
	var height: int = 3
	var start_x = randi_range(1, chunk.chunk_size - width - 1)
	var start_y = randi_range(1, chunk.chunk_size - height - 1)
	
	var global_cell: Vector2i = Vector2i(chunk.to_global(chunk.map_to_local(Vector2i(start_x, start_y))) / 16.0)
	if global_cell.y < 6:
		return
	
	# Fortified chamber perimeter walls
	var pod_tier: int = calculate_faultline_tier(global_cell)
	var wall_tier: int = min(pod_tier + 2, 12)
	var wall_tile: int = chunk.chest_block_from_level(wall_tier)
	if wall_tile == chunk.Tiles.EMPTY:
		wall_tile = chunk.Tiles.HARD_DARK if global_cell.y > 40 else chunk.Tiles.HARD_FIRE
	
	# Carve 3x3 vault into chunk.tiles array
	for x in range(start_x, start_x + width):
		for y in range(start_y, start_y + height):
			var idx = x + y * chunk.chunk_size
			if idx >= 0 and idx < chunk.tiles.size():
				if x == start_x or x == start_x + width - 1 or y == start_y or y == start_y + height - 1:
					chunk.tiles[idx] = wall_tile
				else:
					chunk.tiles[idx] = chunk.Tiles.EMPTY
	
	# Spawn elemental pod entity inside chamber
	var SiphonScene = load("res://mods-unpacked/gareth-tectonic_faultline_mod/entities/MagmaSiphon.gd")
	if SiphonScene:
		var siphon = SiphonScene.new()
		siphon.position = chunk.map_to_local(Vector2i(start_x + 1, start_y + 1))
		var roll = randf()
		if roll < 0.40:
			siphon.set_element("fire")
		elif roll < 0.70:
			siphon.set_element("water")
		else:
			siphon.set_element("poison")
		chunk.add_child(siphon)
'@ | Set-Content -Path $helperPath -Encoding UTF8
Write-Host "Updated: $helperPath" -ForegroundColor Green

Write-Host "`n>>> 2. Writing tile_map_chunk.hooks.gd with exact chain-first hook signatures..." -ForegroundColor Cyan
@'
extends Object

const HelperScript = preload("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")

func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	if HelperScript.is_faultline_level():
		return HelperScript.calculate_faultline_tier(pos)
	return chain.execute_next([pos])

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	# 1. Let vanilla execute completely with noise argument to populate chunk.tiles
	chain.execute_next([noise])
	
	# 2. If Tectonic Faultline, sculpt strata and spawn elemental vaults
	if HelperScript.is_faultline_level():
		var chunk = chain.reference_object
		if chunk and "chunk_pos" in chunk and chunk.chunk_pos.y >= 0:
			var fnl = FastNoiseLite.new()
			fnl.seed = Gvars.map_seed if ("map_seed" in Gvars) else 1337
			fnl.frequency = 0.035
			HelperScript.generate_faultline_strata(chunk, fnl)
			HelperScript.spawn_magma_siphons(chunk)

func generate_chests(chain: ModLoaderHookChain, current_locs: Array[Vector2i]) -> Array[Vector2i]:
	return chain.execute_next([current_locs])

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
git commit -m "Fix generate_chunk noise forwarding and provide procedural image texture fallback"
git push origin main

Write-Host "`nDeploy complete! Launch Coal LLC to test." -ForegroundColor Green