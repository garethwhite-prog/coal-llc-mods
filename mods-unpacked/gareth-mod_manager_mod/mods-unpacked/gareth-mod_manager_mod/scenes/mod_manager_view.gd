class_name ModManagerView
extends Control

signal confirmed()
signal back_pressed()

@export var is_pre_run_mode: bool = true

var toggles: Dictionary = {}
const CONFIG_PATH := "user://gareth_mods_config.json"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var vp_rect := get_viewport_rect()
	position = Vector2.ZERO
	size = vp_rect.size
	custom_minimum_size = vp_rect.size
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 85

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
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
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
	back_btn.text = " < Back " if not is_pre_run_mode else " < Back to Class Select "
	back_btn.custom_minimum_size = Vector2(210, 40)
	back_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back_btn.pressed.connect(func():
		back_pressed.emit()
		queue_free()
	)
	top_bar.add_child(back_btn)

	var title := Label.new()
	title.text = "MOD MANAGER — INSTALLED MODS & MUTATORS" if not is_pre_run_mode else "ACTIVE MOD EXPANSIONS & MUTATORS FOR THIS RUN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title.add_theme_font_size_override("font_size", 18)
	top_bar.add_child(title)

	var confirm_btn := Button.new()
	confirm_btn.text = " Save & Close " if not is_pre_run_mode else " Continue to Map Select > "
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
	content.add_theme_constant_override("separation", 22)
	scroll.add_child(content)

	_populate_cards(content)

func _populate_cards(content: VBoxContainer) -> void:
	var registry_script = load("res://mods-unpacked/gareth-mod_manager_mod/scripts/mod_registry.gd")
	var mods: Array = registry_script.get_all_installed_mods()
	var saved_config := _load_existing_config()

	var category_order := [
		"Classes & Professions",
		"Progression & Upgrades",
		"Custom Maps & Strata",
		"Weapons & Arsenal",
		"Employees & Automation",
		"Quality of Life",
		"Performance & System",
		"Community Add-Ons",
		"Other Mods"
	]

	var grouped: Dictionary = {}
	for cat in category_order:
		grouped[cat] = []

	for m in mods:
		var c: String = m["category"]
		if not grouped.has(c):
			grouped[c] = []
		grouped[c].append(m)

	for cat in category_order:
		var list: Array = grouped[cat]
		if list.size() == 0:
			continue

		var cat_lbl := Label.new()
		cat_lbl.text = "%s (%d)" % [cat.to_upper(), list.size()]
		cat_lbl.modulate = Color(1.0, 0.85, 0.3)
		cat_lbl.add_theme_font_size_override("font_size", 16)
		content.add_child(cat_lbl)

		var grid := GridContainer.new()
		grid.columns = 2
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 20)
		grid.add_theme_constant_override("v_separation", 12)
		content.add_child(grid)

		for m in list:
			var k: String = m["key"]
			var default_active: bool = bool(saved_config.get(k, true))
			if cat == "Hardcore Mutators" and not saved_config.has(k):
				default_active = false
			toggles[k] = default_active

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
			cb.button_pressed = default_active
			cb.disabled = bool(m.get("is_core", false))
			cb.toggled.connect(func(val: bool): toggles[k] = val)
			hbox.add_child(cb)

			var info_vbox := VBoxContainer.new()
			info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var title_lbl := Label.new()
			title_lbl.text = "%s  —  by %s [v%s]" % [m["name"], m["author"], m["version"]]
			title_lbl.add_theme_font_size_override("font_size", 13)
			info_vbox.add_child(title_lbl)

			var desc_lbl := Label.new()
			desc_lbl.text = m["description"]
			desc_lbl.modulate = Color(0.7, 0.7, 0.7)
			desc_lbl.add_theme_font_size_override("font_size", 11)
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			info_vbox.add_child(desc_lbl)

			hbox.add_child(info_vbox)
			grid.add_child(card)

func _load_existing_config() -> Dictionary:
	if FileAccess.file_exists(CONFIG_PATH):
		var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary and parsed.has("mods"):
				return parsed["mods"]
	return {}

func _on_confirm() -> void:
	var cfg := {"mods": toggles}
	var f := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(cfg, "\t"))
		f.close()

	var ssm = get_node_or_null("/root/SaveSlotManager")
	if ssm and is_pre_run_mode:
		var slot_cfg := FileAccess.open(ssm.get_slot_config_path(ssm.current_slot), FileAccess.WRITE)
		if slot_cfg:
			slot_cfg.store_string(JSON.stringify(cfg, "\t"))
			slot_cfg.close()

	confirmed.emit()
	queue_free()




