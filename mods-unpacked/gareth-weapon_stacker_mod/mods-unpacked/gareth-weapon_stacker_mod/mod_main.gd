extends Node

const MOD_DIR := "gareth-weapon_stacker_mod"
const LOG_NAME := "gareth-weapon_stacker_mod:Main"

func _init() -> void:
	var mod_dir_path: String = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	var ext_path: String = mod_dir_path.path_join("extensions/resources/EquipEffects/Scripts")

	ModLoaderMod.install_script_hooks(
		"res://resources/EquipEffects/Scripts/gun.gd",
		ext_path.path_join("gun.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://resources/EquipEffects/Scripts/water_gun.gd",
		ext_path.path_join("water_gun.hooks.gd")
	)
	ModLoaderLog.info("Hooks successfully installed for gun.gd and water_gun.gd", LOG_NAME)

func _ready() -> void:
	ModLoaderLog.info("Weapon Stacker Mod active and ready!", LOG_NAME)