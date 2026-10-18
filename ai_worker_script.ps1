Clear-Host;

# ==============================================================================
# Coal LLC - Deploy Map 103: The Living Canvas (gareth-living_canvas_mod)
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

$modName    = "gareth-living_canvas_mod"
$outerDir   = "$repo\mods-unpacked\$modName"
$innerDir   = "$outerDir\mods-unpacked\$modName"
$zipPath    = "$steamMods\$modName.zip"

Set-Location $repo

Write-Host ">>> 1. Creating directory structure for $modName..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path "$innerDir\helpers" -Force | Out-Null
New-Item -ItemType Directory -Path "$innerDir\assets" -Force | Out-Null
New-Item -ItemType Directory -Path "$innerDir\extensions\scenes\Interfaces\Menus" -Force | Out-Null
New-Item -ItemType Directory -Path "$innerDir\extensions\scenes\tilemaps" -Force | Out-Null

Write-Host ">>> 2. Writing manifest.json..." -ForegroundColor Cyan
@'
{
  "name": "living_canvas_mod",
  "namespace": "gareth",
  "version_number": "1.0.0",
  "description": "Custom subterranean map sculpted directly from real images, photos, and Minecraft screenshots with an in-game file picker.",
  "website_url": "https://github.com/garethwhite-prog/coal-llc-mods",
  "dependencies": [],
  "extra": {
    "godot": {
      "display_name": "The Living Canvas",
      "category": "Maps & Environments",
      "authors": ["Gareth White"],
      "tags": ["map", "canvas", "image", "creative"],
      "compatible_mod_loader_version": ["7.0.1"],
      "compatible_game_version": ["1.4.1.1"]
    }
  }
}
'@ | Set-Content -Path "$outerDir\manifest.json" -Encoding UTF8
Copy-Item -Path "$outerDir\manifest.json" -Destination "$innerDir\manifest.json" -Force

Write-Host ">>> 3. Writing mod_main.gd..." -ForegroundColor Cyan
@'
extends Node

const MOD_ID := "gareth-living_canvas_mod"
const LOG_NAME := "gareth-living_canvas_mod"

func _init() -> void:
	ModLoaderLog.info("The Living Canvas Mod initializing...", LOG_NAME)
	install_hooks()

func _ready() -> void:
	var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
	if helper_script:
		helper_script.ensure_level_registered()
	ModLoaderLog.info("The Living Canvas Custom Map (ID 103) online!", LOG_NAME)

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
'@ | Set-Content -Path "$innerDir\mod_main.gd" -Encoding UTF8

Write-Host ">>> 4. Writing helpers/LivingCanvasHelper.gd..." -ForegroundColor Cyan
@'
class_name LivingCanvasHelper
extends RefCounted

const CANVAS_LEVEL_ID: int = 103
const TARGET_CANVAS_WIDTH: int = 96
const CONFIG_PATH: String = "user://living_canvas_config.json"

# Palette: Color -> Tile Enum ID
const PALETTE: Dictionary = {
	Color(0.85, 0.20, 0.15): 231, # HARD_FIRE (Red / Lava / Netherrack)
	Color(0.70, 0.90, 0.98): 230, # HARD_ICE (Cyan / Snow / Sky)
	Color(0.12, 0.12, 0.15): 232, # HARD_DARK (Black / Obsidian / Deep Shadows)
	Color(0.20, 0.78, 0.25): 233, # HARD_GREEN (Bright Emerald / Grass / Leaves)
	Color(0.92, 0.50, 0.12): 234, # HARD_ORANGE (Amber / Dirt / Copper)
	Color(0.65, 0.20, 0.85): 235, # HARD_PURPLE (Violet / Portal)
	Color(0.12, 0.40, 0.15): 236, # HARD_DARKGREEN (Deep Forest / Pine / Spruce)
	Color(0.95, 0.85, 0.18): 237, # HARD_YELLOW (Gold / Sand / Sunlight)
	Color(0.40, 0.25, 0.15): 238, # HARD_DARKBROWN (Wood / Mud / Bark)
	Color(0.10, 0.25, 0.70): 239, # HARD_DARKBLUE (Water / Deep Ocean)
	Color(0.50, 0.50, 0.52): 229, # HARD_STONE (Stone / Cobblestone)
	Color(0.75, 0.55, 0.45): 228, # HARD_CLAY (Clay / Terracotta)
}

