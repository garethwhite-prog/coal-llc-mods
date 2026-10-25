class_name DiagonalMapHelper
extends RefCounted

const DIAGONAL_LEVEL_ID: int = 105
const PREVIEW_PATH: String = "res://mods-unpacked/gareth-diagonal_map_mod/assets/diagonal_preview.png"

static func ensure_level_registered() -> void:
	if not Gvars or not ("level_manager" in Gvars) or not Gvars.level_manager:
		return

	var lvl_mgr = Gvars.level_manager
	if "all_levels" in lvl_mgr and not lvl_mgr.all_levels.has(DIAGONAL_LEVEL_ID):
		var custom_level = GameLevel.new()
		custom_level.level_name = "Diagonal Seams"
		custom_level.level = DIAGONAL_LEVEL_ID
		custom_level.mining_scene_path = "res://scenes/Stages/MineRegion.tscn"
		custom_level.level_description = "45-degree rotated subterranean strata and inverted angled seams.\nCarve through diagonal geological faultlines and tilted mineral layers."
		custom_level.level_difficulty = GameLevel.Difficulty.REGULAR
		custom_level.unlock_description = ""
		custom_level.level_image = _get_or_create_preview()

		lvl_mgr.all_levels[DIAGONAL_LEVEL_ID] = {
			"level": custom_level,
			"is_unlocked": true
		}

	if "level_info" in Gvars and Gvars.level_info is Dictionary:
		if not Gvars.level_info.has(DIAGONAL_LEVEL_ID):
			Gvars.level_info[DIAGONAL_LEVEL_ID] = {
				"name": "Diagonal Seams",
				"description": "45-degree rotated strata and angled mineral veins.",
				"depth": 1200,
				"cost": 0,
				"unlocked": true
			}

static func _get_or_create_preview() -> ImageTexture:
	if FileAccess.file_exists(PREVIEW_PATH):
		var bytes = FileAccess.get_file_as_bytes(PREVIEW_PATH)
		if bytes.size() > 0:
			var img = Image.new()
			if img.load_png_from_buffer(bytes) == OK:
				return ImageTexture.create_from_image(img)

	# Generate procedural diagonal preview card
	var img = Image.create(96, 64, false, Image.FORMAT_RGBA8)
	var col1 = Color(0.18, 0.22, 0.30, 1.0)
	var col2 = Color(0.85, 0.55, 0.20, 1.0)
	var col3 = Color(0.30, 0.65, 0.85, 1.0)
	for x in range(96):
		for y in range(64):
			var diag = (x + y) % 24
			if diag < 10:
				img.set_pixel(x, y, col1)
			elif diag < 16:
				img.set_pixel(x, y, col2)
			else:
				img.set_pixel(x, y, col3)
	return ImageTexture.create_from_image(img)
