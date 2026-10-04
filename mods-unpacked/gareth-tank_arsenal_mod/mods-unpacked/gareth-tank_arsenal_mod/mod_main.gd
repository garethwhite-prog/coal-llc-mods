extends Node

const MOD_DIR := "gareth-tank_arsenal_mod"
const LOG_NAME := "gareth-tank_arsenal_mod:Main"

func _init() -> void:
	var mod_dir_path: String = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	var ext_path: String = mod_dir_path.path_join("extensions")

	ModLoaderMod.install_script_hooks(
		"res://resources/professions/scripts/tanker.gd",
		ext_path.path_join("resources/professions/scripts/tanker.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Stages/management_screen.gd",
		ext_path.path_join("scenes/Stages/management_screen.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://resources/EquipEffects/Scripts/tank.gd",
		ext_path.path_join("resources/EquipEffects/Scripts/tank.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/equipment/tank_bullet.gd",
		ext_path.path_join("scenes/equipment/tank_bullet.hooks.gd")
	)

func _ready() -> void:
	var state = load("res://mods-unpacked/gareth-tank_arsenal_mod/tank_state.gd")
	state.ensure_catalog_registered()