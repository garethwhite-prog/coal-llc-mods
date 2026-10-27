extends Node
const MOD_DIR := "gareth-drone_workforce_mod"
func _init() -> void:
	ModLoaderMod.install_script_hooks(
		"res://scenes/AutoMiners/employee_miner_2.gd",
		"res://mods-unpacked/gareth-drone_workforce_mod/extensions/scenes/AutoMiners/employee_miner_2.hooks.gd"
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/LootCollectorUFO.gd",
		"res://mods-unpacked/gareth-drone_workforce_mod/extensions/scripts/LootCollectorUFO.hooks.gd"
	)
	ModLoaderLog.info("Quadcopter Drone Workforce online!", MOD_DIR)
