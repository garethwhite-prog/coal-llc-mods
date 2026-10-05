extends PanelContainer

const CATEGORIES: Array[Dictionary] = [
	{
		"title": "Employees & Automation",
		"items": [
			{"key": "employee_collector_speed", "label": "Collector Flight Speed", "unit": "%"},
			{"key": "employee_collector_capacity", "label": "Collector Cargo Capacity", "unit": "%"},
			{"key": "employee_miner_speed", "label": "Miner Walk Speed", "unit": "%"},
			{"key": "employee_miner_damage", "label": "Miner Swing Damage", "unit": "%"}
		]
	},
	{
		"title": "Mortars & Artillery",
		"items": [
			{"key": "mortar_gun_rate", "label": "Mortar Gun Fire Rate", "unit": "%"},
			{"key": "mortar_gun_damage", "label": "Mortar Explosion Damage", "unit": "%"},
			{"key": "gun_rate", "label": "Gun Fire Rate", "unit": "%"},
			{"key": "gun_damage", "label": "Gun Bullet Damage", "unit": "%"},
			{"key": "gun_recoil", "label": "Gun Recoil Force", "unit": "%"}
		]
	},
	{
		"title": "Mining & Player Mobility",
		"items": [
			{"key": "pickaxe_speed", "label": "Pickaxe Mining Speed", "unit": "%"},
			{"key": "pickaxe_damage", "label": "Pickaxe Mining Damage", "unit": "%"},
			{"key": "player_sprint_speed", "label": "Player Sprint Speed", "unit": "%"},
			{"key": "player_climb_speed", "label": "Player Climb Speed", "unit": "%"},
			{"key": "player_jump_velocity", "label": "Player Jump Velocity", "unit": "%"}
		]
	},
	{
		"title": "Explosives & Demolition",
		"items": [
			{"key": "bomb_radius", "label": "Bomb Blast Radius Multiplier", "unit": "%"},
			{"key": "bomb_damage", "label": "Bomb Damage Multiplier", "unit": "%"}
		]
	},
	{
		"title": "Martial Artist Combat",
		"items": [
			{"key": "punch_speed", "label": "Punch Attack Speed", "unit": "%"},
			{"key": "punch_damage", "label": "Punch Kinetic Damage", "unit": "%"},
			{"key": "kick_speed", "label": "Kick Rotation Speed", "unit": "%"},
			{"key": "kick_damage", "label": "Kick Strike Damage", "unit": "%"}
		]
	},
	{
		"title": "Advanced Weapons & Elemental",
		"items": [
			{"key": "drill_speed", "label": "Drill Rotation Speed", "unit": "%"},
			{"key": "drill_damage", "label": "Drill Mining Damage", "unit": "%"},
			{"key": "orb_radius", "label": "Orb Coverage Radius", "unit": "%"},
			{"key": "orb_damage", "label": "Orb Strike Damage", "unit": "%"},
			{"key": "tank_fire_rate", "label": "Tank Fire Rate", "unit": "%"},
			{"key": "tank_damage", "label": "Tank Cannon Damage", "unit": "%"},
			{"key": "wet_damage", "label": "Wet Block Damage", "unit": "%"},
			{"key": "fire_damage", "label": "Fire Burn Damage", "unit": "%"},
			{"key": "poison_damage", "label": "Poison Tick Damage", "unit": "%"},
			{"key": "electric_damage", "label": "Electric Shock Damage", "unit": "%"}
		]
	},
	{
		"title": "Quests & Career Records",
		"items": [
			{"key": "vacuum_level", "label": "Vacuum Cleaner Unlock", "unit": "Tier"},
			{"key": "highest_cash", "label": "Peak Cash Accumulated", "unit": "Cash"},
			{"key": "highest_quota", "label": "Peak Coal Quota Cleared", "unit": "Count"}
		]
	}
]

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)

	var title := RichTextLabel.new()
	title.bbcode_enabled = true
	title.text = "[b][font_size=22]Quest Rewards & All-Time High Scores[/font_size][/b]"
	title.fit_content = true
	title.custom_minimum_size = Vector2(0, 36)
	vbox.add_child(title)

	var tracker = get_node_or_null("/root/LeaderboardTracker")
	if tracker and tracker.has_method("sample_stats"):
		tracker.sample_stats()

	var records: Dictionary = tracker.records if tracker else {}
	var p = Gvars.passives if (Gvars and "passives" in Gvars) else null
	var bem = Gvars.bonus_equipment_manager if (Gvars and "bonus_equipment_manager" in Gvars) else null

	var rendered_keys: Dictionary = {}

	for cat in CATEGORIES:
		_add_section_header(vbox, cat["title"])
		for item in cat["items"]:
			var k: String = item["key"]
			rendered_keys[k] = true
			var all_time: float = records.get(k, 0.0)
			var current: float = _fetch_current(k, p, bem)
			_add_stat_row(vbox, item["label"], all_time, current, item["unit"])

	# Automatically list any extra passives that weren't in the hardcoded list
	var extra_keys: Array[String] = []
	if p:
		for prop in p.get_property_list():
			var pn: String = prop.name
			if not rendered_keys.has(pn) and not pn.begins_with("resource_") and not pn.begins_with("metadata/") and pn != "script":
				if pn in p:
					var val = p.get(pn)
					if val is float or val is int:
						extra_keys.append(pn)

	if extra_keys.size() > 0:
		_add_section_header(vbox, "Additional Active Passives")
		for ek in extra_keys:
			var formatted_name = ek.replace("_", " ").capitalize()
			var all_time: float = records.get(ek, 0.0)
			var current: float = float(p.get(ek))
			_add_stat_row(vbox, formatted_name, all_time, current, "%")

