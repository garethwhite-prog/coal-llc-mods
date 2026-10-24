extends Node

const MOD_DIR := "gareth-employee_passives_mod"

func _init() -> void:
	var unpacked_dir = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	var ext_dir = unpacked_dir.path_join("extensions")

	ModLoaderMod.install_script_hooks(
		"res://scenes/AutoMiners/employee_miner_2.gd",
		ext_dir.path_join("scenes/AutoMiners/employee_miner_2.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/LootCollectorUFO.gd",
		ext_dir.path_join("scripts/LootCollectorUFO.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/loot_drops.gd",
		ext_dir.path_join("scripts/loot_drops.hooks.gd")
	)

func _ready() -> void:
	ModLoaderLog.info("Expanded Employee Passives Mod active (Miner Range, Miner Pickup Speed, Collector Range)!", MOD_DIR)
