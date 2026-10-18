Clear-Host;

# ==============================================================================
# Coal LLC - Universal Baseline Image Conversion & GDScript Filter Fix
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

$lcInnerDir = "$repo\mods-unpacked\gareth-living_canvas_mod\mods-unpacked\gareth-living_canvas_mod"
$mmInnerDir = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod"

Set-Location $repo

Write-Host ">>> 1. Converting ALL C:\Dev\example_*.jpg images to baseline JPEG and PNG..." -ForegroundColor Cyan
Add-Type -AssemblyName System.Drawing

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object {$_.MimeType -eq "image/jpeg" }
$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]95)

$devImages = Get-ChildItem -Path "C:\Dev" -Filter "example_*.jpg"
foreach ($imgFile in $devImages) {
    try {
        $srcImg = [System.Drawing.Image]::FromFile($imgFile.FullName)
		$bmpCopy = New-Object System.Drawing.Bitmap($srcImg)$srcImg.Dispose()

        # Save sibling PNG
        $pngPath = [System.IO.Path]::ChangeExtension($imgFile.FullName, ".png")
        $bmpCopy.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)

        # Overwrite JPG as standard baseline JPEG
        $bmpCopy.Save($imgFile.FullName, $jpegCodec, $encoderParams)
		$bmpCopy.Dispose()
        Write-Host "Processed: $($imgFile.Name) -> Baseline JPEG + PNG" -ForegroundColor Green
    } catch {
        Write-Host "Warning: Could not process $($imgFile.Name):$_" -ForegroundColor Yellow
    }
}

Write-Host "`n>>> 2. Updating LivingCanvasHelper.gd (live memory sync & path normalization)..." -ForegroundColor Cyan
$lcHelperPath = "$lcInnerDir\helpers\LivingCanvasHelper.gd"

@'
class_name LivingCanvasHelper
extends RefCounted

const CANVAS_LEVEL_ID: int = 103
const TARGET_CANVAS_WIDTH: int = 96
const CONFIG_PATH: String = "user://living_canvas_config.json"
const BUFFER_SURFACE_ROWS: int = 12

const STRATA_BASES: Dictionary = {
	Color(0.85, 0.20, 0.15): 75,  # FIRE family
	Color(0.70, 0.90, 0.98): 58,  # ICE family
	Color(0.12, 0.12, 0.15): 92,  # DARK family
	Color(0.20, 0.78, 0.25): 109, # GREEN family
	Color(0.92, 0.50, 0.12): 126, # ORANGE family
	Color(0.65, 0.20, 0.85): 143, # PURPLE family
	Color(0.12, 0.40, 0.15): 160, # DARKGREEN family
	Color(0.95, 0.85, 0.18): 177, # YELLOW family
	Color(0.40, 0.25, 0.15): 194, # DARKBROWN family
	Color(0.10, 0.25, 0.70): 211, # DARKBLUE family
	Color(0.50, 0.50, 0.52): 41,  # STONE family
	Color(0.75, 0.55, 0.45): 24,  # CLAY family
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
				return str(json.data.get("image_path", "")).replace("\\", "/")
	return ""

static func set_active_image(path: String) -> void:
	path = path.replace("\\", "/")
	var cfg = {"image_path": path}
	var file = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(cfg))
	cached_image = null
	var new_img = get_or_load_canvas()
	
	# Instantly synchronize in-memory level registration
	if new_img and Gvars and ("level_manager" in Gvars) and Gvars.level_manager:
		var lvl_mgr = Gvars.level_manager
		if "all_levels" in lvl_mgr and lvl_mgr.all_levels.has(CANVAS_LEVEL_ID):
			var new_tex = ImageTexture.create_from_image(new_img)
			lvl_mgr.all_levels[CANVAS_LEVEL_ID]["level"].level_image = new_tex

	ModLoaderLog.info("Active image updated to: " + path, "gareth-living_canvas_mod")

static func load_image_from_path(path: String) -> Image:
	path = path.replace("\\", "/")
	if not FileAccess.file_exists(path):
		return null
	var bytes = FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null

	var img = Image.new()
	var err: Error = FAILED
	var p_lower = path.to_lower()

	if p_lower.ends_with(".png"):
		err = img.load_png_from_buffer(bytes)
	elif p_lower.ends_with(".webp"):
		err = img.load_webp_from_buffer(bytes)
	else:
		err = img.load_jpg_from_buffer(bytes)
		if err != OK:
			err = img.load_png_from_buffer(bytes)

	if err == OK:
		return img
	return null

static func get_or_load_canvas() -> Image:
	if cached_image != null:
		return cached_image

	var img: Image = null
	var active_path = get_saved_image_path()

	# 1. Try saved user path
	if active_path != "":
		img = load_image_from_path(active_path)
		# Sibling PNG fallback
		if not img:
			var alt_png = active_path.get_basename() + ".png"
			if FileAccess.file_exists(alt_png):
				img = load_image_from_path(alt_png)

	# 2. Try example_4 or example_1 if no valid user selection exists
	if not img and FileAccess.file_exists("C:/Dev/example_4.png"):
		img = load_image_from_path("C:/Dev/example_4.png")
	if not img and FileAccess.file_exists("C:/Dev/example_1.png"):
		img = load_image_from_path("C:/Dev/example_1.png")
	if not img and FileAccess.file_exists("C:/Dev/example_1.jpg"):
		img = load_image_from_path("C:/Dev/example_1.jpg")

	# 3. Fallback procedural canvas
	if not img:
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
		return 0

	var best_base: int = 41
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

	var seed_val: int = abs(world_pos.x * 73856093 ^ world_pos.y * 19349663)
	var roll: int = seed_val % 100

	# 45% Coal, 25% Ore, 30% Base
	if roll < 45:
		return base_id + 1
	elif roll < 70:
		var ore_offset = 2 + (seed_val % 10)
		return base_id + min(ore_offset, 15)
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

		if global_pos.y <= BUFFER_SURFACE_ROWS:
			continue

		var dist_from_center: int = abs(global_pos.x)
		if dist_from_center >= half_w and dist_from_center < half_w + 8:
			if (global_pos.x + global_pos.y) % 5 == 0:
				chunk.tiles[idx] = chunk.Tiles.COAL_STONE
			else:
				chunk.tiles[idx] = chunk.Tiles.BASIC_STONE
			chunk.build_tile(idx)
			continue

		if dist_from_center >= half_w + 8:
			chunk.tiles[idx] = chunk.Tiles.BEDROCK
			chunk.build_tile(idx)
			continue

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

