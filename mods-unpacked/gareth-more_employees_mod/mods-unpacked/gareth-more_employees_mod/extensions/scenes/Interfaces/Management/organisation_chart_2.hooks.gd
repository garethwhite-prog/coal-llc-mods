extends Object

const ICON2_SCENE = preload("res://scenes/Interfaces/Management/employee_level_icon_2.tscn")
const SPACER_SCENE = preload("res://scenes/Interfaces/Management/employee_level_icon_spacer.tscn")

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var chart := chain.reference_object as OrganisationChart2
	if not chart:
		return

	var vbox = chart.get_node_or_null("VBoxContainer")
	if not vbox:
		return

	if chart.has_node("TreeWrapper"):
		return

	# 1. Uncouple VBoxContainer from PanelContainer layout engine by wrapping it in a plain Control
	var wrapper := Control.new()
	wrapper.name = "TreeWrapper"
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chart.add_child(wrapper)
	chart.remove_child(vbox)
	wrapper.add_child(vbox)

	# 2. Remove all empty vanilla spacer rows so they don't consume vertical room
	var to_remove: Array[Node] = []
	for child in vbox.get_children():
		if child is HBoxContainer:
			var has_icon := false
			for sub in child.get_children():
				if sub is EmployeeLevelIcon2:
					has_icon = true
					break
			if not has_icon:
				to_remove.append(child)
			else:
				child.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
				child.custom_minimum_size = Vector2(0, 128)

	for r in to_remove:
		vbox.remove_child(r)
		r.queue_free()

	# 3. Preload all custom employee and collector tier resources
	var titan = load("res://mods-unpacked/gareth-more_employees_mod/levels/titan_miner.tres")
	var md = load("res://mods-unpacked/gareth-more_employees_mod/levels/managing_director_miner.tres")
	var cmo = load("res://mods-unpacked/gareth-more_employees_mod/levels/chief_mining_officer.tres")
	var exec = load("res://mods-unpacked/gareth-more_employees_mod/levels/executive_vp_miner.tres")

	var vortex = null
	var quantum = null
	var abyssal = null
	var singularity = null
	if ResourceLoader.exists("res://mods-unpacked/gareth-more_collectors_mod/levels/vortex_collector.tres"):
		vortex = load("res://mods-unpacked/gareth-more_collectors_mod/levels/vortex_collector.tres")
		quantum = load("res://mods-unpacked/gareth-more_collectors_mod/levels/quantum_collector.tres")
		abyssal = load("res://mods-unpacked/gareth-more_collectors_mod/levels/abyssal_collector.tres")
		singularity = load("res://mods-unpacked/gareth-more_collectors_mod/levels/singularity_collector.tres")

	# 4. Insert custom tiers directly at the top in ascending rank order
	var r9 := _create_grid_row(chart, titan, null, null)
	r9.name = "Tier_9_Titan"
	vbox.add_child(r9)
	vbox.move_child(r9, 0)

	var r8 := _create_grid_row(chart, md, null, null)
	r8.name = "Tier_8_MD"
	vbox.add_child(r8)
	vbox.move_child(r8, 1)

	var r7 := _create_grid_row(chart, cmo, quantum, singularity)
	r7.name = "Tier_7_CMO"
	vbox.add_child(r7)
	vbox.move_child(r7, 2)

	var r6 := _create_grid_row(chart, exec, vortex, abyssal)
	r6.name = "Tier_6_Exec"
	vbox.add_child(r6)
	vbox.move_child(r6, 3)

	# 5. Row separation 4px, 0.52 scale (~67px icons), centered on yellow board
	vbox.add_theme_constant_override("separation", 4)
	vbox.scale = Vector2(0.52, 0.52)
	vbox.position = Vector2(460, 305)

	chart.register_all_employee_icons()
	chart.refresh_all_icons()
	ModLoaderLog.info("Workforce chart scaled to 0.52 (67px icons) and centered at Vector2(460, 305).", "gareth-more_employees_mod")

func _create_grid_row(chart: OrganisationChart2, miner_lvl: EmployeeLevel, speed_col_lvl: EmployeeLevel, cap_col_lvl: EmployeeLevel) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.custom_minimum_size = Vector2(0, 128)
	for i in range(15):
		if i == 9 and miner_lvl:
			var icon: EmployeeLevelIcon2 = ICON2_SCENE.instantiate()
			icon.employee_level = miner_lvl
			icon.add_to_group("employee_icons")
			row.add_child(icon)
			icon.try_to_purchase.connect(chart.on_try_to_purchase)
			icon.try_to_sell.connect(chart.on_try_to_sell)
		elif i == 11 and speed_col_lvl:
			var icon: EmployeeLevelIcon2 = ICON2_SCENE.instantiate()
			icon.employee_level = speed_col_lvl
			icon.add_to_group("employee_icons")
			row.add_child(icon)
			icon.try_to_purchase.connect(chart.on_try_to_purchase)
			icon.try_to_sell.connect(chart.on_try_to_sell)
		elif i == 13 and cap_col_lvl:
			var icon: EmployeeLevelIcon2 = ICON2_SCENE.instantiate()
			icon.employee_level = cap_col_lvl
			icon.add_to_group("employee_icons")
			row.add_child(icon)
			icon.try_to_purchase.connect(chart.on_try_to_purchase)
			icon.try_to_sell.connect(chart.on_try_to_sell)
		else:
			row.add_child(SPACER_SCENE.instantiate())
	return row