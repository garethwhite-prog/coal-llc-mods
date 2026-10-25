class_name DiagonalMapHelper
extends RefCounted

const DIAGONAL_LEVEL_ID: int = 105

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
