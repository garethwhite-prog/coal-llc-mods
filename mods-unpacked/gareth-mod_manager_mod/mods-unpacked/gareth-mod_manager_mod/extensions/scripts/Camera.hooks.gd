extends Object

func _process(chain: ModLoaderHookChain, delta: float) -> void:
	chain.execute_next([delta])
	var cam = chain.reference_object
	if not is_instance_valid(cam):
		return

	# Force camera following and re-acquire player if target was detached
	cam.free_move = false
	var target = null
	if ("TargetNode" in cam) and is_instance_valid(cam.TargetNode):
		target = cam.TargetNode
	else:
		var tree = cam.get_tree()
		if tree:
			var players = tree.get_nodes_in_group("player")
			if players.size() > 0 and is_instance_valid(players[0]):
				target = players[0]
				cam.TargetNode = target
			elif is_instance_valid(cam.get_node_or_null("../Player")):
				target = cam.get_node("../Player")
				cam.TargetNode = target

	if is_instance_valid(target):
		cam.global_position = target.global_position

	# Dedicated zoom controls (freed up [ and ] for game speed)
	if Gvars and ("settings" in Gvars) and Gvars.settings:
		var cur_zoom: float = Gvars.settings.zoom_level
		if Input.is_action_just_pressed("zoomOut") or Input.is_key_pressed(KEY_MINUS):
			Gvars.settings.zoom_level = clamp(cur_zoom - 0.2, 0.2, 4.0)
			cam.zoom = Vector2(Gvars.settings.zoom_level, Gvars.settings.zoom_level)
		elif Input.is_action_just_pressed("zoomIn") or Input.is_key_pressed(KEY_EQUAL):
			Gvars.settings.zoom_level = clamp(cur_zoom + 0.2, 0.2, 4.0)
			cam.zoom = Vector2(Gvars.settings.zoom_level, Gvars.settings.zoom_level)
		elif Input.is_key_pressed(KEY_0):
			Gvars.settings.zoom_level = 1.0
			cam.zoom = Vector2(1.0, 1.0)
