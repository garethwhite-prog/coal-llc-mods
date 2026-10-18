Clear-Host;

# ==============================================================================
# Coal LLC - Fix & Deploy Map 104: The Abyssal Trench (Explicit Target Paths)
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

$modName    = "gareth-abyssal_trench_mod"
$outerDir   = "$repo\mods-unpacked\$modName"
$innerDir   = "$outerDir\mods-unpacked\$modName"
$zipPath    = "$steamMods\$modName.zip"

Set-Location $repo

Write-Host ">>> 1. Ensuring target directory tree exists..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path "$innerDir\helpers" -Force | Out-Null
New-Item -ItemType Directory -Path "$innerDir\assets" -Force | Out-Null
New-Item -ItemType Directory -Path "$innerDir\entities" -Force | Out-Null
New-Item -ItemType Directory -Path "$innerDir\extensions\scenes\Interfaces\Menus" -Force | Out-Null
New-Item -ItemType Directory -Path "$innerDir\extensions\scenes\tilemaps" -Force | Out-Null
New-Item -ItemType Directory -Path "$innerDir\extensions\scripts" -Force | Out-Null

Write-Host ">>> 2. Writing manifest.json..." -ForegroundColor Cyan
@'
{
  "name": "abyssal_trench_mod",
  "namespace": "gareth",
  "version_number": "1.0.0",
  "description": "Subterranean ocean trench featuring hydrothermal black smoker geysers, twilight sapphire strata, and abyssal basalt.",
  "website_url": "https://github.com/garethwhite-prog/coal-llc-mods",
  "dependencies": [],
  "extra": {
    "godot": {
      "display_name": "The Abyssal Trench",
      "category": "Maps & Environments",
      "authors": ["Gareth White"],
      "tags": ["map", "abyss", "ocean", "trench", "geyser"],
      "compatible_mod_loader_version": ["7.0.1"],
      "compatible_game_version": ["1.4.1.1"]
    }
  }
}
'@ | Set-Content -Path "$outerDir\manifest.json" -Encoding UTF8
Copy-Item -Path "$outerDir\manifest.json" -Destination "$innerDir\manifest.json" -Force

Write-Host ">>> 3. Generating abyssal_preview.png in assets..." -ForegroundColor Cyan
Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap 240, 150
$gfx = [System.Drawing.Graphics]::FromImage($bmp)
$gfx.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

# Ocean Gradient Background
$rect = New-Object System.Drawing.Rectangle 0, 0, 240, 150
$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $rect,
    [System.Drawing.Color]::FromArgb(6, 18, 48),
    [System.Drawing.Color]::FromArgb(1, 4, 14),
    [System.Drawing.Drawing2D.LinearGradientMode]::Vertical
)
$gfx.FillRectangle($brush, $rect)

# Trench Wall Silhouettes
$cliffBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(14, 32, 68))
$leftCliff  = [System.Drawing.Point[]]@(
    (New-Object System.Drawing.Point 0, 0),
    (New-Object System.Drawing.Point 65, 45),
    (New-Object System.Drawing.Point 50, 95),
    (New-Object System.Drawing.Point 80, 150),
    (New-Object System.Drawing.Point 0, 150)
)
$rightCliff = [System.Drawing.Point[]]@(
    (New-Object System.Drawing.Point 240, 0),
    (New-Object System.Drawing.Point 175, 45),
    (New-Object System.Drawing.Point 190, 95),
    (New-Object System.Drawing.Point 160, 150),
    (New-Object System.Drawing.Point 240, 150)
)
$gfx.FillPolygon($cliffBrush, $leftCliff)
$gfx.FillPolygon($cliffBrush, $rightCliff)

# Hydrothermal Vent Column & Glowing Plume
$glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 0, 200, 255))
$gfx.FillEllipse($glowBrush, 95, 60, 50, 85)
$cyanPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(0, 240, 255), 2)
$gfx.DrawLine($cyanPen, 120, 140, 120, 50)
$gfx.DrawLine($cyanPen, 113, 140, 108, 65)
$gfx.DrawLine($cyanPen, 127, 140, 132, 65)

# Basalt Chimney
$ventBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20, 20, 25))
$gfx.FillRectangle($ventBrush, 112, 128, 16, 22)

