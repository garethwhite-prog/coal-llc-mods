extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var icon := chain.reference_object as EmployeeLevelIcon2
	if not icon:
		return
	if icon.tooltip_instance:
		_set_ignore(icon.tooltip_instance)
	if icon.sell_tooltip_instance:
		_set_ignore(icon.sell_tooltip_instance)

func position_tooltip(chain: ModLoaderHookChain, tooltip_ins: Control) -> void:
	var icon := chain.reference_object as EmployeeLevelIcon2
	if not icon or not tooltip_ins:
		chain.execute_next([tooltip_ins])
		return

	_set_ignore(tooltip_ins)

	var scaled_w: float = tooltip_ins.size.x * tooltip_ins.scale.x
	var scaled_h: float = tooltip_ins.size.y * tooltip_ins.scale.y
	var mouse_pos: Vector2 = icon.get_local_mouse_position()
	var global_mouse: Vector2 = icon.get_global_mouse_position()

	var offset_x: float = 0.0
	var offset_y: float = 0.0

	if global_mouse.x > 960.0:
		offset_x = -45.0 - scaled_w
	else:
		offset_x = 45.0

	if global_mouse.y > 540.0:
		offset_y = -45.0 - scaled_h
	else:
		offset_y = 45.0

	tooltip_ins.position = mouse_pos + Vector2(offset_x, offset_y)

func _set_ignore(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_ignore(child)