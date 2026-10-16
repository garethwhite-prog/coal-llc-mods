extends Node

const MOD_DIR := "gareth-lost_expedition_mod"

func _init() -> void:
	ModLoaderLog.info("Lost Expedition Mod initializing...", MOD_DIR)
	var mod_dir_path: String = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/Menus/level_select.gd",
		mod_dir_path.path_join("extensions/scenes/Interfaces/Menus/level_select.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/tilemaps/tile_map_chunk.gd",
		mod_dir_path.path_join("extensions/scenes/tilemaps/tile_map_chunk.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/Game.gd",
		mod_dir_path.path_join("extensions/scripts/Game.hooks.gd")
	)

func _ready() -> void:
	ModLoaderLog.info("Lost Expedition Custom Map Mod (ID 101) online!", MOD_DIR)
