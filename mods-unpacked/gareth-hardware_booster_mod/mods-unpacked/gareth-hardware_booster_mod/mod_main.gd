extends Node

const MOD_ID := "gareth-hardware_booster_mod"
const LOG_NAME := "gareth-hardware_booster_mod"

func _init() -> void:
	ModLoaderLog.info("Hardware Multi-Thread Booster initializing...", LOG_NAME)
	install_hooks()

func _ready() -> void:
	var cpu_count = OS.get_processor_count()
	ModLoaderLog.info("Hardware Multi-Thread Booster active! Detected " + str(cpu_count) + " logical CPU threads.", LOG_NAME)

func install_hooks() -> void:
	var unpacked_dir = ModLoaderMod.get_unpacked_dir().path_join(MOD_ID)
	var ext_dir = unpacked_dir.path_join("extensions")

	ModLoaderMod.install_script_hooks(
		"res://scenes/tilemaps/tile_map_chunk.gd",
		ext_dir.path_join("scenes/tilemaps/tile_map_chunk.hooks.gd")
	)
