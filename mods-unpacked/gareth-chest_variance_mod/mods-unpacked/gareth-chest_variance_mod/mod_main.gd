extends Node

const MOD_DIR := "gareth-chest_variance_mod"

func _init() -> void:
	ModLoaderMod.install_script_hooks(
		"res://scripts/Chest.gd",
		"res://mods-unpacked/gareth-chest_variance_mod/extensions/scripts/Chest.hooks.gd"
	)

func _ready() -> void:
	ModLoaderLog.info("Chest Variance, Class Seeding & Trap Mod active!", MOD_DIR)
