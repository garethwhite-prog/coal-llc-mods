extends Object

const CUSTOM_NAMES := {
	32: "Vortex Collector",
	33: "Quantum Collector",
	34: "Abyssal Collector",
	35: "Singularity Collector"
}

func _ready(chain: ModLoaderHookChain) -> void:
	var tooltip := chain.reference_object as EmployeeShopTooltip
	if not tooltip:
		chain.execute_next([])
		return

	tooltip.scale = Vector2(1.88, 1.88)
	_apply_click_through(tooltip)

	if not tooltip.employee_level:
		chain.execute_next([])
		return

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
	_apply_click_through(tooltip)

func _apply_click_through(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_apply_click_through(child)