Write-Host "`n>>> 3. Updating level_select.hooks.gd (live visual refresh without restart)..." -ForegroundColor Cyan
$lsHookPath = "$lcInnerDir\extensions\scenes\Interfaces\Menus\level_select.hooks.gd"

@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
	if helper_script and helper_script.has_method("ensure_level_registered"):
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
	var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
	var active_path = helper_script.get_saved_image_path() if helper_script else ""
	var initial_label = "[ Choose Image ]"
	if active_path != "":
		initial_label = "[ " + active_path.get_file() + " ]"

	var btn = Button.new()
	btn.text = initial_label
	btn.custom_minimum_size = Vector2(140, 26)
	btn.add_theme_font_size_override("font_size", 9)
	btn.focus_mode = Control.FOCUS_NONE
	card.add_child(btn)
	btn.position = Vector2(10, 180)

	btn.pressed.connect(func():
		var dialog = FileDialog.new()
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.filters = PackedStringArray(["*.jpg, *.jpeg, *.png, *.webp ; Image Files"])
		dialog.current_dir = "C:/Dev"
		dialog.title = "Select Image for The Living Canvas"
		if "use_native_dialog" in dialog:
			dialog.set("use_native_dialog", true)

		dialog.file_selected.connect(func(path: String):
			path = path.replace("\\", "/")
			if helper_script and helper_script.has_method("set_active_image"):
				helper_script.set_active_image(path)
				btn.text = "[ " + path.get_file() + " ]"
				
				var new_tex = helper_script.get_preview_texture()
				if new_tex:
					card.game_level.level_image = new_tex
					for child in card.find_children("*", "TextureRect", true, false):
						if child.name != "Lock":
							child.texture = new_tex
		)

		ls.add_child(dialog)
		dialog.popup_centered(Vector2i(800, 500))
	)
'@ | Set-Content -Path $lsHookPath -Encoding UTF8
Write-Host "Updated level_select.hooks.gd" -ForegroundColor Green

Write-Host "`n>>> 4. Updating management_screen.hooks.gd (fixing syntax & adding Void Cores)..." -ForegroundColor Cyan
$mgmtHook = "$mmInnerDir\extensions\scenes\Stages\management_screen.hooks.gd"

@'
extends Object

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var screen = chain.reference_object
	if screen:
		Callable(self, "_filter_cards").call_deferred(screen)

func _filter_cards(screen: Node) -> void:
	if not is_instance_valid(screen):
		return

	var prof = Gvars.profession if ("profession" in Gvars and Gvars.profession) else null
	var prof_name: String = ""
	if prof:
		if "profession_name" in prof:
			prof_name = str(prof.profession_name)
		elif "title" in prof:
			prof_name = str(prof.title)
		elif "name" in prof:
			prof_name = str(prof.name)

	# When playing Internship or no custom class, hide all modded class weapons
	if prof_name == "Internship" or prof_name == "" or prof_name.begins_with("@"):
		var container = null
		if "equipment_items" in screen and screen.equipment_items:
			container = screen.equipment_items
		else:
			for c in screen.find_children("*", "GridContainer", true, false):
				container = c
				break

		if container:
			for card in container.get_children():
				var txt: String = ""
				for lbl in card.find_children("*", "Label", true, false):
					txt += " " + lbl.text
				if "item" in card and card.item and "itemName" in card.item:
					txt += " " + str(card.item.itemName)

				# Use GDScript 'in' operator to avoid .contains() parse errors
				var is_mod_weapon: bool = (
					("Tectonic Fracker" in txt) or
					("Void Core" in txt) or
					("Optical Emitter" in txt) or
					("Broadsword" in txt) or
					("Energy Saber" in txt) or
					("Laser Beam" in txt)
				)

				if is_mod_weapon:
					card.visible = false
					card.process_mode = Node.PROCESS_MODE_DISABLED
'@ | Set-Content -Path $mgmtHook -Encoding UTF8
Write-Host "Updated management_screen.hooks.gd" -ForegroundColor Green

Write-Host "`n>>> 5. Flushing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 6. Repackaging living_canvas_mod.zip and mod_manager_mod.zip..." -ForegroundColor Cyan
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

Write-Host "`n>>> 7. Git staging and committing..." -ForegroundColor Cyan
git add -A
git commit -m "Convert all C:/Dev images to baseline JPEG/PNG, fix GDScript 'in' string filter, and support live canvas switching without restart"
git push origin main

Write-Host "`nAll fixes applied! Launch Coal LLC to test." -ForegroundColor Green