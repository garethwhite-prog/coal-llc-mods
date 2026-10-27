extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var menu = chain.reference_object
	if not menu:
		return

	# 1. Custom "Enhanced by Gareth & Gemini" Subtitle Badge
	if not menu.has_node("EnhancedSubtitle"):
		var subtitle = RichTextLabel.new()
		subtitle.name = "EnhancedSubtitle"
		subtitle.bbcode_enabled = true
		subtitle.text = "[center][b][color=#38bdf8]✦ ENHANCED BY GARETH & GEMINI ✦[/color][/b][/center]"
		subtitle.custom_minimum_size = Vector2(500, 26)
		subtitle.offset_left = -250.0
		subtitle.offset_right = 250.0
		subtitle.anchor_left = 0.5
		subtitle.anchor_right = 0.5
		subtitle.offset_top = 276.0
		subtitle.offset_bottom = 302.0
		menu.add_child(subtitle)

	# 2. Main Menu Buttons Alignment & Store Entry
	var btn_grid = menu.get_node_or_null("%MainMenuButtons")
	if btn_grid:
		# Shift buttons up by 50px and tighten vertical separation so they fit cleanly
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

