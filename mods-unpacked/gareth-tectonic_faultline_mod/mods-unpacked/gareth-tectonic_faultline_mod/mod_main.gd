extends Node

const MOD_DIR := "gareth-tectonic_faultline_mod"

func _init() -> void:
	ModLoaderLog.info("Tectonic Faultline Mod initializing...", MOD_DIR)
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
	ModLoaderMod.install_script_hooks(
		"res://scenes/Stages/management_screen.gd",
		mod_dir_path.path_join("extensions/scenes/Stages/management_screen.hooks.gd")
	)

func _ready() -> void:
	var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
	if helper_script:
		var helper = helper_script.new()
		helper.ensure_level_registered()
	ModLoaderLog.info("Tectonic Faultline Custom Map Mod (ID 102) online!", MOD_DIR)
