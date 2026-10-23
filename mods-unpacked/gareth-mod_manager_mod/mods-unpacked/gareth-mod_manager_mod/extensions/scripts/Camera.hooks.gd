extends Object

func _process(chain: ModLoaderHookChain, delta: float) -> void:
	chain.execute_next([delta])
	var cam = chain.reference_object
	if not is_instance_valid(cam) or not Gvars or not ("settings" in Gvars) or not Gvars.settings:
		return

	var cur_zoom: float = Gvars.settings.zoom_level
	if Input.is_action_just_pressed("zoomOut") or Input.is_key_pressed(KEY_BRACKETLEFT) or Input.is_key_pressed(KEY_MINUS):
		Gvars.settings.zoom_level = clamp(cur_zoom - 0.2, 0.2, 4.0)
		cam.zoom = Vector2(Gvars.settings.zoom_level, Gvars.settings.zoom_level)
	elif Input.is_action_just_pressed("zoomIn") or Input.is_key_pressed(KEY_BRACKETRIGHT) or Input.is_key_pressed(KEY_EQUAL):
		Gvars.settings.zoom_level = clamp(cur_zoom + 0.2, 0.2, 4.0)
		cam.zoom = Vector2(Gvars.settings.zoom_level, Gvars.settings.zoom_level)
	elif Input.is_key_pressed(KEY_0):
		Gvars.settings.zoom_level = 1.0
		cam.zoom = Vector2(1.0, 1.0)
