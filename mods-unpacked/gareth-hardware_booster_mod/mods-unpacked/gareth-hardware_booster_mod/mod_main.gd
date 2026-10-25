extends Node

const MOD_DIR := "gareth-hardware_booster_mod"

func _init() -> void:
	var unpacked_dir = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	var ext_dir = unpacked_dir.path_join("extensions")

	ModLoaderMod.install_script_hooks(
		"res://scenes/tilemaps/tile_map_chunk.gd",
		ext_dir.path_join("scenes/tilemaps/tile_map_chunk.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/tilemaps/tile_map_manager.gd",
		ext_dir.path_join("scenes/tilemaps/tile_map_manager.hooks.gd")
	)
	ModLoaderLog.info("Hardware Booster Mod initialized with TileMapManager bounds protection.", MOD_DIR)
