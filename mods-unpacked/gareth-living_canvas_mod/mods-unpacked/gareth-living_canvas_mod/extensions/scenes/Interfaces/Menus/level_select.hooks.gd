extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
	if helper_script and helper_script.has_method("ensure_level_registered"):
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
	var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
	var active_path = helper_script.get_saved_image_path() if helper_script else ""
	var initial_label = "[ Your Mum (Default) ]"
	if active_path != "":
		initial_label = "[ " + active_path.get_file() + " ]"

	var btn = Button.new()
	btn.text = initial_label
	btn.custom_minimum_size = Vector2(150, 26)
	btn.add_theme_font_size_override("font_size", 9)
	btn.focus_mode = Control.FOCUS_NONE
	card.add_child(btn)
	btn.position = Vector2(8, 180)

	btn.pressed.connect(func():
		var dialog = FileDialog.new()
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.filters = PackedStringArray(["*.jpg, *.jpeg, *.png, *.webp ; Image Files"])
		dialog.current_dir = "C:/Dev"
		dialog.title = "Select Image for The Living Canvas"
		if "use_native_dialog" in dialog:
			dialog.set("use_native_dialog", true)

		dialog.file_selected.connect(func(path: String):
			path = path.replace("\\", "/")
			if helper_script and helper_script.has_method("set_active_image"):
				helper_script.set_active_image(path)
				btn.text = "[ " + path.get_file() + " ]"
				
				var new_tex = helper_script.get_preview_texture()
				if new_tex:
					card.game_level.level_image = new_tex
					for child in card.find_children("*", "TextureRect", true, false):
						if child.name != "Lock":
							child.texture = new_tex
		)

		ls.add_child(dialog)
		dialog.popup_centered(Vector2i(800, 500))
	)
