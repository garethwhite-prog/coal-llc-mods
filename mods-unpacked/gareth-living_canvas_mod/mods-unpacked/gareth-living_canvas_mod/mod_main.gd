extends Node

const MOD_ID := "gareth-living_canvas_mod"
const LOG_NAME := "gareth-living_canvas_mod"

func _init() -> void:
	ModLoaderLog.info("The Living Canvas Mod initializing...", LOG_NAME)
	install_hooks()

func _ready() -> void:
	var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
	if helper_script and helper_script.has_method("ensure_level_registered"):
		helper_script.ensure_level_registered()
	ModLoaderLog.info("The Living Canvas Custom Map (ID 103) online!", LOG_NAME)

func install_hooks() -> void:
	var unpacked_dir = ModLoaderMod.get_unpacked_dir().path_join(MOD_ID)
	var ext_dir = unpacked_dir.path_join("extensions")

	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/Menus/level_select.gd",
		ext_dir.path_join("scenes/Interfaces/Menus/level_select.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/tilemaps/tile_map_chunk.gd",
		ext_dir.path_join("scenes/tilemaps/tile_map_chunk.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/Game.gd",
		ext_dir.path_join("scripts/Game.hooks.gd")
	)
