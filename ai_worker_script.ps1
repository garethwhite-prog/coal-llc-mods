Clear-Host;

# ==============================================================================
# Coal LLC - Deploy Map 104: The Abyssal Trench (gareth-abyssal_trench_mod)
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

Write-Host ">>> 1. Creating directory structure for $modName..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path "$innerDir\helpers" -Force | Out-Null
New-Item -ItemType Directory -Path "$innerDir\assets" -Force | Out-Null
New-Item -ItemType Directory -Path "$innerDir\entities" -Force | Out-Null
New-Item -ItemType Directory -Path "$innerDir\extensions\scenes\Interfaces\Menus" -Force | Out-Null
New-Item -ItemType Directory -Path "$innerDir\extensions\scenes\tilemaps" -Force | Out-Null
New-Item -ItemType Directory -Path "$innerDir\extensions\scripts" -Force | Out-Null

Write-Host ">>> 2. Generating custom trench preview asset..." -ForegroundColor Cyan
Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap 240, 150
$gfx = [System.Drawing.Graphics]::FromImage($bmp)
$gfx.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

# Deep ocean gradient
$rect = New-Object System.Drawing.Rectangle 0, 0, 240, 150
$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect,
    [System.Drawing.Color]::FromArgb(6, 18, 42),
    [System.Drawing.Color]::FromArgb(1, 4, 12),
    [System.Drawing.Drawing2D.LinearGradientMode]::Vertical
)
$gfx.FillRectangle($brush,$rect)

# Trench cliffs
$cliffBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(12, 28, 60))
$leftCliff  = [System.Drawing.Point[]]@( (New-Object System.Drawing.Point 0, 0), (New-Object System.Drawing.Point 60, 40), (New-Object System.Drawing.Point 45, 100), (New-Object System.Drawing.Point 75, 150), (New-Object System.Drawing.Point 0, 150) )
$rightCliff = [System.Drawing.Point[]]@(
    (New-Object System.Drawing.Point 240, 0),
    (New-Object System.Drawing.Point 180, 40),
    (New-Object System.Drawing.Point 195, 100),
    (New-Object System.Drawing.Point 165, 150),
    (New-Object System.Drawing.Point 240, 150)
)
$gfx.FillPolygon($cliffBrush, $leftCliff)
$gfx.FillPolygon($cliffBrush,$rightCliff)

# Bioluminescent Sapphire Vents & Updraft glow
$glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(90, 0, 190, 255))
$gfx.FillEllipse($glowBrush, 95, 70, 50, 75)
$cyanPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(0, 240, 255), 2)
$gfx.DrawLine($cyanPen, 120, 140, 120, 60)
$gfx.DrawLine($cyanPen, 114, 140, 110, 75)
$gfx.DrawLine($cyanPen, 126, 140, 130, 75)

# Chimney
$ventBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20, 20, 25))
$gfx.FillRectangle($ventBrush, 112, 130, 16, 20)

