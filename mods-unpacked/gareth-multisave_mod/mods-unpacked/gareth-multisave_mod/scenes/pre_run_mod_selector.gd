class_name PreRunModSelector
extends Control

signal run_confirmed()
signal back_requested()

var toggles: Dictionary = {}

const DEFAULT_MODS: Array[Dictionary] = [
	{"key": "dual_multipliers", "label": "Dual-Multiplier Scaling", "category": "Weapons & Scaling", "desc": "Compounding secondary stats for Drills, Axes & Firearms.", "default": true},
	{"key": "tank_arsenal", "label": "Tank Arsenal", "category": "Weapons & Scaling", "desc": "45 custom tank levels with scaling explosive shells.", "default": true},
	{"key": "weapon_stacker", "label": "Weapon Stacker", "category": "Weapons & Scaling", "desc": "Duplicate weapon purchases stack damage and projectile counts.", "default": true},
	{"key": "bouncing_grenades", "label": "Bouncing Grenades", "category": "Weapons & Scaling", "desc": "15-tier parabolic bouncing cluster explosives.", "default": true},
	{"key": "martial_legends", "label": "Martial Legends", "category": "Weapons & Scaling", "desc": "High-velocity boxing gloves and roundhouse kick weapons.", "default": true},
	{"key": "plasma_raygun", "label": "Plasma Raygun", "category": "Weapons & Scaling", "desc": "360-degree piercing energy beam weapon.", "default": true},
	{"key": "hydrogen_bomb", "label": "Hydrogen Bombs", "category": "Weapons & Scaling", "desc": "15 tiers of massive subterranean thermonuclear explosives.", "default": true},
	{"key": "neutron_bomb", "label": "Neutron Bombs", "category": "Weapons & Scaling", "desc": "Clean-yield radiation blasts that preserve raw minerals.", "default": true},
	{"key": "water_spirit", "label": "Water Spirit Companion", "category": "Weapons & Scaling", "desc": "Orbital cyan spirit that saturates rock within an expanding orbit.", "default": true},
	{"key": "buyable_vacuums", "label": "Vacuum Cleaners", "category": "Progression & Upgrades", "desc": "Purchasable tethered vacuum collectors in the shop.", "default": true},
	{"key": "more_inventory_slots", "label": "Expanded Inventory Slots", "category": "Progression & Upgrades", "desc": "Increases hotbar inventory from 4 up to 10 slots.", "default": true},
	{"key": "more_inventory_stacks", "label": "Larger Stack Sizes", "category": "Progression & Upgrades", "desc": "Expands carried material stack limits from 7 up to 16.", "default": true},
	{"key": "more_layer_shifts", "label": "Deeper Layer Shifts", "category": "Progression & Upgrades", "desc": "Expands cavern depth from 6 up to 12 distinct strata.", "default": true},
	{"key": "infini_platform", "label": "Infini-Platform Bridging", "category": "Progression & Upgrades", "desc": "Places walkable scaffolding across deep mine pits.", "default": true},
	{"key": "prospectors_beacon", "label": "Prospector's Beacon", "category": "Progression & Upgrades", "desc": "Emits periodic radar pulses that highlight nearby rare gems.", "default": true},
	{"key": "more_employees", "label": "Executive Miners", "category": "Workforce & Automation", "desc": "Expanded workforce hierarchy with automated miners.", "default": true},
	{"key": "more_collectors", "label": "Cosmic Collectors", "category": "Workforce & Automation", "desc": "High-speed automated cargo recovery drones.", "default": true},
	{"key": "more_drills", "label": "High-Yield Drills", "category": "Workforce & Automation", "desc": "Adds automated mining drill machinery to the shop.", "default": true},
	{"key": "more_mortars", "label": "Mortar Gun Expansion", "category": "Workforce & Automation", "desc": "Automated mortar emplacements with parabolic targeting.", "default": true},
	{"key": "vacuum_depot", "label": "Vacuum Collector Depot", "category": "Workforce & Automation", "desc": "Collector UFOs offload directly into subterranean nozzles.", "default": true},
	{"key": "seismic_hazards", "label": "Seismic Hazards", "category": "Hardcore Mutators", "desc": "Mining deep strata triggers ceiling collapses and rockfalls.", "default": false},
	{"key": "uranium_gas", "label": "Pressurized Uranium Gas", "category": "Hardcore Mutators", "desc": "Exposed uranium leaks volatile explosive gas clouds.", "default": false},
	{"key": "liquefaction", "label": "Liquefaction Fluid Strata", "category": "Hardcore Mutators", "desc": "Explosions cause rock to temporarily flow like liquid sand.", "default": false},
	{"key": "debt_executioner", "label": "Corporate Debt Executioner", "category": "Hardcore Mutators", "desc": "Start at -$50M debt; Repo Drones hunt you if quotas fail.", "default": false}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var vp_rect := get_viewport_rect()
	position = Vector2.ZERO
	size = vp_rect.size
	custom_minimum_size = vp_rect.size
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 80

	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = vp_rect.size
	bg.color = Color(0.06, 0.07, 0.09, 0.98)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var margin := MarginContainer.new()
	margin.position = Vector2.ZERO
	margin.size = vp_rect.size
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var top_bar := HBoxContainer.new()
	top_bar.custom_minimum_size = Vector2(0, 48)
	top_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(top_bar)

	var back_btn := Button.new()
	back_btn.text = " < Back to Class Select "
	back_btn.custom_minimum_size = Vector2(200, 40)
	back_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back_btn.pressed.connect(func():
		back_requested.emit()
		queue_free()
	)
	top_bar.add_child(back_btn)

	var title := Label.new()
	title.text = "ACTIVE MOD EXPANSIONS & MUTATORS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title.add_theme_font_size_override("font_size", 20)
	top_bar.add_child(title)

	var confirm_btn := Button.new()
	confirm_btn.text = " Continue to Map Select > "
	confirm_btn.custom_minimum_size = Vector2(220, 40)
	confirm_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	confirm_btn.modulate = Color(0.4, 1.0, 0.5)
	confirm_btn.pressed.connect(_on_confirm)
	top_bar.add_child(confirm_btn)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 20)
	scroll.add_child(content)

	var saved_config := _load_existing_mod_config()
	var categories := ["Weapons & Scaling", "Progression & Upgrades", "Workforce & Automation", "Hardcore Mutators"]

	for cat in categories:
		var cat_lbl := Label.new()
		cat_lbl.text = cat.to_upper()
		cat_lbl.modulate = Color(1.0, 0.85, 0.3)
		cat_lbl.add_theme_font_size_override("font_size", 16)
		content.add_child(cat_lbl)

		var grid := GridContainer.new()
		grid.columns = 2
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 20)
		grid.add_theme_constant_override("v_separation", 12)
		content.add_child(grid)

		for m in DEFAULT_MODS:
			if m["category"] != cat:
				continue
			var k: String = m["key"]
			var default_val: bool = bool(saved_config.get(k, m["default"]))
			toggles[k] = default_val

			var card := PanelContainer.new()
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var c_margin := MarginContainer.new()
			c_margin.add_theme_constant_override("margin_left", 14)
			c_margin.add_theme_constant_override("margin_right", 14)
			c_margin.add_theme_constant_override("margin_top", 10)
			c_margin.add_theme_constant_override("margin_bottom", 10)
			card.add_child(c_margin)

			var hbox := HBoxContainer.new()
			hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_theme_constant_override("separation", 12)
			c_margin.add_child(hbox)

			var cb := CheckBox.new()
			cb.button_pressed = default_val
			cb.toggled.connect(func(v: bool): toggles[k] = v)
			hbox.add_child(cb)

			var info_vbox := VBoxContainer.new()
			info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var name_lbl := Label.new()
			name_lbl.text = m["label"]
			name_lbl.add_theme_font_size_override("font_size", 14)
			info_vbox.add_child(name_lbl)

			var desc_lbl := Label.new()
			desc_lbl.text = m["desc"]
			desc_lbl.modulate = Color(0.7, 0.7, 0.7)
			desc_lbl.add_theme_font_size_override("font_size", 11)
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			info_vbox.add_child(desc_lbl)

			hbox.add_child(info_vbox)
			grid.add_child(card)

func _load_existing_mod_config() -> Dictionary:
	var path := "user://gareth_mods_config.json"
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary and parsed.has("mods"):
				return parsed["mods"]
	return {}

func _on_confirm() -> void:
	var ssm = get_node_or_null("/root/SaveSlotManager")
	if ssm:
		var cfg := {"mods": toggles}
		var f := FileAccess.open(ssm.get_slot_config_path(ssm.current_slot), FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(cfg, "\t"))
			f.close()
	run_confirmed.emit()
	queue_free()