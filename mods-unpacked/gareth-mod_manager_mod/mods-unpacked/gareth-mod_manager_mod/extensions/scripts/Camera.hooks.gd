extends Object

var _zoom_cooldown: float = 0.0

func _process(chain: ModLoaderHookChain, delta: float) -> void:
	var cam = chain.reference_object
	if not is_instance_valid(cam):
		chain.execute_next([delta])
		return

	# 1. Re-acquire player target BEFORE vanilla _process runs to prevent null crash
	var target: Node2D = null
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

	# 2. Enforce active camera state
	cam.free_move = false
	if not cam.is_current():
		cam.make_current()

	# 3. Execute vanilla chain
	chain.execute_next([delta])

	# 4. Synchronize camera position directly to target
	if is_instance_valid(target):
		cam.global_position = target.global_position

	# 5. Clamp zoom_level to protect against mouse-wheel zero-division viewport collapse
	if Gvars and ("settings" in Gvars) and Gvars.settings:
		var cur_zoom: float = float(Gvars.settings.zoom_level)
		if cur_zoom < 0.4 or cur_zoom > 3.0:
			cur_zoom = clampf(cur_zoom, 0.4, 3.0)
			Gvars.settings.zoom_level = cur_zoom
			cam.zoom = Vector2(cur_zoom, cur_zoom)

		if _zoom_cooldown > 0.0:
			_zoom_cooldown -= delta
		else:
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
