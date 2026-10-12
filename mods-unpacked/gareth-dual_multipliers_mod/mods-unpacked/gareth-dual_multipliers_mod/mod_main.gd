extends Node

const MOD_DIR := "gareth-dual_multipliers_mod"

func _init() -> void:
	var mod_dir_path := ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	ModLoaderMod.install_script_extension(
		mod_dir_path.path_join("extensions/resources/professions/scripts/profession.hooks.gd")
	)

func _ready() -> void:
	ModLoaderLog.info("Dual-Multiplier Scaling Expansion initialized.", MOD_DIR)