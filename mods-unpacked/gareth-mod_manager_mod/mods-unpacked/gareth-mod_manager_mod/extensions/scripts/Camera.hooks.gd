extends Object

const MIN_ZOOM: float = 0.50
const MAX_ZOOM: float = 2.40
const ZOOM_STEP: float = 0.08

func _unhandled_input(chain: ModLoaderHookChain, event: InputEvent) -> void:
	var cam = chain.reference_object
	if not is_instance_valid(cam):
		chain.execute_next([event])
		return

	# Intercept and clamp mouse wheel and touchpad gestures before vanilla executes
	if event.is_action_pressed("zoomIn") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed):
		_apply_safe_zoom(cam, ZOOM_STEP)
		return
	elif event.is_action_pressed("zoomOut") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed):
		_apply_safe_zoom(cam, -ZOOM_STEP)
		return
	elif event is InputEventPanGesture:
		_apply_safe_zoom(cam, event.delta.y * 0.04)
		return
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_0 or event.keycode == KEY_KP_0:
			_reset_zoom(cam)
			return
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			_apply_safe_zoom(cam, -0.15)
			return
		elif event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			_apply_safe_zoom(cam, 0.15)
			return

	chain.execute_next([event])

func _apply_safe_zoom(cam: Camera2D, amount: float) -> void:
	if not Gvars or not ("settings" in Gvars) or not Gvars.settings:
		return
	var cur: float = float(Gvars.settings.zoom_level)
	var new_zoom: float = clampf(cur + amount, MIN_ZOOM, MAX_ZOOM)
	Gvars.settings.zoom_level = new_zoom
	cam.zoom = Vector2(new_zoom, new_zoom)

func _reset_zoom(cam: Camera2D) -> void:
	if Gvars and ("settings" in Gvars) and Gvars.settings:
		Gvars.settings.zoom_level = 1.0
	cam.zoom = Vector2(1.0, 1.0)

func _process(chain: ModLoaderHookChain, delta: float) -> void:
	var cam = chain.reference_object
	if not is_instance_valid(cam):
		chain.execute_next([delta])
		return

	# 1. Re-acquire player target before vanilla _process executes
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

	# 2. Maintain active camera lock
	cam.free_move = false
	if not cam.is_current():
		cam.make_current()

	# 3. Defensively enforce safe zoom bounds on settings
	if Gvars and ("settings" in Gvars) and Gvars.settings:
		var cur_zoom: float = float(Gvars.settings.zoom_level)
		if cur_zoom < MIN_ZOOM or cur_zoom > MAX_ZOOM:
			var clamped_zoom = clampf(cur_zoom, MIN_ZOOM, MAX_ZOOM)
			Gvars.settings.zoom_level = clamped_zoom
			cam.zoom = Vector2(clamped_zoom, clamped_zoom)

	# 4. Execute vanilla process
	chain.execute_next([delta])

	# 5. Lock position to active target
	if is_instance_valid(target):
		cam.global_position = target.global_position