static var cached_image: Image = null
static var cached_width: int = 96
static var cached_height: int = 49

static func is_canvas_level() -> bool:
	if Gvars:
		if "level" in Gvars and Gvars.level == CANVAS_LEVEL_ID:
			return true
		if "chosen_level" in Gvars and Gvars.chosen_level == CANVAS_LEVEL_ID:
			return true
		if "current_level" in Gvars and Gvars.current_level == CANVAS_LEVEL_ID:
			return true
	return false

static func ensure_level_registered() -> void:
	if not Gvars:
		return

	if "level_manager" in Gvars and Gvars.level_manager and ("all_levels" in Gvars.level_manager):
		var lvl_mgr = Gvars.level_manager
		if not lvl_mgr.all_levels.has(CANVAS_LEVEL_ID):
			var custom_level = GameLevel.new()
			custom_level.level_name = "The Living Canvas"
			custom_level.level = CANVAS_LEVEL_ID
			custom_level.mining_scene_path = "res://scenes/Stages/MineRegion.tscn"
			custom_level.level_description = "Subterranean strata sculpted directly from a real image or screenshot.\n\nMine your way through pixel-perfect mineral landscapes."
			custom_level.level_difficulty = GameLevel.Difficulty.MEDIUM
			custom_level.unlock_description = ""

			var preview_tex = get_preview_texture()
			if preview_tex:
				custom_level.level_image = preview_tex

			lvl_mgr.all_levels[CANVAS_LEVEL_ID] = {
				"level": custom_level,
				"is_unlocked": true
			}

	if "level_info" in Gvars and Gvars.level_info is Dictionary:
		if not Gvars.level_info.has(CANVAS_LEVEL_ID):
			Gvars.level_info[CANVAS_LEVEL_ID] = {
				"name": "The Living Canvas",
				"description": "Subterranean strata sculpted directly from real images or screenshots.",
				"depth": 1000,
				"cost": 0,
				"unlocked": true
			}

static func get_saved_image_path() -> String:
	if FileAccess.file_exists(CONFIG_PATH):
		var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
		if file:
			var txt = file.get_as_text()
			var json = JSON.new()
			if json.parse(txt) == OK and json.data is Dictionary:
				return json.data.get("image_path", "")
	return ""

static func set_active_image(path: String) -> void:
	var cfg = {"image_path": path}
	var file = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(cfg))
	cached_image = null
	get_or_load_canvas()
	ModLoaderLog.info("Active image updated to: " + path, "gareth-living_canvas_mod")

static func get_or_load_canvas() -> Image:
	if cached_image != null:
		return cached_image

	var img: Image = Image.new()
	var loaded: bool = false
	var active_path = get_saved_image_path()

	# 1. Load user selected image from config
	if active_path != "" and FileAccess.file_exists(active_path):
		var bytes = FileAccess.get_file_as_bytes(active_path)
		if bytes.size() > 0:
			if active_path.to_lower().ends_with(".png"):
				if img.load_png_from_buffer(bytes) == OK:
					loaded = true
			else:
				if img.load_jpg_from_buffer(bytes) == OK:
					loaded = true

	# 2. Default fallback to C:/Dev/example_1.jpg if present
	if not loaded and FileAccess.file_exists("C:/Dev/example_1.jpg"):
		var bytes = FileAccess.get_file_as_bytes("C:/Dev/example_1.jpg")
		if bytes.size() > 0 and img.load_jpg_from_buffer(bytes) == OK:
			loaded = true

	# 3. Fallback procedural mosaic if no files found
	if not loaded:
		img = _generate_fallback_canvas()
	else:
		var orig_w = img.get_width()
		var orig_h = img.get_height()
		var aspect = float(orig_w) / float(max(1, orig_h))
		cached_width = TARGET_CANVAS_WIDTH
		cached_height = max(16, int(round(float(cached_width) / aspect)))
		img.resize(cached_width, cached_height, Image.INTERPOLATE_LANCZOS)

	cached_image = img
	return cached_image