func _fetch_current(key: String, p: Object, bem: Object) -> float:
	if key == "vacuum_level":
		if bem and "current_vacuum" in bem and bem.current_vacuum != null:
			return float(bem.current_vacuum)
	elif key == "highest_cash":
		if Gvars and "cash" in Gvars and Gvars.cash != null:
			return float(Gvars.cash)
	elif key == "highest_quota":
		if Gvars and "quota" in Gvars and Gvars.quota != null:
			return float(Gvars.quota)
	elif p and (key in p):
		var v = p.get(key)
		if v != null:
			return float(v)
	return 0.0

func _add_section_header(parent: Node, title_text: String) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	parent.add_child(spacer)

	var lbl := RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.text = "[color=#f2c94c][b][font_size=16]%s[/font_size][/b][/color]" % title_text
	lbl.fit_content = true
	lbl.custom_minimum_size = Vector2(0, 24)
	parent.add_child(lbl)

	var sep := HSeparator.new()
	parent.add_child(sep)

func _add_stat_row(parent: Node, label_name: String, all_time: float, current: float, unit_type: String) -> void:
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_lbl := Label.new()
	name_lbl.text = label_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.custom_minimum_size = Vector2(260, 22)
	hbox.add_child(name_lbl)

	var record_lbl := Label.new()
	record_lbl.text = "Best: " + _format_val(all_time, unit_type)
	record_lbl.custom_minimum_size = Vector2(170, 22)
	record_lbl.modulate = Color(1.0, 0.85, 0.25)
	hbox.add_child(record_lbl)

	var curr_lbl := Label.new()
	curr_lbl.text = "Current: " + _format_val(current, unit_type)
	curr_lbl.custom_minimum_size = Vector2(170, 22)
	curr_lbl.modulate = Color(0.78, 0.78, 0.78)
	hbox.add_child(curr_lbl)

	parent.add_child(hbox)

func _format_val(val: float, unit_type: String) -> String:
	if unit_type == "%":
		return "+%d%%" % int(val * 100.0)
	elif unit_type == "Tier":
		return "Level %d" % int(val)
	elif unit_type == "Count":
		return Gconsts.add_comma_to_float_no_dp(val)
	elif unit_type == "Cash":
		if val >= 1e12:
			return "$%.2fe+12" % (val / 1e12)
		elif val >= 1e9:
			return "$%.2fe+9" % (val / 1e9)
		elif val >= 1e6:
			return "$%.2fe+6" % (val / 1e6)
		else:
			return "$%s" % Gconsts.add_comma_to_float_no_dp(val)
	return "%.2f" % val