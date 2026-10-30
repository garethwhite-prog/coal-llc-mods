class_name DiagonalMapHelper
extends RefCounted

const DIAGONAL_LEVEL_ID: int = 105

static func ensure_level_registered() -> void:
	var lvl_mgr = Engine.get_main_loop().root.get_node_or_null("/root/LevelManager")
	if not lvl_mgr:
		var scene = Engine.get_main_loop().current_scene
		if scene:
			lvl_mgr = scene.find_child("LevelManager", true, false)

	if lvl_mgr and ("all_levels" in lvl_mgr):
		if not lvl_mgr.all_levels.has(DIAGONAL_LEVEL_ID):
			var base_res = load("res://resources/Levels/level_1.tres")
			var custom_level = base_res.duplicate() if base_res else Resource.new()
			custom_level.set("level_id", DIAGONAL_LEVEL_ID)
			custom_level.set("level_name", "Diagonal Seams")
			custom_level.set("level_description", "Subterranean strata tilted at a 45-degree angle. Specialized diagonal tunneling required.")
			custom_level.set("mining_scene_path", "res://scenes/Stages/MineRegion.tscn")
			lvl_mgr.all_levels[DIAGONAL_LEVEL_ID] = {
				"level": custom_level,
				"is_unlocked": true
			}