static func get_preview_texture() -> ImageTexture:
	var img = get_or_load_canvas()
	if img:
		return ImageTexture.create_from_image(img)
	return null

static func _generate_fallback_canvas() -> Image:
	var img = Image.create(TARGET_CANVAS_WIDTH, 48, false, Image.FORMAT_RGBA8)
	cached_width = TARGET_CANVAS_WIDTH
	cached_height = 48
	for x in range(TARGET_CANVAS_WIDTH):
		for y in range(48):
			var r = sin(float(x) * 0.1) * 0.5 + 0.5
			var g = cos(float(y) * 0.15) * 0.5 + 0.5
			var b = sin(float(x + y) * 0.08) * 0.5 + 0.5
			img.set_pixel(x, y, Color(r, g, b, 1.0))
	return img

static func match_tile_from_color(col: Color) -> int:
	if col.a < 0.2:
		return 0 # Tiles.EMPTY

	var best_tile: int = 229 # Default HARD_STONE
	var min_dist: float = 999999.0

	for p_col in PALETTE.keys():
		var dr = col.r - p_col.r
		var dg = col.g - p_col.g
		var db = col.b - p_col.b
		var dist = dr * dr + dg * dg + db * db
		if dist < min_dist:
			min_dist = dist
			best_tile = PALETTE[p_col]

	return best_tile

static func paint_chunk_from_canvas(chunk: Node) -> void:
	if not ("tiles" in chunk) or not ("chunk_size" in chunk):
		return

	var img = get_or_load_canvas()
	if not img:
		return

	var half_w = int(cached_width / 2.0)

	for x in range(chunk.chunk_size):
		for y in range(chunk.chunk_size):
			var local_pos = Vector2i(x, y)
			var global_pos: Vector2i = Vector2i(chunk.to_global(chunk.map_to_local(local_pos)) / 16.0)

			# Keep top rows intact for spawn grass and player foothold
			if global_pos.y <= 3:
				continue

			var idx: int = chunk.pos_to_array(local_pos) if chunk.has_method("pos_to_array") else (x + y * chunk.chunk_size)
			if idx < 0 or idx >= chunk.tiles.size():
				continue

			# Outside canvas horizontal width: generate framing bedrock or dark slate
			if global_pos.x < -half_w or global_pos.x >= half_w:
				if abs(global_pos.x) > half_w + 3:
					chunk.tiles[idx] = chunk.Tiles.BEDROCK
				else:
					chunk.tiles[idx] = chunk.Tiles.HARD_DARK
				chunk.build_tile(idx)
				continue

			# Inside canvas area: sample downsampled image coordinates
			var img_u = global_pos.x + half_w
			var img_v = (global_pos.y - 4) % cached_height
			if img_v < 0:
				img_v += cached_height

			if img_u >= 0 and img_u < cached_width and img_v >= 0 and img_v < cached_height:
				var pixel_col = img.get_pixel(img_u, img_v)
				var tile_id = match_tile_from_color(pixel_col)
				chunk.tiles[idx] = tile_id
				chunk.build_tile(idx)
'@ | Set-Content -Path "$innerDir\helpers\LivingCanvasHelper.gd" -Encoding UTF8

Write-Host ">>> 5. Writing extensions/.../level_select.hooks.gd..." -ForegroundColor Cyan
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
	if helper_script:
		helper_script.ensure_level_registered()
		var ls = chain.reference_object
		if ls and ("LEVEL_ORDER" in ls):
			if not ls.LEVEL_ORDER.has(helper_script.CANVAS_LEVEL_ID):
				ls.LEVEL_ORDER.append(helper_script.CANVAS_LEVEL_ID)

	chain.execute_next([])

	var ls = chain.reference_object
	if ls and "levels" in ls and ls.levels:
		for card in ls.levels.get_children():
			if "game_level" in card and card.game_level and card.game_level.level == 103:
				_inject_canvas_button(ls, card)

