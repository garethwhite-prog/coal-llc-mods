extends Node

const MOD_ID := "gareth-mod_manager_mod"
const LOG_NAME := "gareth-mod_manager_mod"

func _init() -> void:
	ModLoaderLog.info("Universal Mod Manager initializing...", LOG_NAME)
	install_hooks()

func _ready() -> void:
	ModLoaderLog.info("Universal Mod Manager active with full Class, Shop & Input gating.", LOG_NAME)

func install_hooks() -> void:
	var unpacked_dir = ModLoaderMod.get_unpacked_dir().path_join(MOD_ID)
	var ext_dir = unpacked_dir.path_join("extensions")

	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/in_game/choose_passive.gd",
		ext_dir.path_join("scenes/Interfaces/in_game/choose_passive.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/MainMenu.gd",
		ext_dir.path_join("scripts/MainMenu.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/Gvars.gd",
		ext_dir.path_join("scripts/Gvars.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Stages/management_screen.gd",
		ext_dir.path_join("scenes/Stages/management_screen.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/Camera.gd",
		ext_dir.path_join("scripts/Camera.hooks.gd")
	)
