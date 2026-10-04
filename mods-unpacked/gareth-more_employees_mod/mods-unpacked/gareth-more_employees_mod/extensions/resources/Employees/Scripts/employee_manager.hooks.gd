extends Object

var custom_levels: Dictionary = {}

func _init() -> void:
	var paths := [
		"res://mods-unpacked/gareth-more_employees_mod/levels/executive_vp_miner.tres",
		"res://mods-unpacked/gareth-more_employees_mod/levels/chief_mining_officer.tres",
		"res://mods-unpacked/gareth-more_employees_mod/levels/managing_director_miner.tres",
		"res://mods-unpacked/gareth-more_employees_mod/levels/titan_miner.tres"
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