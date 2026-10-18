Clear-Host;

# ==============================================================================
# Coal LLC - Fix Mod Manager Indentation & Living Canvas Strata Generator
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Repairing gareth-mod_manager_mod/mod_main.gd indentation..." -ForegroundColor Cyan
$mmInnerDir = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod"
$mmMainPath = "$mmInnerDir\mod_main.gd"

@'
extends Node

const MOD_ID := "gareth-mod_manager_mod"
const LOG_NAME := "gareth-mod_manager_mod"

func _init() -> void:
	ModLoaderLog.info("Universal Mod Manager initializing...", LOG_NAME)
	install_hooks()

func _ready() -> void:
	ModLoaderLog.info("Universal Mod Manager active with full Class, Shop & Input gating.", LOG_NAME)

func install_hooks() -> void:
	var unpacked_dir = ModLoaderMod.get_unpacked_dir().path_join(MOD_ID)
	var ext_dir = unpacked_dir.path_join("extensions")

	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/in_game/choose_passive.gd",
		ext_dir.path_join("scenes/Interfaces/in_game/choose_passive.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/MainMenu.gd",
		ext_dir.path_join("scripts/MainMenu.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/Gvars.gd",
		ext_dir.path_join("scripts/Gvars.hooks.gd")
	)
'@ | Set-Content -Path $mmMainPath -Encoding UTF8
Write-Host "Repaired: $mmMainPath" -ForegroundColor Green

Write-Host "`n>>> 2. Updating LivingCanvasHelper.gd to use native chunk.array_to_global_pos()..." -ForegroundColor Cyan
$lcInnerDir   = "$repo\mods-unpacked\gareth-living_canvas_mod\mods-unpacked\gareth-living_canvas_mod"
$lcHelperPath = "$lcInnerDir\helpers\LivingCanvasHelper.gd"

@'
class_name LivingCanvasHelper
extends RefCounted

const CANVAS_LEVEL_ID: int = 103
const TARGET_CANVAS_WIDTH: int = 96
const CONFIG_PATH: String = "user://living_canvas_config.json"

const PALETTE: Dictionary = {
	Color(0.85, 0.20, 0.15): 231, # HARD_FIRE
	Color(0.70, 0.90, 0.98): 230, # HARD_ICE
	Color(0.12, 0.12, 0.15): 232, # HARD_DARK
	Color(0.20, 0.78, 0.25): 233, # HARD_GREEN
	Color(0.92, 0.50, 0.12): 234, # HARD_ORANGE
	Color(0.65, 0.20, 0.85): 235, # HARD_PURPLE
	Color(0.12, 0.40, 0.15): 236, # HARD_DARKGREEN
	Color(0.95, 0.85, 0.18): 237, # HARD_YELLOW
	Color(0.40, 0.25, 0.15): 238, # HARD_DARKBROWN
	Color(0.10, 0.25, 0.70): 239, # HARD_DARKBLUE
	Color(0.50, 0.50, 0.52): 229, # HARD_STONE
	Color(0.75, 0.55, 0.45): 228, # HARD_CLAY
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
			custom_level.level_difficulty = GameLevel.Difficulty.HARD
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

	if active_path != "" and FileAccess.file_exists(active_path):
		var bytes = FileAccess.get_file_as_bytes(active_path)
		if bytes.size() > 0:
			if active_path.to_lower().ends_with(".png"):
				if img.load_png_from_buffer(bytes) == OK:
					loaded = true
			else:
				if img.load_jpg_from_buffer(bytes) == OK:
					loaded = true

	if not loaded and FileAccess.file_exists("C:/Dev/example_1.jpg"):
		var bytes = FileAccess.get_file_as_bytes("C:/Dev/example_1.jpg")
		if bytes.size() > 0 and img.load_jpg_from_buffer(bytes) == OK:
			loaded = true

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
		return 0

	var best_tile: int = 229
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
	if not ("tiles" in chunk) or not chunk.has_method("array_to_global_pos"):
		return

	var img = get_or_load_canvas()
	if not img:
		return

	var half_w: int = int(cached_width / 2.0)

	for idx in range(chunk.tiles.size()):
		var global_pos: Vector2i = Vector2i(chunk.array_to_global_pos(idx))

		# Retain surface layer (first 4 tile rows: 0, 1, 2, 3)
		if global_pos.y <= 3:
			continue

		# Outside horizontal canvas boundary: bedrock framing
		if global_pos.x < -half_w or global_pos.x >= half_w:
			if abs(global_pos.x) > half_w + 3:
				chunk.tiles[idx] = chunk.Tiles.BEDROCK
			else:
				chunk.tiles[idx] = chunk.Tiles.HARD_DARK
			chunk.build_tile(idx)
			continue

		# Inside canvas: sample downsampled image coordinates
		var img_u: int = global_pos.x + half_w
		var img_v: int = (global_pos.y - 4) % cached_height
		if img_v < 0:
			img_v += cached_height

		if img_u >= 0 and img_u < cached_width and img_v >= 0 and img_v < cached_height:
			var pixel_col: Color = img.get_pixel(img_u, img_v)
			var tile_id: int = match_tile_from_color(pixel_col)
			chunk.tiles[idx] = tile_id
			chunk.build_tile(idx)
'@ | Set-Content -Path $lcHelperPath -Encoding UTF8
Write-Host "Updated: $lcHelperPath" -ForegroundColor Green

Write-Host "`n>>> 3. Updating tile_map_chunk.hooks.gd..." -ForegroundColor Cyan
$chunkHookPath = "$lcInnerDir\extensions\scenes\tilemaps\tile_map_chunk.hooks.gd"

@'
extends Object

func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
	if helper_script and helper_script.is_canvas_level():
		if pos.y < 0:
			return -2
		return 1
	return chain.execute_next([pos])

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	chain.execute_next([noise])
	var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
	if helper_script and helper_script.is_canvas_level():
		var chunk = chain.reference_object
		if chunk:
			helper_script.paint_chunk_from_canvas(chunk)
'@ | Set-Content -Path $chunkHookPath -Encoding UTF8
Write-Host "Updated: $chunkHookPath" -ForegroundColor Green

Write-Host "`n>>> 4. Flushing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 5. Repackaging living_canvas_mod.zip and mod_manager_mod.zip..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($mTarget in @("gareth-living_canvas_mod", "gareth-mod_manager_mod")) {
    $mOuter = "$repo\mods-unpacked\$mTarget"
    $mZip   = "$steamMods\$mTarget.zip"
    if (Test-Path $mZip) { Remove-Item -Path $mZip -Force }

    $stream  = [System.IO.File]::Open($mZip, [System.IO.FileMode]::CreateNew)
    $archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
    foreach ($f in (Get-ChildItem -Path $mOuter -Recurse -File)) {$entryName = $f.FullName.Substring($mOuter.Length + 1).Replace("\", "/")
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
    }
    $archive.Dispose()
	$stream.Dispose()
    Write-Host "Repacked: $mZip" -ForegroundColor Green
}

Write-Host "`n>>> 6. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Fix Mod Manager indentation error and switch Living Canvas to native chunk.array_to_global_pos"
git push origin main

Write-Host "`nAll fixes applied! Launch Coal LLC to test." -ForegroundColor Green