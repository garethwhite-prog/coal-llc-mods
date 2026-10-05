extends PanelContainer

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
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

	_add_stat_row(vbox, "Pickaxe Mining Speed", records.get("pickaxe_speed", 0.0), _safe_get(p, "pickaxe_speed"), "%")
	_add_stat_row(vbox, "Pickaxe Mining Damage", records.get("pickaxe_damage", 0.0), _safe_get(p, "pickaxe_damage"), "%")
	_add_stat_row(vbox, "Player Sprint Speed", records.get("player_sprint_speed", 0.0), _safe_get(p, "player_sprint_speed"), "%")
	_add_stat_row(vbox, "Player Jump Velocity", records.get("player_jump_velocity", 0.0), _safe_get(p, "player_jump_velocity"), "%")
	_add_stat_row(vbox, "Vacuum Cleaner Tier", records.get("vacuum_level", 0.0), float(bem.current_vacuum) if (bem and "current_vacuum" in bem) else 0.0, "Tier")
	_add_stat_row(vbox, "Bomb Blast Radius Multiplier", records.get("bomb_radius", 0.0), _safe_get(p, "bomb_radius"), "%")
	_add_stat_row(vbox, "Bomb Damage Multiplier", records.get("bomb_damage", 0.0), _safe_get(p, "bomb_damage"), "%")
	_add_stat_row(vbox, "Punch Speed Multiplier", records.get("punch_speed", 0.0), _safe_get(p, "punch_speed"), "%")
	_add_stat_row(vbox, "Punch Damage Multiplier", records.get("punch_damage", 0.0), _safe_get(p, "punch_damage"), "%")
	_add_stat_row(vbox, "Kick Speed Multiplier", records.get("kick_speed", 0.0), _safe_get(p, "kick_speed"), "%")
	_add_stat_row(vbox, "Kick Damage Multiplier", records.get("kick_damage", 0.0), _safe_get(p, "kick_damage"), "%")
	_add_stat_row(vbox, "Peak Cash Accumulated", records.get("highest_cash", 0.0), float(Gvars.cash) if (Gvars and "cash" in Gvars and Gvars.cash != null) else 0.0, "Cash")

func _safe_get(obj: Object, prop: String) -> float:
	if obj and prop in obj:
		var v = obj.get(prop)
		if v != null:
			return float(v)
	return 0.0

func _add_stat_row(parent: Node, label_name: String, all_time: float, current: float, unit_type: String) -> void:
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_lbl := Label.new()
	name_lbl.text = label_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.custom_minimum_size = Vector2(240, 24)
	hbox.add_child(name_lbl)

	var record_lbl := Label.new()
	record_lbl.text = "Best: " + _format_val(all_time, unit_type)
	record_lbl.custom_minimum_size = Vector2(160, 24)
	record_lbl.modulate = Color.GOLD
	hbox.add_child(record_lbl)

	var curr_lbl := Label.new()
	curr_lbl.text = "Current: " + _format_val(current, unit_type)
	curr_lbl.custom_minimum_size = Vector2(160, 24)
	curr_lbl.modulate = Color.LIGHT_GRAY
	hbox.add_child(curr_lbl)

	parent.add_child(hbox)

func _format_val(val: float, unit_type: String) -> String:
	if unit_type == "%":
		return "+%d%%" % int(val * 100.0)
	elif unit_type == "Tier":
		return "Level %d" % int(val)
	elif unit_type == "Cash":
		if val >= 1e12:
			return "$%.2fe+12" % (val / 1e12)
		elif val >= 1e9:
			return "$%.2fe+9" % (val / 1e9)
		elif val >= 1e6:
			return "$%.2fe+6" % (val / 1e6)
		else:
			return "$%s" % str(int(val))
	return "%.2f" % val