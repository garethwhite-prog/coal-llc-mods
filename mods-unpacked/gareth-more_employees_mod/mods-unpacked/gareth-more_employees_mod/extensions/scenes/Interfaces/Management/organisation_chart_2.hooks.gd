extends Object

const ICON2_SCENE = preload("res://scenes/Interfaces/Management/employee_level_icon_2.tscn")
const SPACER_SCENE = preload("res://scenes/Interfaces/Management/employee_level_icon_spacer.tscn")

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var chart := chain.reference_object as OrganisationChart2
	if not chart:
		return

	var levels := [
		"res://mods-unpacked/gareth-more_employees_mod/levels/executive_vp_miner.tres",
		"res://mods-unpacked/gareth-more_employees_mod/levels/chief_mining_officer.tres",
		"res://mods-unpacked/gareth-more_employees_mod/levels/managing_director_miner.tres",
		"res://mods-unpacked/gareth-more_employees_mod/levels/titan_miner.tres"
	]

	var vbox = chart.get_node_or_null("VBoxContainer")
	if not vbox:
		return

	var new_row := HBoxContainer.new()
	new_row.name = "HBoxContainer_ExecutiveMiners"
	vbox.add_child(new_row)

	for lvl_path in levels:
		var lvl = load(lvl_path)
		if lvl:
			var icon: EmployeeLevelIcon2 = ICON2_SCENE.instantiate()
			icon.employee_level = lvl
			icon.add_to_group("employee_icons")
			new_row.add_child(icon)
			icon.try_to_purchase.connect(chart.on_try_to_purchase)
			icon.try_to_sell.connect(chart.on_try_to_sell)
			new_row.add_child(SPACER_SCENE.instantiate())

	chart.register_all_employee_icons()
	chart.refresh_all_icons()
	ModLoaderLog.info("Executive Miner tier icons injected into Organisation Chart.", "gareth-more_employees_mod")