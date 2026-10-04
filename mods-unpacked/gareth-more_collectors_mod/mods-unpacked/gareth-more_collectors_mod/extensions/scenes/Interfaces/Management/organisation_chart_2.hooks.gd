extends Object

const ICON2_SCENE = preload("res://scenes/Interfaces/Management/employee_level_icon_2.tscn")
const SPACER_SCENE = preload("res://scenes/Interfaces/Management/employee_level_icon_spacer.tscn")

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var chart := chain.reference_object as OrganisationChart2
	if not chart:
		return

	var levels := [
		"res://mods-unpacked/gareth-more_collectors_mod/levels/vortex_collector.tres",
		"res://mods-unpacked/gareth-more_collectors_mod/levels/quantum_collector.tres",
		"res://mods-unpacked/gareth-more_collectors_mod/levels/abyssal_collector.tres",
		"res://mods-unpacked/gareth-more_collectors_mod/levels/singularity_collector.tres"
	]

	var vbox = chart.get_node_or_null("VBoxContainer")
	if not vbox:
		return

	var new_row := HBoxContainer.new()
	new_row.name = "HBoxContainer_CosmicCollectors"
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
	ModLoaderLog.info("Cosmic Collector tier icons injected into Organisation Chart.", "gareth-more_collectors_mod")