func _inject_canvas_button(ls: Control, card: Control) -> void:
	var btn = Button.new()
	btn.text = "??? Choose Image"
	btn.custom_minimum_size = Vector2(130, 28)
	btn.add_theme_font_size_override("font_size", 10)
	btn.focus_mode = Control.FOCUS_NONE
	card.add_child(btn)
	btn.position = Vector2(12, 175)

	btn.pressed.connect(func():
		var dialog = FileDialog.new()
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.filters = PackedStringArray(["*.jpg, *.jpeg, *.png ; Image Files"])
		dialog.current_dir = "C:/Dev"
		dialog.title = "Select Image for The Living Canvas"
		dialog.use_native_dialog = true

		dialog.file_selected.connect(func(path: String):
			var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
			if helper_script:
				helper_script.set_active_image(path)
				var new_tex = helper_script.get_preview_texture()
				if new_tex and "level_image" in card and card.level_image:
					card.level_image.texture = new_tex
		)

		ls.add_child(dialog)
		dialog.popup_centered(Vector2i(850, 550))
	)
'@ | Set-Content -Path "$innerDir\extensions\scenes\Interfaces\Menus\level_select.hooks.gd" -Encoding UTF8

Write-Host ">>> 6. Writing extensions/.../tile_map_chunk.hooks.gd..." -ForegroundColor Cyan
@'
extends Object

func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	if Gvars and ("level" in Gvars) and Gvars.level == 103:
		if pos.y < 0:
			return -2 # Sky stratum air contract
		return 1
	return chain.execute_next([pos])

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	chain.execute_next([noise])
	if Gvars and ("level" in Gvars) and Gvars.level == 103:
		var chunk = chain.reference_object
		if chunk and "chunk_pos" in chunk and chunk.chunk_pos.y >= 0:
			var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
			if helper_script:
				helper_script.paint_chunk_from_canvas(chunk)
'@ | Set-Content -Path "$innerDir\extensions\scenes\tilemaps\tile_map_chunk.hooks.gd" -Encoding UTF8

Write-Host ">>> 7. Writing README.md for gareth-living_canvas_mod..." -ForegroundColor Cyan
@'
# The Living Canvas (`gareth-living_canvas_mod`)

**Author:** Gareth White  
**Map ID:** 103  
**Difficulty:** Medium  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
**The Living Canvas** transforms subterranean strata into a playable mosaic sculpted directly from real images, photos, or screenshots. Using an intelligent Euclidean color quantization algorithm, pixels are converted into corresponding rock strata (`HARD_FIRE`, `HARD_ICE`, `HARD_GREEN`, `HARD_DARKBLUE`, etc.).

---

## Key Features
* **In-Game Image Picker:** Click the **??? Choose Image** button on the level card to open a native Windows file dialog and load any PNG or JPEG.
* **Auto-Downsampling:** Automatically downsamples large 1080p and 4K images to a 96-tile shaft width while preserving original aspect ratios.
* **Seamless Strata Looping:** Digging deep through the shaft smoothly loops the landscape pattern.
* **Bedrock Framing:** Borders beyond the canvas are encased in bedrock and dark slate to frame the subterranean artwork.
'@ | Set-Content -Path "$outerDir\README.md" -Encoding UTF8
Copy-Item -Path "$outerDir\README.md" -Destination "$innerDir\README.md" -Force

Write-Host "`n>>> 8. Flushing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 9. Packaging gareth-living_canvas_mod.zip for Steam..." -ForegroundColor Cyan
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
Write-Host "Packed archive: $zipPath" -ForegroundColor Green

Write-Host "`n>>> 10. Staging, committing, and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Implement Map 103: The Living Canvas with Euclidean image-to-strata engine and in-game file picker"
git push origin main

Write-Host "`nDeployment complete! Launch Coal LLC to test The Living Canvas." -ForegroundColor Green