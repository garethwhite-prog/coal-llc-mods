extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	_process_pending_deletions()
	chain.execute_next([])
	var menu = chain.reference_object
	if not is_instance_valid(menu): return

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
			mod_btn.pressed.connect(Callable(self, "_on_mod_manager_pressed").bind(menu))
			btn_grid.add_child(mod_btn)
			btn_grid.move_child(mod_btn, 2)

		if not btn_grid.has_node("ModStoreButton"):
			var store_btn := Button.new()
			store_btn.name = "ModStoreButton"
			store_btn.text = "Mod & Map Store"
			store_btn.custom_minimum_size = Vector2(0, 30)
			store_btn.modulate = Color(1.0, 0.88, 0.35)
			store_btn.pressed.connect(Callable(self, "_on_mod_store_pressed").bind(menu))
			btn_grid.add_child(store_btn)
			btn_grid.move_child(store_btn, 3)

		if not btn_grid.has_node("LeaderboardsButton"):
			var lb_btn := Button.new()
			lb_btn.name = "LeaderboardsButton"
			lb_btn.text = "Leaderboards"
			lb_btn.custom_minimum_size = Vector2(0, 30)
			lb_btn.pressed.connect(Callable(self, "_on_leaderboards_pressed").bind(menu))
			btn_grid.add_child(lb_btn)
			btn_grid.move_child(lb_btn, 4)

func _on_mod_manager_pressed(menu: Node) -> void:
	# FIX: Loading the .tscn scene file instead of the .gd script
	var view_scene = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_manager_view.tscn")
	if view_scene:
		var view = view_scene.instantiate()
		view.set_meta("is_pre_run_mode", false)
		menu.add_child(view)

func _on_mod_store_pressed(menu: Node) -> void:
	var store_scene = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_store_view.tscn")
	if store_scene:
		var store_view = store_scene.instantiate()
		menu.add_child(store_view)

func _on_leaderboards_pressed(menu: Node) -> void:
	var modal_scene = load("res://mods-unpacked/gareth-leaderboard_mod/scenes/leaderboard_modal.tscn")
	if modal_scene:
		var modal = modal_scene.instantiate()
		menu.add_child(modal)

func on_profession_selected(chain: ModLoaderHookChain, mode: int, prof: Object, hard_modifier: Object = null) -> void:
	var menu = chain.reference_object
	if not menu:
		chain.execute_next([mode, prof, hard_modifier])
		return

	var p_select = menu.get_node_or_null("ProfessionSelect")
	if not p_select and "profession_select" in menu:
		p_select = menu.profession_select
	if p_select:
		p_select.visible = false

	var view_scene = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_manager_view.tscn")
	if view_scene:
		var view = view_scene.instantiate()
		view.name = "PreRunModSelector"
		view.set_meta("is_pre_run_mode", true)
		if view.has_signal("confirmed"):
			view.connect("confirmed", Callable(self, "_on_mod_selector_confirmed").bind(chain, mode, prof, hard_modifier))
		if view.has_signal("back_pressed"):
			view.connect("back_pressed", Callable(self, "_on_mod_selector_back").bind(p_select))
		menu.add_child(view)
		return
	chain.execute_next([mode, prof, hard_modifier])

func _on_mod_selector_confirmed(chain: ModLoaderHookChain, mode: int, prof: Object, hard_modifier: Object) -> void:
	chain.execute_next([mode, prof, hard_modifier])

func _on_mod_selector_back(p_select: Node) -> void:
	if p_select:
		p_select.visible = true

func _process_pending_deletions() -> void:
	var base_dir = OS.get_executable_path().get_base_dir()
	var mods_dir = base_dir.path_join("mods")
	var dir = DirAccess.open(mods_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if "pending_delete" in file_name:
				var target_zip = file_name.replace(".pending_delete", ".zip")
				if FileAccess.file_exists(mods_dir.path_join(target_zip)):
					DirAccess.remove_absolute(mods_dir.path_join(target_zip))
				DirAccess.remove_absolute(mods_dir.path_join(file_name))
			file_name = dir.get_next()
