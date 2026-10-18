extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
	if helper_script:
		helper_script.ensure_level_registered()
		var ls = chain.reference_object
		if ls and ("LEVEL_ORDER" in ls):
			if not ls.LEVEL_ORDER.has(helper_script.CANVAS_LEVEL_ID):
				ls.LEVEL_ORDER.append(helper_script.CANVAS_LEVEL_ID)

	chain.execute_next([])

	var ls = chain.reference_object
	if ls and "levels" in ls and ls.levels:
		for card in ls.levels.get_children():
			if "game_level" in card and card.game_level and card.game_level.level == 103:
				_inject_canvas_button(ls, card)

func _inject_canvas_button(ls: Control, card: Control) -> void:
	var btn = Button.new()
	btn.text = "??? Choose Image"
	btn.custom_minimum_size = Vector2(130, 28)
	btn.add_theme_font_size_override("font_size", 10)
	btn.focus_mode = Control.FOCUS_NONE
	card.add_child(btn)
	btn.position = Vector2(12, 175)

	btn.pressed.connect(func():
		var dialog = FileDialog.new()
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.filters = PackedStringArray(["*.jpg, *.jpeg, *.png ; Image Files"])
		dialog.current_dir = "C:/Dev"
		dialog.title = "Select Image for The Living Canvas"
		dialog.use_native_dialog = true

		dialog.file_selected.connect(func(path: String):
			var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
			if helper_script:
				helper_script.set_active_image(path)
				var new_tex = helper_script.get_preview_texture()
				if new_tex and "level_image" in card and card.level_image:
					card.level_image.texture = new_tex
		)

		ls.add_child(dialog)
		dialog.popup_centered(Vector2i(850, 550))
	)