$previewInner = "$innerDir\assets\abyssal_preview.png"
$previewOuter = "$outerDir\assets\abyssal_preview.png"
$bmp.Save($previewInner, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Save($previewOuter, [System.Drawing.Imaging.ImageFormat]::Png)
$gfx.Dispose()
$bmp.Dispose()
Write-Host "Created preview asset: $previewInner" -ForegroundColor Green

Write-Host "`n>>> 3. Writing manifest.json..." -ForegroundColor Cyan
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

Write-Host ">>> 4. Writing mod_main.gd..." -ForegroundColor Cyan
@'
extends Node

const MOD_ID := "gareth-abyssal_trench_mod"
const LOG_NAME := "gareth-abyssal_trench_mod"

func _init() -> void:
	ModLoaderLog.info("The Abyssal Trench Mod initializing...", LOG_NAME)
	install_hooks()

func _ready() -> void:
	var helper_script = load("res://mods-unpacked/gareth-abyssal_trench_mod/helpers/AbyssalTrenchHelper.gd")
	if helper_script and helper_script.has_method("ensure_level_registered"):
		helper_script.ensure_level_registered()
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

Write-Host ">>> 5. Writing entities/HydrothermalVent.gd..." -ForegroundColor Cyan
@'
class_name HydrothermalVent
extends Node2D

var steam_particles: CPUParticles2D
var trigger_area: Area2D
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

Write-Host ">>> 6. Writing helpers/AbyssalTrenchHelper.gd..." -ForegroundColor Cyan
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

static func ensure_level_registered() -> void:
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

		# 1. Surface Shallows (Rows 0-12): Keep soft clay/starter coal intact
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
'@ | Set-Content -Path $lcHelperPath -Encoding UTF8

Write-Host ">>> 7. Writing extensions/.../level_select.hooks.gd..." -ForegroundColor Cyan
$lsHookPath = "$innerDir\extensions\scenes\Interfaces\Menus\level_select.hooks.gd"

@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-abyssal_trench_mod/helpers/AbyssalTrenchHelper.gd")
	if helper_script and helper_script.has_method("ensure_level_registered"):
		helper_script.ensure_level_registered()
		var ls = chain.reference_object
		if ls and ("LEVEL_ORDER" in ls):
			if not ls.LEVEL_ORDER.has(helper_script.TRENCH_LEVEL_ID):
				ls.LEVEL_ORDER.append(helper_script.TRENCH_LEVEL_ID)

	chain.execute_next([])
'@ | Set-Content -Path $lsHookPath -Encoding UTF8

Write-Host ">>> 8. Writing extensions/.../tile_map_chunk.hooks.gd..." -ForegroundColor Cyan
$chunkHookPath = "$innerDir\extensions\scenes\tilemaps\tile_map_chunk.hooks.gd"

@'
extends Object

func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	var helper_script = load("res://mods-unpacked/gareth-abyssal_trench_mod/helpers/AbyssalTrenchHelper.gd")
	if helper_script and helper_script.is_abyssal_level():
		if pos.y < 0:
			return -2 # Sky stratum air contract
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
			# Starter tool damage balancing in upper trench
			if global_pos.y > 12 and global_pos.y <= 40:
				damage *= 2.8
	chain.execute_next([idx, damage])
'@ | Set-Content -Path $chunkHookPath -Encoding UTF8

Write-Host ">>> 9. Writing extensions/scripts/Game.hooks.gd..." -ForegroundColor Cyan
$gameHookPath = "$innerDir\extensions\scripts\Game.hooks.gd"

@'
extends Object

func change_stage(chain: ModLoaderHookChain, target: int, targetPosition: Vector2) -> void:
	var game = chain.reference_object
	if target == 2 and Gvars and ("level" in Gvars) and Gvars.level == 104:
		var mine_scene = load("res://scenes/Stages/MineRegion.tscn")
		if mine_scene and game:
			game.target_stage = mine_scene

	chain.execute_next([target, targetPosition])
'@ | Set-Content -Path $gameHookPath -Encoding UTF8

Write-Host ">>> 10. Writing README.md for gareth-abyssal_trench_mod..." -ForegroundColor Cyan
@'
# The Abyssal Trench (`gareth-abyssal_trench_mod`)

**Author:** Gareth White  
**Map ID:** 104
**Difficulty:** Hard  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
**The Abyssal Trench** drops miners into an underwater oceanic chasm. Carve through deep twilight sapphire rock, navigate submerged cavern pockets, and ride hydrothermal black smoker steam geysers back to the surface.

---

## Key Features
* **Hydrothermal Vents (Black Smokers):** Volcanic chimneys rising from cavern floors blast continuous steam updrafts. Stepping into the steam column launches the miner upward for fast vertical ascent.
* **Stratified Ocean Depth:**
  * **Rows 0�12 (Surface Shallows):** Soft clay and starter coal deposits for quota safety.
  * **Rows 13�60 (Twilight Depths):** Dense blue shale (`BASIC_DARKBLUE`), rich in sapphire and moonstone deposits.
  * **Rows 61+ (Hadal Floor):** Volcanic basalt (`BASIC_DARK`), onyx clusters, and supercooled crystalline ice.
'@ | Set-Content -Path "$outerDir\README.md" -Encoding UTF8
Copy-Item -Path "$outerDir\README.md" -Destination "$innerDir\README.md" -Force

Write-Host "`n>>> 11. Updating master SESSION_PROMPT.md & root README.md to 49 mods..." -ForegroundColor Cyan
$promptPath  = "$repo\SESSION_PROMPT.md"
$readmePath  = "$repo\README.md"

$pText = Get-Content $promptPath -Raw
if ($pText -notmatch "Map 104 - The Abyssal Trench") {
    $map104Doc = @'

### Map 104 - The Abyssal Trench (`gareth-abyssal_trench_mod`)
* **Level ID**: `104` (Registered in `level_manager.all_levels` and `Gvars.level_info`).
* **Stage Routing**: Hook `Game.gd:change_stage` on `target == 2` and `Gvars.level == 104` to load `res://scenes/Stages/MineRegion.tscn`.
* **Subterranean Generation Hook**: Hook `tile_map_chunk.gd:generate_chunk`. Maintain `pos.y < 0` returning `-2` in `lvl_from_global_pos`.
* **Strata Mapping**:
  * Rows 0�12: Vanilla soft clay/coal starter buffer.
  * Rows 13�60 (Twilight Zone): `BASIC_DARKBLUE` (211), `COAL_DARKBLUE` (212), `SAPPHIRE_DARKBLUE` (215), `MOONSTONE_DARKBLUE` (225).
  * Rows 61+ (Hadal Trench): `BASIC_DARK` (92), `COAL_DARK` (93), `ONYX_DARK` (107), `DIAMOND_ICE` (68).
* **Entities**: `HydrothermalVent.gd` spawns in carved cavern floors; emits bubbling CPUParticles2D and launches miner upward (`velocity.y = -680.0`).
* **Tool Balancing**: Upper trench blocks ($13 \le y \le 40$) receive $2.8\times$ damage in `damage_tile_idx`.
'@
    $pText += $map104Doc
    $pText = $pText -replace '48 mods', '49 mods'
    $pText = $pText -replace '48-mod', '49-mod'
    Set-Content -Path $promptPath -Value $pText -Encoding UTF8
    Write-Host "Updated: $promptPath" -ForegroundColor Green
}

$rText = Get-Content $readmePath -Raw
$rText = $rText -replace '48 mods', '49 mods'
$rText = $rText -replace '48-mod', '49-mod'
if ($rText -notmatch "gareth-abyssal_trench_mod") {
    $entry = "| `gareth-abyssal_trench_mod` | Maps & Environments | The Abyssal Trench (Map 104) - Oceanic chasm with hydrothermal black smoker geysers |"
    $rText = $rText -replace '(\| `gareth-living_canvas_mod`.*)', "`$1`r`n$entry"
    Set-Content -Path $readmePath -Value $rText -Encoding UTF8
    Write-Host "Updated: $readmePath" -ForegroundColor Green
}

Write-Host "`n>>> 12. Flushing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 13. Packaging gareth-abyssal_trench_mod.zip for Steam..." -ForegroundColor Cyan
if (Test-Path $zipPath) { Remove-Item -Path $zipPath -Force }

$stream  = [System.IO.File]::Open($zipPath, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $outerDir -Recurse -File)) {$entryName = $f.FullName.Substring($outerDir.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Write-Host "Packed archive: $zipPath" -ForegroundColor Green

Write-Host "`n>>> 14. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Implement Map 104: The Abyssal Trench with hydrothermal black smoker geysers and twilight sapphire strata (49 mods)"
git push origin main

Write-Host "`nDeployment complete! Launch Coal LLC to explore The Abyssal Trench." -ForegroundColor Green