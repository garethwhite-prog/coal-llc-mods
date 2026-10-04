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

	var wrapper := Control.new()
	wrapper.name = "TreeWrapper"
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chart.add_child(wrapper)
	chart.remove_child(vbox)
	wrapper.add_child(vbox)

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

	vbox.add_theme_constant_override("separation", 4)
	vbox.scale = Vector2(0.53, 0.53)
	vbox.position = Vector2(350, 80)

	chart.register_all_employee_icons()
	_cascade_and_update_visibility(chart)
	chart.refresh_all_icons()
	ModLoaderLog.info("Workforce chart initialized cleanly.", "gareth-more_employees_mod")

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

func refresh_all_icons(chain: ModLoaderHookChain) -> void:
	var chart := chain.reference_object as OrganisationChart2
	if not chart:
		chain.execute_next([])
		return
	_cascade_and_update_visibility(chart)
	chain.execute_next([])
	_cascade_and_update_visibility(chart)
	chart.queue_redraw()

func _cascade_and_update_visibility(chart: OrganisationChart2) -> void:
	var mgr = Gvars.employee_manager
	if not mgr:
		return

	var changed := true
	while changed:
		changed = false
		for icon in chart.all_employee_icons:
			if not icon or not is_instance_valid(icon) or not icon.employee_level:
				continue
			var lvl = icon.employee_level
			if lvl.upgrades_from != EmployeeLevel.EmployeeLevelNames.NOTHING:
				if lvl.upgrades_from in mgr.locked_employees:
					if not (lvl.level_name in mgr.locked_employees):
						mgr.locked_employees.append(lvl.level_name)
						changed = true

	for icon in chart.all_employee_icons:
		if not icon or not is_instance_valid(icon) or not icon.employee_level:
			continue
		var is_locked = (icon.employee_level.level_name in mgr.locked_employees)
		if is_locked:
			icon.visible = false
			icon.purchaseable = false

func _draw(chain: ModLoaderHookChain) -> void:
	var chart := chain.reference_object as OrganisationChart2
	if not chart:
		chain.execute_next([])
		return

	if chart.all_employee_icons.is_empty():
		chart.register_all_employee_icons()

	var mgr = Gvars.employee_manager
	var points_lock: Array[Vector2] = []
	var points_unlock: Array[Vector2] = []

	for icon in chart.all_employee_icons:
		if not icon or not is_instance_valid(icon) or not icon.visible or not icon.employee_level:
			continue
		if mgr and (icon.employee_level.level_name in mgr.locked_employees):
			continue

		var upgrades_from = icon.employee_level.upgrades_from
		if upgrades_from == EmployeeLevel.EmployeeLevelNames.NOTHING:
			continue

		for icon_2 in chart.all_employee_icons:
			if not icon_2 or not is_instance_valid(icon_2) or not icon_2.visible or not icon_2.employee_level:
				continue
			if mgr and (icon_2.employee_level.level_name in mgr.locked_employees):
				continue

			if icon_2.employee_level.level_name == upgrades_from:
				var p1: Vector2
				if icon_2.employee_node:
					p1 = icon_2.employee_node.global_position - chart.global_position
				else:
					p1 = icon_2.global_position - chart.global_position

				var p2: Vector2
				if icon.employee_node:
					p2 = icon.employee_node.global_position - chart.global_position
				else:
					p2 = icon.global_position - chart.global_position

				if p1.length_squared() < 100.0 or p2.length_squared() < 100.0:
					continue

				var mid_y: float = (p1.y + p2.y) / 2.0
				var pts: Array[Vector2] = points_unlock if icon.purchaseable else points_lock

				pts.append(p1)
				pts.append(Vector2(p1.x, mid_y))

				pts.append(Vector2(p1.x, mid_y))
				pts.append(Vector2(p2.x, mid_y))

				pts.append(Vector2(p2.x, mid_y))
				pts.append(p2)

	if not points_lock.is_empty():
		chart.draw_multiline(PackedVector2Array(points_lock), Color(0.6, 0.0, 0.0), 3.5, false)

	if not points_unlock.is_empty():
		chart.draw_multiline(PackedVector2Array(points_unlock), Color(0.0, 0.6, 0.0), 5.5, false)