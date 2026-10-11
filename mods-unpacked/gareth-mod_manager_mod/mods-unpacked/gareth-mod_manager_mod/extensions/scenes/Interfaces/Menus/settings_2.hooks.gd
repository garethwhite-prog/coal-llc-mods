extends Object

const LOG_NAME := "gareth-mod_manager_mod:SettingsHook"

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var settings = chain.reference_object
	if not settings or not ("tab_container" in settings) or not settings.tab_container:
		return

	var existing = settings.tab_container.get_node_or_null("ModManagerTab")
	if existing:
		return

	var tab := PanelContainer.new()
	tab.name = "ModManagerTab"
	tab.set_name("Mod Manager")
	tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	tab.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var header_bar := HBoxContainer.new()
	var h_lbl := RichTextLabel.new()
	h_lbl.bbcode_enabled = true
	h_lbl.text = "[b][font_size=20]Installed Mod Registry & Global Defaults[/font_size][/b]"
	h_lbl.fit_content = true
	h_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_bar.add_child(h_lbl)

	var launch_full_btn := Button.new()
	launch_full_btn.text = " Open Fullscreen Mod Manager "
	launch_full_btn.custom_minimum_size = Vector2(240, 36)
	launch_full_btn.pressed.connect(func():
		var view_script = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_manager_view.gd")
		var view: Control = Control.new()
		view.set_script(view_script)
		view.is_pre_run_mode = false
		settings.add_child(view)
	)
	header_bar.add_child(launch_full_btn)
	vbox.add_child(header_bar)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var desc := Label.new()
	desc.text = "Toggle global active states for installed mods. These settings serve as default presets when starting new career runs."
	desc.modulate = Color(0.75, 0.75, 0.75)
	vbox.add_child(desc)

	settings.tab_container.add_child(tab)
	ModLoaderLog.info("Mod Manager tab added to Settings.", LOG_NAME)