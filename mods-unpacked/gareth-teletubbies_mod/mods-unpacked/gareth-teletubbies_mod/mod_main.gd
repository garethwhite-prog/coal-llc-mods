extends Node

const MOD_DIR := "gareth-teletubbies_mod"

func _init() -> void:
	ModLoaderMod.install_script_hooks(
		"res://scenes/equipment/vacuum_cleaner.gd",
		"res://mods-unpacked/gareth-teletubbies_mod/extensions/scenes/equipment/vacuum_cleaner.hooks.gd"
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/tilemaps/tile_map_manager.gd",
		"res://mods-unpacked/gareth-teletubbies_mod/extensions/scenes/tilemaps/tile_map_manager.hooks.gd"
	)
	ModLoaderLog.info("Teletubbyland, Baby Sun & Noo-Noo active!", MOD_DIR)
