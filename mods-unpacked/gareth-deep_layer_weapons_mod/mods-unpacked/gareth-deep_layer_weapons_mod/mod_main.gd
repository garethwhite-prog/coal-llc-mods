extends Node
func _init() -> void:
	ModLoaderMod.install_script_hooks("res://scripts/Chest.gd", "res://mods-unpacked/gareth-deep_layer_weapons_mod/extensions/scripts/Chest.hooks.gd")
	ModLoaderLog.info("Deep Layer Weapons Mod active!", "gareth-deep_layer_weapons_mod")
