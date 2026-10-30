extends Node
const MOD_ID := "gareth-reach_expansion_mod"

func _init() -> void:
	var unpacked_dir = ModLoaderMod.get_unpacked_dir().path_join(MOD_ID)
	var ext_dir = unpacked_dir.path_join("extensions")

	ModLoaderMod.install_script_hooks(
		"res://scripts/Stockpile.gd",
		ext_dir.path_join("scripts/Stockpile.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/NPCs/quest_scene_manager.gd",
		ext_dir.path_join("scenes/NPCs/quest_scene_manager.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Stages/management_screen.gd",
		ext_dir.path_join("scenes/Stages/management_screen.hooks.gd")
	)
	ModLoaderLog.info("Expanded Interaction Reach online!", MOD_ID)
