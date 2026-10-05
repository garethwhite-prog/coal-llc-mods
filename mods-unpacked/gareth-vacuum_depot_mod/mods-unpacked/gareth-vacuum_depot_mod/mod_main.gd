extends Node

const MOD_DIR := "gareth-vacuum_depot_mod"

func _init() -> void:
	var mod_dir_path: String = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	ModLoaderMod.install_script_hooks(
		"res://scenes/equipment/vacuum_cleaner.gd",
		mod_dir_path.path_join("extensions/scenes/equipment/vacuum_cleaner.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/LootCollectorUFO.gd",
		mod_dir_path.path_join("extensions/scripts/LootCollectorUFO.hooks.gd")
	)

func _ready() -> void:
	ModLoaderLog.info("Vacuum Collector Depot mod initialized successfully.", MOD_DIR)