extends Node
const MOD_DIR := "gareth-collector_priority_mod"
func _init() -> void:
	ModLoaderMod.install_script_hooks("res://scripts/loot_drops.gd", "res://mods-unpacked/gareth-collector_priority_mod/extensions/scripts/loot_drops.hooks.gd")
func _ready() -> void:
	ModLoaderLog.info("Collector Priority Mod active!", MOD_DIR)
