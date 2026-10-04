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

func purchase_employee_level(chain: ModLoaderHookChain, employee_level: EmployeeLevel, count: float) -> float:
	var mgr = chain.reference_object
	if mgr:
		_cascade_locks(mgr)
		if employee_level.level_name in mgr.locked_employees:
			return 0.0
	return chain.execute_next([employee_level, count])

func _cascade_locks(mgr) -> void:
	var changed := true
	while changed:
		changed = false
		for lvl_name in custom_levels.keys():
			var lvl: EmployeeLevel = custom_levels[lvl_name]
			if lvl.upgrades_from in mgr.locked_employees:
				if not (lvl.level_name in mgr.locked_employees):
					mgr.locked_employees.append(lvl.level_name)
					changed = true