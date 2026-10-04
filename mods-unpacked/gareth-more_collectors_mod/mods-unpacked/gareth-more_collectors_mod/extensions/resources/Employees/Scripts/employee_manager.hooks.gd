extends Object

var custom_levels: Dictionary = {}

func _init() -> void:
	var paths := [
		"res://mods-unpacked/gareth-more_collectors_mod/levels/vortex_collector.tres",
		"res://mods-unpacked/gareth-more_collectors_mod/levels/quantum_collector.tres",
		"res://mods-unpacked/gareth-more_collectors_mod/levels/abyssal_collector.tres",
		"res://mods-unpacked/gareth-more_collectors_mod/levels/singularity_collector.tres"
	]
	for p in paths:
		var lvl = load(p)
		if lvl:
			custom_levels[lvl.level_name] = lvl

func get_employee_level_from_enum(chain: ModLoaderHookChain, employee_enum: int) -> EmployeeLevel:
	if custom_levels.has(employee_enum):
		return custom_levels[employee_enum]
	return chain.execute_next([employee_enum])