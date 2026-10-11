extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var pause_menu = chain.reference_object
	if not pause_menu:
		return

	var resume_btn = null
	for child in pause_menu.find_children("*", "Button", true, false):
		if child.text.to_lower().contains("resume"):
			resume_btn = child
			break

	if resume_btn and resume_btn.get_parent():
		var parent_box = resume_btn.get_parent()
		if not parent_box.has_node("PauseModManagerButton"):
			var mod_btn := Button.new()
			mod_btn.name = "PauseModManagerButton"
			mod_btn.text = "Mod Manager"
			mod_btn.custom_minimum_size = resume_btn.custom_minimum_size
			mod_btn.size_flags_horizontal = resume_btn.size_flags_horizontal

			# Copy exact font, font size, and theme styling from resume button
			var btn_font = resume_btn.get_theme_font("font")
			if btn_font:
				mod_btn.add_theme_font_override("font", btn_font)
			var font_sz = resume_btn.get_theme_font_size("font_size")
			if font_sz > 0:
				mod_btn.add_theme_font_size_override("font_size", font_sz)

			mod_btn.pressed.connect(func():
				var view_script = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_manager_view.gd")
				var view = view_script.new()
				view.is_pre_run_mode = false
				pause_menu.add_child(view)
			)
			parent_box.add_child(mod_btn)
			var r_idx = resume_btn.get_index()
			parent_box.move_child(mod_btn, r_idx + 1)