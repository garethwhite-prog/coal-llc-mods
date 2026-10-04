extends PanelContainer

const GarethSettings = preload("res://mods-unpacked/gareth-mod_settings_mod/scripts/gareth_settings.gd")
const BOOL_SCENE = preload("res://scenes/Interfaces/Menus/setting_bool.tscn")
const SLIDER_SCENE = preload("res://scenes/Interfaces/Menus/setting_slider.tscn")

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
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	var title := RichTextLabel.new()
	title.bbcode_enabled = true
	title.text = "[b][font_size=22]Gareth Mod Suite Configuration[/font_size][/b]"
	title.fit_content = true
	title.custom_minimum_size = Vector2(0, 36)
	vbox.add_child(title)

	_add_header(vbox, "Weapons & Explosives")
	_add_mod_toggle(vbox, "Tank Arsenal Mod", "tank_arsenal")
	_add_mod_toggle(vbox, "Hydrogen Bomb Mod", "hydrogen_bomb")
	_add_mod_toggle(vbox, "Neutron Bomb Mod", "neutron_bomb")
	_add_mod_toggle(vbox, "Mortar Gun Expansion", "more_mortars")
	_add_mod_toggle(vbox, "High-Yield Drills", "more_drills")
	_add_mod_toggle(vbox, "Weapon Stacker Scaling", "weapon_stacker")
	_add_mod_toggle(vbox, "Plasma Raygun", "plasma_raygun")

	_add_header(vbox, "Progression & Shop Upgrades")
	_add_mod_toggle(vbox, "More Rock Layer Shifts (6-12)", "more_layer_shifts")
	_add_mod_toggle(vbox, "More Inventory Slots (4-10)", "more_inventory_slots")
	_add_mod_toggle(vbox, "More Inventory Stacks (7-16)", "more_inventory_stacks")
	_add_mod_toggle(vbox, "Buyable Vacuums & Extensions (1-8)", "buyable_vacuums")
	_add_mod_toggle(vbox, "InfiniPlatform Bridging", "infini_platform")

	_add_header(vbox, "Workforce & Automation")
	_add_mod_toggle(vbox, "Executive Miner Tiers", "more_employees")
	_add_mod_toggle(vbox, "Cosmic Collector Tiers", "more_collectors")

	_add_header(vbox, "World & Mechanics")
	_add_mod_toggle(vbox, "Elemental Transmutation (Bounties)", "elemental_transmutation")
	_add_mod_toggle(vbox, "Excavation Frenzy Multiplier", "excavation_frenzy")
	_add_mod_toggle(vbox, "Prospector's Acoustic Beacon", "prospectors_beacon")
	_add_mod_toggle(vbox, "Seismic Ceiling Hazards", "seismic_hazards")

	_add_header(vbox, "Numerical Tuning Multipliers")
	_add_slider(vbox, "Hydrogen Bomb Blast Radius", "hbomb_radius", 80.0, 20.0, 160.0, 5.0)
	_add_slider(vbox, "InfiniPlatform Max Tile Span", "infini_platform_max", 200.0, 50.0, 500.0, 25.0)

func _add_header(parent: Control, text: String) -> void:
	var h := RichTextLabel.new()
	h.bbcode_enabled = true
	h.text = "\n[b][color=gold]" + text + "[/color][/b]"
	h.fit_content = true
	h.custom_minimum_size = Vector2(0, 32)
	parent.add_child(h)

func _add_mod_toggle(parent: Control, label_text: String, mod_key: String) -> void:
	var b: SettingBool = BOOL_SCENE.instantiate()
	b.default = true
	parent.add_child(b)
	b.setting_label.text = label_text
	b.check_button.button_pressed = GarethSettings.is_mod_enabled(mod_key)
	b.new_value.connect(_on_mod_toggle_changed.bind(mod_key))

func _on_mod_toggle_changed(value: bool, mod_key: String) -> void:
	GarethSettings.set_mod_enabled(mod_key, value)

func _add_slider(parent: Control, label_text: String, slider_key: String, def_val: float, min_val: float, max_val: float, step_val: float) -> void:
	var s: SettingSlider = SLIDER_SCENE.instantiate()
	s.default = def_val
	parent.add_child(s)
	s.setting_label.text = label_text
	s.slider.min_value = min_val
	s.slider.max_value = max_val
	s.slider.step = step_val
	s.slider.value = GarethSettings.get_slider(slider_key, def_val)
	s.value_label.text = Gconsts.two_dp(s.slider.value)
	s.new_value.connect(_on_slider_changed.bind(slider_key))

func _on_slider_changed(value: float, slider_key: String) -> void:
	GarethSettings.set_slider(slider_key, value)