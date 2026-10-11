extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var settings = chain.reference_object
	if not settings or not ("tab_container" in settings) or not settings.tab_container:
		return

	var tc: TabContainer = settings.tab_container

	# 1. Add Mod Manager Tab
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

	# 2. Add Leaderboard Tab
	var lb_tab = tc.get_node_or_null("LeaderboardTab")
	if not lb_tab:
		var tab_script = load("res://mods-unpacked/gareth-leaderboard_mod/scenes/leaderboard_tab.gd")
		if tab_script:
			var tab := PanelContainer.new()
			tab.set_script(tab_script)
			tab.name = "LeaderboardTab"
			tab.set_name("Leaderboard")
			tc.add_child(tab)
			lb_tab = tab

	# 3. Force exact child positions: Mod Manager = Index 6, Leaderboard = Index 7
	if mm_tab:
		tc.move_child(mm_tab, 6)
	if lb_tab:
		tc.move_child(lb_tab, 7)