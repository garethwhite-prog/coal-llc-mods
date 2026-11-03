extends Object

var _zoom_cooldown: float = 0.0

func _process(chain: ModLoaderHookChain, delta: float) -> void:
	chain.execute_next([delta])
	var cam = chain.reference_object
	if not is_instance_valid(cam):
		return

	if _zoom_cooldown > 0.0:
		_zoom_cooldown -= delta

	# Re-acquire player target if detached, without breaking internal position smoothing
	if ("TargetNode" in cam) and not is_instance_valid(cam.TargetNode):
		var tree = cam.get_tree()
		if tree:
			var players = tree.get_nodes_in_group("player")
			if players.size() > 0 and is_instance_valid(players[0]):
				cam.TargetNode = players[0]
			elif is_instance_valid(cam.get_node_or_null("../Player")):
				cam.TargetNode = cam.get_node("../Player")

	# Debounced zoom controls to prevent runaway viewport scaling
	if Gvars and ("settings" in Gvars) and Gvars.settings and _zoom_cooldown <= 0.0:
		var cur_zoom: float = Gvars.settings.zoom_level
		if Input.is_action_just_pressed("zoomOut") or Input.is_key_pressed(KEY_MINUS):
			Gvars.settings.zoom_level = clampf(cur_zoom - 0.2, 0.4, 3.0)
			cam.zoom = Vector2(Gvars.settings.zoom_level, Gvars.settings.zoom_level)
			_zoom_cooldown = 0.18
		elif Input.is_action_just_pressed("zoomIn") or Input.is_key_pressed(KEY_EQUAL):
			Gvars.settings.zoom_level = clampf(cur_zoom + 0.2, 0.4, 3.0)
			cam.zoom = Vector2(Gvars.settings.zoom_level, Gvars.settings.zoom_level)
			_zoom_cooldown = 0.18
		elif Input.is_key_pressed(KEY_0):
			Gvars.settings.zoom_level = 1.0
			cam.zoom = Vector2(1.0, 1.0)
			_zoom_cooldown = 0.18
