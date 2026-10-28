extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var menu = chain.reference_object
	if not is_instance_valid(menu):
		return

	# Check for an optional external branded logo using raw byte buffers
	var logo_loaded := false
	var title_node = menu.find_child("Title", true, false)
	if not title_node:
		title_node = menu.find_child("TextureRect", true, false)

	var logo_path := "res://mods-unpacked/gareth-mod_manager_mod/assets/branded_logo.png"
	if FileAccess.file_exists(logo_path) and is_instance_valid(title_node) and title_node is TextureRect:
		var bytes := FileAccess.get_file_as_bytes(logo_path)
		if bytes.size() > 0:
			var img := Image.new()
			if img.load_png_from_buffer(bytes) == OK:
				var tex := ImageTexture.create_from_image(img)
				title_node.texture = tex
				title_node.custom_minimum_size = Vector2(760, 310)
				title_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				logo_loaded = true

	# Procedural Hanging Plaque with Iron Chains beneath the Title Sign
	if not logo_loaded and not menu.has_node("HangingTitlePlaque"):
		var plaque_container := Control.new()
		plaque_container.name = "HangingTitlePlaque"
		plaque_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
		plaque_container.position = Vector2(0, 0)
		menu.add_child(plaque_container)

		# Left Iron Chain Links
		var chain_l := ColorRect.new()
		chain_l.color = Color(0.28, 0.28, 0.32, 0.95)
		chain_l.position = Vector2(488, 252)
		chain_l.size = Vector2(8, 22)
		plaque_container.add_child(chain_l)

		# Right Iron Chain Links
		var chain_r := ColorRect.new()
		chain_r.color = Color(0.28, 0.28, 0.32, 0.95)
		chain_r.position = Vector2(784, 252)
		chain_r.size = Vector2(8, 22)
		plaque_container.add_child(chain_r)

		# Hanging Wooden Plaque Board
		var wood_panel := PanelContainer.new()
		wood_panel.position = Vector2(440, 274)
		wood_panel.custom_minimum_size = Vector2(400, 36)

		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.55, 0.32, 0.18, 0.98) # Warm timber brown
		sb.border_color = Color(0.22, 0.12, 0.06, 1.0) # Dark wooden bark rim
		sb.set_border_width_all(3)
		sb.corner_radius_top_left = 6
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_left = 6
		sb.corner_radius_bottom_right = 6
		sb.expand_margin_top = 2
		sb.expand_margin_bottom = 2
		wood_panel.add_theme_stylebox_override("panel", sb)

		var plaque_label := RichTextLabel.new()
		plaque_label.bbcode_enabled = true
		plaque_label.text = "[center][b][color=#38bdf8]✦ ENHANCED BY GARETH WHITE & GEMINI ✦[/color][/b][/center]"
		plaque_label.fit_content = true
		plaque_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wood_panel.add_child(plaque_label)

		plaque_container.add_child(wood_panel)

	# Main Menu Buttons Configuration
	var btn_grid = menu.get_node_or_null("%MainMenuButtons")
	if btn_grid:
		btn_grid.offset_top = -68.0
		btn_grid.offset_bottom = 176.0
		btn_grid.add_theme_constant_override("separation", 4)

		if not btn_grid.has_node("ModManagerButton"):
			var mod_btn := Button.new()
			mod_btn.name = "ModManagerButton"
			mod_btn.text = "Mod Manager"
			mod_btn.custom_minimum_size = Vector2(0, 30)
			mod_btn.pressed.connect(func():
				var view_script = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_manager_view.gd")
				if view_script:
					var view: Control = Control.new()
					view.set_script(view_script)
					view.is_pre_run_mode = false
					menu.add_child(view)
			)
			btn_grid.add_child(mod_btn)
			btn_grid.move_child(mod_btn, 2)

		if not btn_grid.has_node("ModStoreButton"):
			var store_btn := Button.new()
			store_btn.name = "ModStoreButton"
			store_btn.text = "Mod & Map Store"
			store_btn.custom_minimum_size = Vector2(0, 30)
			store_btn.modulate = Color(1.0, 0.88, 0.35)
			store_btn.pressed.connect(func():
				var store_script = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_store_view.gd")
				if store_script:
					var store_view = store_script.new()
					menu.add_child(store_view)
			)
			btn_grid.add_child(store_btn)
			btn_grid.move_child(store_btn, 3)

		if not btn_grid.has_node("LeaderboardsButton"):
			var lb_btn := Button.new()
			lb_btn.name = "LeaderboardsButton"
			lb_btn.text = "Leaderboards"
			lb_btn.custom_minimum_size = Vector2(0, 30)
			lb_btn.pressed.connect(func():
				var modal_script = load("res://mods-unpacked/gareth-leaderboard_mod/scenes/leaderboard_modal.gd")
				if modal_script:
					var modal = modal_script.new()
					menu.add_child(modal)
			)
			btn_grid.add_child(lb_btn)
			btn_grid.move_child(lb_btn, 4)

func on_profession_selected(chain: ModLoaderHookChain, mode: int, prof: Object, hard_modifier: Object) -> void:
	var menu = chain.reference_object
	if not menu:
		chain.execute_next([mode, prof, hard_modifier])
		return

	var p_select = menu.get_node_or_null("ProfessionSelect")
	if not p_select and "profession_select" in menu:
		p_select = menu.profession_select
	if p_select:
		p_select.visible = false

	var view_script = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_manager_view.gd")
	if view_script:
		var view: Control = Control.new()
		view.set_script(view_script)
		view.name = "PreRunModSelector"
		view.is_pre_run_mode = true

		view.confirmed.connect(func():
			chain.execute_next([mode, prof, hard_modifier])
		)

		view.back_pressed.connect(func():
			if p_select:
				p_select.visible = true
		)

		menu.add_child(view)
	else:
		chain.execute_next([mode, prof, hard_modifier])
