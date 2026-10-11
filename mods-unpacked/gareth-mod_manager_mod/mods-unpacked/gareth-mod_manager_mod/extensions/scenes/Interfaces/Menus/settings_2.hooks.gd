extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var settings = chain.reference_object
	if not settings or not ("tab_container" in settings) or not settings.tab_container:
		return

	var tc: TabContainer = settings.tab_container

	# 1. Add Mod Manager Tab ONLY if missing
	var mm_tab = tc.get_node_or_null("ModManagerTab")
	if not mm_tab:
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
		h_lbl.text = "[b][font_size=20]Installed Mod Manager & Runtime Toggles[/font_size][/b]"
		h_lbl.fit_content = true
		h_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_bar.add_child(h_lbl)

		var launch_full_btn := Button.new()
		launch_full_btn.text = " Open Fullscreen Mod Manager "
		launch_full_btn.custom_minimum_size = Vector2(240, 36)
		launch_full_btn.pressed.connect(func():
			var view_script = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_manager_view.gd")
			var view = view_script.new()
			view.is_pre_run_mode = false
			settings.add_child(view)
		)
		header_bar.add_child(launch_full_btn)
		vbox.add_child(header_bar)

		var sep := HSeparator.new()
		vbox.add_child(sep)

		var desc := Label.new()
		desc.text = "Configure installed mods and difficulty mutators live during gameplay."
		desc.modulate = Color(0.75, 0.75, 0.75)
		vbox.add_child(desc)

		tc.add_child(tab)
		mm_tab = tab

	# 2. Position Mod Manager at Index 6
	tc.move_child(mm_tab, 6)

	# 3. Align Leaderboard Tab at Index 7 and eliminate duplicate / unnamed tabs
	var found_lb: bool = false
	for child in tc.get_children():
		var c_name := child.name
		if c_name.to_lower().contains("leaderboard"):
			if not found_lb:
				child.name = "Leaderboard"
				child.set_name("Leaderboard")
				tc.move_child(child, 7)
				found_lb = true
			else:
				child.queue_free()
		elif c_name.begins_with("@PanelContainer@"):
			child.queue_free()