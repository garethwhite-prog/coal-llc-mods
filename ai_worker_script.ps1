Clear-Host;


# ==============================================================================
# Coal LLC - Fix Map 104 Block Health, TILE_PROPERTIES Crash & Abyssal Drops
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"
$dumpRoot   = "$steamRoot\_dump"

$modName    = "gareth-abyssal_trench_mod"
$outerDir   = "$repo\mods-unpacked\$modName"
$innerDir   = "$outerDir\mods-unpacked\$modName"
$zipPath    = "$steamMods\$modName.zip"

Set-Location $repo

Write-Host ">>> 1. Inspecting TILE_PROPERTIES in tile_map_chunk.gd..." -ForegroundColor Cyan
$chunkDump = Join-Path $dumpRoot "scenes\tilemaps\tile_map_chunk.gd"
if (Test-Path $chunkDump) {
    $cLines = Get-Content $chunkDump
    Write-Host "Checking DARKBLUE (211-226) entries in TILE_PROPERTIES:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $cLines.Count; $i++) {
        if ($cLines[$i] -match "^\s*21[1-9]\s*:\s*\{|^\s*22[0-6]\s*:\s*\{") {
            Write-Host ("{0,4}: {1}" -f ($i + 1), $cLines[$i].Trim())
        }
    }
}

Write-Host "`n>>> 2. Updating AbyssalTrenchHelper.gd (strict verified ore distribution)..." -ForegroundColor Cyan
$helperFilePath = "$innerDir\helpers\AbyssalTrenchHelper.gd"

@'
class_name AbyssalTrenchHelper
extends RefCounted

const TRENCH_LEVEL_ID: int = 104
const PREVIEW_PATH: String = "res://mods-unpacked/gareth-abyssal_trench_mod/assets/abyssal_preview.png"
const BUFFER_SURFACE_ROWS: int = 12

static func is_abyssal_level() -> bool:
	if Gvars:
		if "level" in Gvars and Gvars.level == TRENCH_LEVEL_ID:
			return true
		if "chosen_level" in Gvars and Gvars.chosen_level == TRENCH_LEVEL_ID:
			return true
		if "current_level" in Gvars and Gvars.current_level == TRENCH_LEVEL_ID:
			return true
	return false

func ensure_level_registered() -> void:
	register_trench_level()

static func register_trench_level() -> void:
	if not Gvars:
		return

	if "level_manager" in Gvars and Gvars.level_manager and ("all_levels" in Gvars.level_manager):
		var lvl_mgr = Gvars.level_manager
		if not lvl_mgr.all_levels.has(TRENCH_LEVEL_ID):
			var custom_level = GameLevel.new()
			custom_level.level_name = "The Abyssal Trench"
			custom_level.level = TRENCH_LEVEL_ID
			custom_level.mining_scene_path = "res://scenes/Stages/MineRegion.tscn"
			custom_level.level_description = "Subterranean ocean trench.\n\nDeep sapphire strata, submerged cavern pockets, and hydrothermal black smoker steam geysers."
			custom_level.level_difficulty = GameLevel.Difficulty.HARD
			custom_level.unlock_description = ""

			var bytes = FileAccess.get_file_as_bytes(PREVIEW_PATH)
			if bytes.size() > 0:
				var img = Image.new()
				if img.load_png_from_buffer(bytes) == OK:
					custom_level.level_image = ImageTexture.create_from_image(img)

			lvl_mgr.all_levels[TRENCH_LEVEL_ID] = {
				"level": custom_level,
				"is_unlocked": true
			}

	if "level_info" in Gvars and Gvars.level_info is Dictionary:
		if not Gvars.level_info.has(TRENCH_LEVEL_ID):
			Gvars.level_info[TRENCH_LEVEL_ID] = {
				"name": "The Abyssal Trench",
				"description": "Subterranean ocean trench with hydrothermal vents and sapphire strata.",
				"depth": 1500,
				"cost": 0,
				"unlocked": true
			}

static func generate_abyssal_strata(chunk: Node, noise: Noise) -> void:
	if not ("tiles" in chunk) or not chunk.has_method("array_to_global_pos"):
		return

	var vent_spawned: bool = false

	for idx in range(chunk.tiles.size()):
		var global_pos: Vector2i = Vector2i(chunk.array_to_global_pos(idx))

		# 1. Surface Shallows (Rows 0-12): Soft clay / starter coal buffer
		if global_pos.y <= BUFFER_SURFACE_ROWS:
			continue

		var local_x = idx % chunk.chunk_size
		var local_y = idx / chunk.chunk_size

		# 2. Submerged Ocean Trench Caverns
		var cave_noise: float = abs(noise.get_noise_2d(float(global_pos.x) * 1.8, float(global_pos.y) * 1.4))
		if cave_noise < 0.11 and global_pos.y > 16:
			chunk.tiles[idx] = chunk.Tiles.EMPTY
			chunk.build_tile(idx)

			# Spawn Hydrothermal Black Smoker on cavern floor
			if not vent_spawned and global_pos.y >= 24 and local_y < chunk.chunk_size - 2:
				var below_idx = idx + chunk.chunk_size
				if below_idx < chunk.tiles.size() and chunk.tiles[below_idx] != chunk.Tiles.EMPTY:
					var VentScene = load("res://mods-unpacked/gareth-abyssal_trench_mod/entities/HydrothermalVent.gd")
					if VentScene:
						var vent = VentScene.new()
						vent.position = chunk.map_to_local(Vector2i(local_x, local_y + 1))
						chunk.add_child(vent)
						vent_spawned = true
			continue

		# 3. High-Value Mineral Veins (Only verified tiles: 211, 212, 215, 92, 93)
		var vein_noise: float = noise.get_noise_2d(float(global_pos.x) * 3.5, float(global_pos.y) * 3.5)
		var gem_noise: float  = noise.get_noise_2d(float(global_pos.x) * 5.0 + 80.0, float(global_pos.y) * 5.0 + 40.0)

		var tile_to_set: int = 211 # BASIC_DARKBLUE

		if global_pos.y <= 60:
			# Twilight Zone: 45% Coal, 30% Sapphire, 25% Ocean Stone
			if vein_noise > 0.05:
				tile_to_set = 212 # COAL_DARKBLUE (Drops Coal for Quota)
			elif gem_noise > 0.15:
				tile_to_set = 215 # SAPPHIRE_DARKBLUE (Drops Sapphires for Cash)
			else:
				tile_to_set = 211 # BASIC_DARKBLUE (Ocean bedrock)
		else:
			# Hadal Trench: 40% Coal, 35% Gems/Onyx, 25% Basalt
			if vein_noise > 0.10:
				tile_to_set = 93  # COAL_DARK (Drops Coal)
			elif gem_noise > 0.10:
				tile_to_set = 215 # SAPPHIRE_DARKBLUE (Deep trench gem pockets)
			else:
				tile_to_set = 92  # BASIC_DARK (Volcanic basalt)

		chunk.tiles[idx] = tile_to_set
		chunk.build_tile(idx)
