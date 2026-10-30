extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
	if helper_script and helper_script.has_method("ensure_level_registered"):
		helper_script.ensure_level_registered()

	var ls = chain.reference_object
	if ls and ("LEVEL_ORDER" in ls):
		if not ls.LEVEL_ORDER.has(103):
			ls.LEVEL_ORDER.append(103)

	chain.execute_next([])

	if not is_instance_valid(ls):
		return

	# Remove any bottom-screen viewport buttons over the grass
	var old_btn = ls.get_node_or_null("CanvasImagePickerBtn")
	if is_instance_valid(old_btn):
		old_btn.queue_free()

	# Attach Browse button inside the Level 103 card container
	var levels_box = ls.get_node_or_null("%Levels")
	if levels_box:
		for card in levels_box.get_children():
			var is_map_103 := false
			if ("game_level" in card) and card.game_level and ("level_id" in card.game_level) and card.game_level.level_id == 103:
				is_map_103 = true
			elif ("level" in card) and card.level and ("level_id" in card.level) and card.level.level_id == 103:
				is_map_103 = true
			else:
				for lbl in card.find_children("*", "Label", true, false):
					if "Living Canvas" in lbl.text:
						is_map_103 = true
						break

			if is_map_103 and not card.has_node("CanvasImagePickerBtn"):
				var btn_pick = Button.new()
				btn_pick.name = "CanvasImagePickerBtn"
				btn_pick.text = "📁 Browse Custom Image"
				btn_pick.custom_minimum_size = Vector2(0, 26)
				btn_pick.modulate = Color(0.4, 0.9, 1.0)
				btn_pick.pressed.connect(func(): _open_file_dialog(ls))
				card.add_child(btn_pick)
				break

func _open_file_dialog(menu: Control) -> void:
	var fd = FileDialog.new()
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.filters = PackedStringArray(["*.png, *.jpg, *.jpeg ; Image Files"])
	fd.title = "Select Image for The Living Canvas Mosaic"
	fd.file_selected.connect(func(path: String):
		var helper = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
		if helper and helper.has_method("set_active_canvas_image"):
			helper.set_active_canvas_image(path)
		fd.queue_free()
	)
	menu.add_child(fd)
	fd.popup_centered(Vector2i(700, 500))
