class_name LivingCanvasHelper
extends RefCounted

const CANVAS_LEVEL_ID: int = 103
const PREVIEW_PATH: String = "res://mods-unpacked/gareth-living_canvas_mod/assets/canvas_preview.png"

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
			custom_level.level_description = "Subterranean strata sculpted directly from a real image or screenshot.\n\nDefault theme: 'Your Mum'. Mine through the beach mosaic or choose any custom image."
			custom_level.level_difficulty = GameLevel.Difficulty.NORMAL
			custom_level.unlock_description = ""

			if FileAccess.file_exists(PREVIEW_PATH):
				var bytes = FileAccess.get_file_as_bytes(PREVIEW_PATH)
				if bytes.size() > 0:
					var img = Image.new()
					if img.load_png_from_buffer(bytes) == OK:
						custom_level.level_image = ImageTexture.create_from_image(img)

			lvl_mgr.all_levels[CANVAS_LEVEL_ID] = {
				"level": custom_level,
				"is_unlocked": true
			}

	if "level_info" in Gvars and Gvars.level_info is Dictionary:
		if not Gvars.level_info.has(CANVAS_LEVEL_ID):
			Gvars.level_info[CANVAS_LEVEL_ID] = {
				"name": "The Living Canvas",
				"description": "Subterranean strata sculpted from real images.",
				"depth": 1000,
				"cost": 0,
				"unlocked": true
			}
