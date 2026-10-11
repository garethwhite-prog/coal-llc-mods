extends Node

const MOD_DIR := "gareth-mod_manager_mod"

func _init() -> void:
	var mod_dir_path: String = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	ModLoaderMod.install_script_hooks(
		"res://scripts/MainMenu.gd",
		mod_dir_path.path_join("extensions/scripts/MainMenu.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/Menus/settings_2.gd",
		mod_dir_path.path_join("extensions/scenes/Interfaces/Menus/settings_2.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/PauseMenu.gd",
		mod_dir_path.path_join("extensions/scripts/PauseMenu.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/in_game/choose_passive.gd",
		mod_dir_path.path_join("extensions/scenes/Interfaces/in_game/choose_passive.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Stages/management_screen.gd",
		mod_dir_path.path_join("extensions/scenes/Stages/management_screen.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/Menus/profession_select.gd",
		mod_dir_path.path_join("extensions/scenes/Interfaces/Menus/profession_select.hooks.gd")
	)

func _ready() -> void:
	ModLoaderLog.info("Universal Mod Manager online with Class & Shop gating.", MOD_DIR)