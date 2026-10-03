extends Node

const MOD_DIR := "gareth-elemental_transmutation_mod"
const LOG_NAME := "gareth-elemental_transmutation_mod:Main"


func _init() -> void:
	var mod_dir_path: String = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	var extensions_dir_path: String = mod_dir_path.path_join("extensions")
	ModLoaderMod.install_script_hooks(
		"res://scenes/tilemaps/tile_map_chunk.gd",
		extensions_dir_path.path_join("scenes/tilemaps/tile_map_chunk.hooks.gd")
	)
	ModLoaderLog.info("Hooks successfully installed.", LOG_NAME)


func _ready() -> void:
	ModLoaderLog.info("Ready and active in scene!", LOG_NAME)