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

	if is_instance_valid(ls) and not ls.has_node("CanvasImagePickerBtn"):
		var btn_pick = Button.new()
		btn_pick.name = "CanvasImagePickerBtn"
		btn_pick.text = "📁 Browse Custom Image (Map 103)"
		btn_pick.custom_minimum_size = Vector2(250, 34)
		btn_pick.anchor_left = 0.5
		btn_pick.anchor_right = 0.5
		btn_pick.anchor_top = 1.0
		btn_pick.anchor_bottom = 1.0
		btn_pick.offset_left = -125.0
		btn_pick.offset_right = 125.0
		btn_pick.offset_top = -54.0
		btn_pick.offset_bottom = -20.0
		btn_pick.modulate = Color(0.4, 0.9, 1.0)
		btn_pick.pressed.connect(func(): _open_file_dialog(ls))
		ls.add_child(btn_pick)

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
