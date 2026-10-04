extends Object

const CUSTOM_NAMES := {
	32: "Vortex Collector",
	33: "Quantum Collector",
	34: "Abyssal Collector",
	35: "Singularity Collector"
}

func _ready(chain: ModLoaderHookChain) -> void:
	var tooltip := chain.reference_object as EmployeeShopTooltip
	if not tooltip or not tooltip.employee_level:
		chain.execute_next([])
		return

	tooltip.scale = Vector2(1.92, 1.92)

	var lvl = tooltip.employee_level
	if CUSTOM_NAMES.has(lvl.level_name):
		var name_str: String = CUSTOM_NAMES[lvl.level_name]
		var info: String = "[b]" + name_str + " - [i]" + Gconsts.add_comma_to_int(int(lvl.upgrade_cost)) + "g[/i][/b]\n"
		info += "Type: Collector\n"
		info += "Flight Speed: " + str(lvl.fly_speed) + "\n"
		info += "Capacity: " + Gconsts.add_comma_to_int(int(lvl.inventory_space)) + " items\n"
		tooltip.text_label.text = info
		return
	chain.execute_next([])