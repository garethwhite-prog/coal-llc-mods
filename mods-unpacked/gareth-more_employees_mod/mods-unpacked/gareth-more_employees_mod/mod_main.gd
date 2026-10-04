extends Node

const MOD_DIR := "gareth-more_employees_mod"

func _init() -> void:
	var mod_dir_path: String = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/Management/organisation_chart_2.gd",
		mod_dir_path.path_join("extensions/scenes/Interfaces/Management/organisation_chart_2.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/Management/employee_shop_tooltip.gd",
		mod_dir_path.path_join("extensions/scenes/Interfaces/Management/employee_shop_tooltip.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/Management/employee_level_icon_2.gd",
		mod_dir_path.path_join("extensions/scenes/Interfaces/Management/employee_level_icon_2.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://resources/Employees/Scripts/employee_manager.gd",
		mod_dir_path.path_join("extensions/resources/Employees/Scripts/employee_manager.hooks.gd")
	)

func _ready() -> void:
	ModLoaderLog.info("Executive Miners initialized safely with click-through tooltips.", MOD_DIR)