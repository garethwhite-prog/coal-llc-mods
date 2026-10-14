extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var ps = chain.reference_object
	if not ps or not ("professions" in ps) or not ps.professions:
		return

	# Enable horizontal mouse wheel scrolling across all cards
	var parent_scroll = ps.professions.get_parent()
	if parent_scroll and parent_scroll is ScrollContainer:
		parent_scroll.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					parent_scroll.scroll_horizontal += 80
				elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
					parent_scroll.scroll_horizontal -= 80
		)