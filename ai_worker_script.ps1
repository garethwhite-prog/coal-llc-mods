Clear-Host;

# ==============================================================================
# Coal LLC - Fix Living Canvas Ore Drops & Equipment Shop Filter
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

$lcInnerDir = "$repo\mods-unpacked\gareth-living_canvas_mod\mods-unpacked\gareth-living_canvas_mod"
$mmInnerDir = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod"

Set-Location $repo

Write-Host ">>> 1. Updating LivingCanvasHelper.gd with Ore & Coal Infusion..." -ForegroundColor Cyan
$lcHelperPath = "$lcInnerDir\helpers\LivingCanvasHelper.gd"

@'
class_name LivingCanvasHelper
extends RefCounted

const CANVAS_LEVEL_ID: int = 103
const TARGET_CANVAS_WIDTH: int = 96
const CONFIG_PATH: String = "user://living_canvas_config.json"
const BUFFER_SURFACE_ROWS: int = 12

# Base Tile IDs for each stratum family:
# Index +0 = BASIC (No drop)
# Index +1 = COAL (Drops Coal)
# Index +2..15 = Ores (Copper, Iron, Gems, Gold, Diamond, etc.)
const STRATA_BASES: Dictionary = {
	Color(0.85, 0.20, 0.15): 75,  # FIRE family (Ruby/Lava)
	Color(0.70, 0.90, 0.98): 58,  # ICE family (Diamond/Sky)
	Color(0.12, 0.12, 0.15): 92,  # DARK family (Onyx/Shadows)
	Color(0.20, 0.78, 0.25): 109, # GREEN family (Emerald/Foliage)
	Color(0.92, 0.50, 0.12): 126, # ORANGE family (Copper/Amber)
	Color(0.65, 0.20, 0.85): 143, # PURPLE family (Amethyst)
	Color(0.12, 0.40, 0.15): 160, # DARKGREEN family (Uranium/Pine)
	Color(0.95, 0.85, 0.18): 177, # YELLOW family (Gold/Sunlight)
	Color(0.40, 0.25, 0.15): 194, # DARKBROWN family (Wood/Mud)
	Color(0.10, 0.25, 0.70): 211, # DARKBLUE family (Sapphire/Water)
	Color(0.50, 0.50, 0.52): 41,  # STONE family (Silver/Granite)
	Color(0.75, 0.55, 0.45): 24,  # CLAY family (Clay/Terracotta)
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

static func match_strata_base(col: Color) -> int:
	if col.a < 0.2:
		return 0 # Tiles.EMPTY

	var best_base: int = 41 # Default STONE family
	var min_dist: float = 999999.0

	for p_col in STRATA_BASES.keys():
		var dr = col.r - p_col.r
		var dg = col.g - p_col.g
		var db = col.b - p_col.b
		var dist = dr * dr + dg * dg + db * db
		if dist < min_dist:
			min_dist = dist
			best_base = STRATA_BASES[p_col]

	return best_base

static func pick_ore_infused_tile(base_id: int, world_pos: Vector2i) -> int:
	if base_id == 0:
		return 0

	# Deterministic hash so tile types are consistent per coordinate
	var seed_val: int = abs(world_pos.x * 73856093 ^ world_pos.y * 19349663)
	var roll: int = seed_val % 100

	# 45% Chance: Coal Ore (Index +1)
	if roll < 45:
		return base_id + 1

	# 25% Chance: Precious Metal / Gem Ore matching this stratum
	elif roll < 70:
		var ore_offset = 2 + (seed_val % 10) # Offsets +2 to +11 (Iron, Gold, Ruby, Diamond, etc.)
		return base_id + min(ore_offset, 15)

	# 30% Chance: Standard base stratum stone
	return base_id

static func paint_chunk_from_canvas(chunk: Node) -> void:
	if not ("tiles" in chunk) or not chunk.has_method("array_to_global_pos"):
		return

	var img = get_or_load_canvas()
	if not img:
		return

	var half_w: int = int(cached_width / 2.0)

	for idx in range(chunk.tiles.size()):
		var global_pos: Vector2i = Vector2i(chunk.array_to_global_pos(idx))

		# 1. Surface Buffer (Rows 0 to 12): Retain standard ground and coal
		if global_pos.y <= BUFFER_SURFACE_ROWS:
			continue

		# 2. Flanking Quarries (8 blocks wide on left & right): breakable coal/stone
		var dist_from_center: int = abs(global_pos.x)
		if dist_from_center >= half_w and dist_from_center < half_w + 8:
			if (global_pos.x + global_pos.y) % 5 == 0:
				chunk.tiles[idx] = chunk.Tiles.COAL_STONE
			else:
				chunk.tiles[idx] = chunk.Tiles.BASIC_STONE
			chunk.build_tile(idx)
			continue

		# 3. Outer boundary: Bedrock
		if dist_from_center >= half_w + 8:
			chunk.tiles[idx] = chunk.Tiles.BEDROCK
			chunk.build_tile(idx)
			continue

		# 4. Canvas Interior: Sample pixel and assign coal/ore-bearing tile
		var img_u: int = global_pos.x + half_w
		var img_v: int = (global_pos.y - (BUFFER_SURFACE_ROWS + 1)) % cached_height
		if img_v < 0:
			img_v += cached_height

		if img_u >= 0 and img_u < cached_width and img_v >= 0 and img_v < cached_height:
			var pixel_col: Color = img.get_pixel(img_u, img_v)
			var base_id: int = match_strata_base(pixel_col)
			var final_tile: int = pick_ore_infused_tile(base_id, global_pos)
			chunk.tiles[idx] = final_tile
			chunk.build_tile(idx)
'@ | Set-Content -Path $lcHelperPath -Encoding UTF8
Write-Host "Updated LivingCanvasHelper.gd" -ForegroundColor Green

Write-Host "`n>>> 2. Rewriting management_screen.hooks.gd with working Callable filter..." -ForegroundColor Cyan
$mgmtHook = "$mmInnerDir\extensions\scenes\Stages\management_screen.hooks.gd"

@'
extends Object

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var screen = chain.reference_object
	if screen:
		Callable(self, "_filter_shop_cards").call_deferred(screen)

func _filter_shop_cards(screen: Node) -> void:
	var prof = Gvars.profession if ("profession" in Gvars and Gvars.profession) else null
	var prof_name: String = prof.name if (prof and "name" in prof) else ""

	if prof_name == "Internship" or prof_name == "":
		if not is_instance_valid(screen):
			return

		var tooltips = screen.find_children("*", "EmployeeShopTooltip", true, false)
		for card in tooltips:
			if "item" in card and card.item:
				var item_name: String = card.item.itemName if ("itemName" in card.item) else ""
				if item_name.contains("Optical Emitter") or item_name.contains("Tectonic Fracker") or item_name.contains("Broadsword") or item_name.contains("Energy Saber"):
					card.visible = false
					card.process_mode = Node.PROCESS_MODE_DISABLED
'@ | Set-Content -Path $mgmtHook -Encoding UTF8
Write-Host "Updated management_screen.hooks.gd" -ForegroundColor Green

Write-Host "`n>>> 3. Flushing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 4. Repackaging living_canvas_mod.zip and mod_manager_mod.zip..." -ForegroundColor Cyan
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

Write-Host "`n>>> 5. Git staging and committing..." -ForegroundColor Cyan
git add -A
git commit -m "Implement ore and coal infusion for Living Canvas tiles and fix deferred shop filter"
git push origin main

Write-Host "`nPatch applied successfully! Launch Coal LLC to test." -ForegroundColor Green