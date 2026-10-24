extends Node
const MOD_DIR := "gareth-diagonal_map_mod"
func _init() -> void:
	ModLoaderMod.install_script_hooks("res://scenes/tilemaps/tile_map_chunk.gd", "res://mods-unpacked/gareth-diagonal_map_mod/extensions/scenes/tilemaps/tile_map_chunk.hooks.gd")
func _ready() -> void:
	ModLoaderLog.info("Diagonal Map Mod active!", MOD_DIR)