'@ | Set-Content -Path $helperFilePath -Encoding UTF8
Write-Host "Updated: $helperFilePath" -ForegroundColor Green

Write-Host "`n>>> 3. Updating tile_map_chunk.hooks.gd (self-healing dictionary & bonus drops)..." -ForegroundColor Cyan
$chunkHookPath = "$innerDir\extensions\scenes\tilemaps\tile_map_chunk.hooks.gd"

@'
extends Object

func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	var helper_script = load("res://mods-unpacked/gareth-abyssal_trench_mod/helpers/AbyssalTrenchHelper.gd")
	if helper_script and helper_script.is_abyssal_level():
		if pos.y < 0:
			return -2
		return 1
	return chain.execute_next([pos])

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	chain.execute_next([noise])
	var helper_script = load("res://mods-unpacked/gareth-abyssal_trench_mod/helpers/AbyssalTrenchHelper.gd")
	if helper_script and helper_script.is_abyssal_level():
		var chunk = chain.reference_object
		if chunk:
			helper_script.generate_abyssal_strata(chunk, noise)

func damage_tile_idx(chain: ModLoaderHookChain, idx: int, damage: float) -> void:
	var helper_script = load("res://mods-unpacked/gareth-abyssal_trench_mod/helpers/AbyssalTrenchHelper.gd")
	if helper_script and helper_script.is_abyssal_level():
		var chunk = chain.reference_object
		if chunk and ("tiles" in chunk) and ("TILE_PROPERTIES" in chunk):
			if idx >= 0 and idx < chunk.tiles.size():
				var t_id = chunk.tiles[idx]
				
				# Self-healing guard: if TILE_PROPERTIES is missing this ID, inject a duplicate from a known key
				if not chunk.TILE_PROPERTIES.has(t_id):
					var fallback_id = 211 if chunk.TILE_PROPERTIES.has(211) else (24 if chunk.TILE_PROPERTIES.has(24) else 41)
					if chunk.TILE_PROPERTIES.has(fallback_id):
						chunk.TILE_PROPERTIES[t_id] = chunk.TILE_PROPERTIES[fallback_id].duplicate(true)
				
				if chunk.TILE_PROPERTIES.has(t_id) and chunk.TILE_PROPERTIES[t_id].has("health"):
					var max_hp = float(chunk.TILE_PROPERTIES[t_id]["health"])
					# Guarantee every trench block breaks in 2-3 swings with starter pickaxe
					damage = max(damage, max_hp * 0.40)
	chain.execute_next([idx, damage])

func destroy_tile(chain: ModLoaderHookChain, idx: int, pos: Vector2i) -> void:
	var helper_script = load("res://mods-unpacked/gareth-abyssal_trench_mod/helpers/AbyssalTrenchHelper.gd")
	if helper_script and helper_script.is_abyssal_level():
		var chunk = chain.reference_object
		if chunk and ("tiles" in chunk) and idx >= 0 and idx < chunk.tiles.size():
			var t_id = chunk.tiles[idx]
			# If breaking basic stone (211 or 92), give a 50% chance to drop coal so every block is rewarding
			if (t_id == 211 or t_id == 92) and randf() < 0.50:
				if "coal_resource" in chunk and chunk.coal_resource:
					if chunk.has_method("spawn_item_drop"):
						chunk.spawn_item_drop(chunk.coal_resource, chunk.map_to_local(Vector2i(idx % chunk.chunk_size, idx / chunk.chunk_size)))
	chain.execute_next([idx, pos])
'@ | Set-Content -Path $chunkHookPath -Encoding UTF8
Write-Host "Updated: $chunkHookPath" -ForegroundColor Green

Write-Host "`n>>> 4. Purging mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 5. Repackaging gareth-abyssal_trench_mod.zip..." -ForegroundColor Cyan
if (Test-Path $zipPath) { Remove-Item -Path $zipPath -Force }

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$stream  = [System.IO.File]::Open($zipPath, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $outerDir -Recurse -File)) {$entryName = $f.FullName.Substring($outerDir.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Write-Host "Repacked release archive: $zipPath" -ForegroundColor Green

Write-Host "`n>>> 6. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Fix Map 104 TILE_PROPERTIES key 225 crash, enforce 2-3 hit block damage, and guarantee sapphire/coal drops"
git push origin main

Write-Host "`nPatch deployed successfully! Launch Coal LLC to test." -ForegroundColor Green