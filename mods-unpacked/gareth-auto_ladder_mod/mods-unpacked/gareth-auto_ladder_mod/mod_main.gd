extends Node
const MOD_DIR := "gareth-auto_ladder_mod"
func _init() -> void:
	ModLoaderMod.install_script_hooks("res://scripts/tile_map_layer_main.gd", "res://mods-unpacked/gareth-auto_ladder_mod/extensions/scripts/tile_map_layer_main.hooks.gd")
func _ready() -> void:
	ModLoaderLog.info("Auto Ladder Mod active!", MOD_DIR)