$bmp.Save("$innerDir\assets\abyssal_preview.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Save("$outerDir\assets\abyssal_preview.png", [System.Drawing.Imaging.ImageFormat]::Png)
$gfx.Dispose()
$bmp.Dispose()
Write-Host "Created: $innerDir\assets\abyssal_preview.png" -ForegroundColor Green

Write-Host ">>> 4. Writing helpers/AbyssalTrenchHelper.gd..." -ForegroundColor Cyan
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

		# 1. Surface buffer (Rows 0-12): Keep soft clay/coal starter ground intact
		if global_pos.y <= BUFFER_SURFACE_ROWS:
			continue

		var local_x = idx % chunk.chunk_size
		var local_y = idx / chunk.chunk_size

		# 2. Carve Submerged Trench Caverns using 2D noise
		var cave_noise: float = abs(noise.get_noise_2d(float(global_pos.x) * 3.2, float(global_pos.y) * 1.8))
		if cave_noise < 0.12 and global_pos.y > 18:
			chunk.tiles[idx] = chunk.Tiles.EMPTY
			chunk.build_tile(idx)

			# Spawn Hydrothermal Black Smoker on cavern floor
			if not vent_spawned and global_pos.y >= 28 and local_y < chunk.chunk_size - 2:
				var below_idx = idx + chunk.chunk_size
				if below_idx < chunk.tiles.size() and chunk.tiles[below_idx] != chunk.Tiles.EMPTY:
					var VentScene = load("res://mods-unpacked/gareth-abyssal_trench_mod/entities/HydrothermalVent.gd")
					if VentScene:
						var vent = VentScene.new()
						vent.position = chunk.map_to_local(Vector2i(local_x, local_y + 1))
						chunk.add_child(vent)
						vent_spawned = true
			continue

		# 3. Strata Distribution
		var tile_to_set: int = chunk.Tiles.BASIC_DARKBLUE
		var seed_val: int = abs(global_pos.x * 73856093 ^ global_pos.y * 19349663)
		var roll: int = seed_val % 100

		if global_pos.y <= 60:
			# Twilight Zone: Dark Blue Stone & Sapphires / Moonstones
			if roll < 38:
				tile_to_set = 212 # COAL_DARKBLUE
			elif roll < 56:
				tile_to_set = 215 # SAPPHIRE_DARKBLUE
			elif roll < 66:
				tile_to_set = 225 # MOONSTONE_DARKBLUE
			elif roll < 78:
				tile_to_set = 213 # COPPER_DARKBLUE
			else:
				tile_to_set = 211 # BASIC_DARKBLUE
		else:
			# Hadal Trench: Volcanic Basalt, Onyx, Supercooled Ice Crystals
			if roll < 35:
				tile_to_set = 93  # COAL_DARK
			elif roll < 54:
				tile_to_set = 107 # ONYX_DARK
			elif roll < 65:
				tile_to_set = 68  # DIAMOND_ICE
			elif roll < 78:
				tile_to_set = 98  # GOLD_DARK
			else:
				tile_to_set = 92  # BASIC_DARK

		chunk.tiles[idx] = tile_to_set
		chunk.build_tile(idx)
'@ | Set-Content -Path $helperFilePath -Encoding UTF8
Write-Host "Created: $helperFilePath" -ForegroundColor Green

Write-Host ">>> 5. Writing entities/HydrothermalVent.gd..." -ForegroundColor Cyan
@'
class_name HydrothermalVent
extends Node2D

var steam_particles: CPUParticles2D
var launch_cooldown: float = 0.0

func _ready() -> void:
	z_index = 5
	
	# Chimney Visuals
	var chimney = ColorRect.new()
	chimney.color = Color(0.12, 0.12, 0.15)
	chimney.size = Vector2(16, 24)
	chimney.position = Vector2(-8, -24)
	add_child(chimney)

	var vent_rim = ColorRect.new()
	vent_rim.color = Color(0.2, 0.22, 0.28)
	vent_rim.size = Vector2(20, 6)
	vent_rim.position = Vector2(-10, -26)
	add_child(vent_rim)

	# Upward Hydrothermal Steam Emitter
	steam_particles = CPUParticles2D.new()
	steam_particles.position = Vector2(0, -26)
	steam_particles.amount = 24
	steam_particles.lifetime = 1.6
	steam_particles.direction = Vector2(0, -1)
	steam_particles.spread = 12.0
	steam_particles.gravity = Vector2(0, -140)
	steam_particles.initial_velocity_min = 70.0
	steam_particles.initial_velocity_max = 130.0
	steam_particles.scale_amount_min = 2.5
	steam_particles.scale_amount_max = 5.0
	steam_particles.color = Color(0.65, 0.85, 1.0, 0.55)
	add_child(steam_particles)

func _physics_process(delta: float) -> void:
	if launch_cooldown > 0.0:
		launch_cooldown -= delta

	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return

	var p = players[0]
	if not is_instance_valid(p):
		return

	# Launch column: 24px wide, extends 90px vertically upward from chimney
	var diff = p.global_position - global_position
	if abs(diff.x) < 14.0 and diff.y < -10.0 and diff.y > -95.0:
		if launch_cooldown <= 0.0 and "velocity" in p:
			p.velocity.y = -680.0
			launch_cooldown = 0.35
'@ | Set-Content -Path "$innerDir\entities\HydrothermalVent.gd" -Encoding UTF8

Write-Host ">>> 6. Writing mod_main.gd..." -ForegroundColor Cyan
@'
extends Node

const MOD_ID := "gareth-abyssal_trench_mod"
const LOG_NAME := "gareth-abyssal_trench_mod"

func _init() -> void:
	ModLoaderLog.info("The Abyssal Trench Mod initializing...", LOG_NAME)
	install_hooks()

func _ready() -> void:
	var helper_script = load("res://mods-unpacked/gareth-abyssal_trench_mod/helpers/AbyssalTrenchHelper.gd")
	if helper_script:
		var helper = helper_script.new()
		if helper.has_method("ensure_level_registered"):
			helper.ensure_level_registered()
	ModLoaderLog.info("The Abyssal Trench Custom Map (ID 104) online!", LOG_NAME)

func install_hooks() -> void:
	var unpacked_dir = ModLoaderMod.get_unpacked_dir().path_join(MOD_ID)
	var ext_dir = unpacked_dir.path_join("extensions")

	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/Menus/level_select.gd",
		ext_dir.path_join("scenes/Interfaces/Menus/level_select.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/tilemaps/tile_map_chunk.gd",
		ext_dir.path_join("scenes/tilemaps/tile_map_chunk.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/Game.gd",
		ext_dir.path_join("scripts/Game.hooks.gd")
	)
'@ | Set-Content -Path "$innerDir\mod_main.gd" -Encoding UTF8

Write-Host ">>> 7. Writing extensions/.../level_select.hooks.gd..." -ForegroundColor Cyan
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-abyssal_trench_mod/helpers/AbyssalTrenchHelper.gd")
	if helper_script:
		var helper = helper_script.new()
		if helper.has_method("ensure_level_registered"):
			helper.ensure_level_registered()
		var ls = chain.reference_object
		if ls and ("LEVEL_ORDER" in ls):
			if not ls.LEVEL_ORDER.has(104):
				ls.LEVEL_ORDER.append(104)

	chain.execute_next([])
'@ | Set-Content -Path "$innerDir\extensions\scenes\Interfaces\Menus\level_select.hooks.gd" -Encoding UTF8

Write-Host ">>> 8. Writing extensions/.../tile_map_chunk.hooks.gd..." -ForegroundColor Cyan
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
		if chunk and chunk.has_method("array_to_global_pos"):
			var global_pos: Vector2i = Vector2i(chunk.array_to_global_pos(idx))
			if global_pos.y > 12 and global_pos.y <= 40:
				damage *= 2.8
	chain.execute_next([idx, damage])
'@ | Set-Content -Path "$innerDir\extensions\scenes\tilemaps\tile_map_chunk.hooks.gd" -Encoding UTF8

Write-Host ">>> 9. Writing extensions/scripts/Game.hooks.gd..." -ForegroundColor Cyan
@'
extends Object

func change_stage(chain: ModLoaderHookChain, target: int, targetPosition: Vector2) -> void:
	var game = chain.reference_object
	if target == 2 and Gvars and ("level" in Gvars) and Gvars.level == 104:
		var mine_scene = load("res://scenes/Stages/MineRegion.tscn")
		if mine_scene and game:
			game.target_stage = mine_scene

	chain.execute_next([target, targetPosition])
'@ | Set-Content -Path "$innerDir\extensions\scripts\Game.hooks.gd" -Encoding UTF8

Write-Host "`n>>> 10. Purging mod-hooks.zip to trigger re-pack..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 11. Packaging gareth-abyssal_trench_mod.zip..." -ForegroundColor Cyan
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
Write-Host "Packed release archive: $zipPath" -ForegroundColor Green

Write-Host "`n>>> 12. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Fix AbyssalTrenchHelper file path and carousel registration for Map 104"
git push origin main

Write-Host "`nDeployment complete! Launch Coal LLC to test." -ForegroundColor Green