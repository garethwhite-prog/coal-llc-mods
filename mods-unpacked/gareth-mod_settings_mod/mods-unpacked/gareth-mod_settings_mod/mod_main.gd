extends Node

const MOD_DIR := "gareth-mod_settings_mod"

func _init() -> void:
	var mod_dir_path: String = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/Menus/settings_2.gd",
		mod_dir_path.path_join("extensions/scenes/Interfaces/Menus/settings_2.hooks.gd")
	)

func _ready() -> void:
	ModLoaderLog.info("Gareth Mod Settings framework initialized.", MOD_DIR)