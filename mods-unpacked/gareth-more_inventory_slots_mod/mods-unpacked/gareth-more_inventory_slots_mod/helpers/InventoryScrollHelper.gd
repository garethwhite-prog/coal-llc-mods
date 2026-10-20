class_name InventoryScrollHelper
extends RefCounted

static func setup_scroll(window: GridContainer) -> void:
	if not window or not is_instance_valid(window):
		return
	_apply_scroll_wrapper.call_deferred(window)

static func update_scroll(window: GridContainer) -> void:
	if not window or not is_instance_valid(window):
		return
	_adjust_scroll_size.call_deferred(window)

static func _apply_scroll_wrapper(window: GridContainer) -> void:
	if not window or not is_instance_valid(window):
		return

	var parent = window.get_parent()
	if not parent or not is_instance_valid(parent):
		return

	if parent is ScrollContainer or parent.name == "InventoryScrollContainer":
		_adjust_scroll_size(window)
		return

	var idx = window.get_index()
	var orig_owner = window.owner

	var scroll = ScrollContainer.new()
	scroll.name = "InventoryScrollContainer"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	scroll.size_flags_horizontal = window.size_flags_horizontal
	scroll.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var dims = _calculate_dimensions(window)
	scroll.custom_minimum_size = dims

	window.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	window.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	parent.remove_child(window)
	parent.add_child(scroll)
	parent.move_child(scroll, idx)
	scroll.add_child(window)

	if orig_owner:
		scroll.owner = orig_owner
		window.owner = orig_owner

	_wire_slot_mouse_scroll(window, scroll)

static func _adjust_scroll_size(window: GridContainer) -> void:
	if not window or not is_instance_valid(window):
		return
	var scroll = window.get_parent() as ScrollContainer
	if not scroll:
		return
	var dims = _calculate_dimensions(window)
	scroll.custom_minimum_size = dims
	_wire_slot_mouse_scroll(window, scroll)

static func _calculate_dimensions(window: GridContainer) -> Vector2:
	var slots = window.get_children()
	var slot_w: float = 64.0
	var slot_h: float = 64.0
	var h_sep: float = window.get_theme_constant("h_separation")
	var v_sep: float = window.get_theme_constant("v_separation")
	if h_sep <= 0.0: h_sep = 6.0
	if v_sep <= 0.0: v_sep = 6.0

	if slots.size() > 0 and slots[0] is Control:
		var s = slots[0] as Control
		if s.size.x > 10.0: slot_w = s.size.x
		elif s.custom_minimum_size.x > 10.0: slot_w = s.custom_minimum_size.x
		if s.size.y > 10.0: slot_h = s.size.y
		elif s.custom_minimum_size.y > 10.0: slot_h = s.custom_minimum_size.y

	var total_w = (slot_w * 10.0) + (h_sep * 9.0) + 26.0
	var max_h   = (slot_h * 4.0) + (v_sep * 3.0) + 4.0
	return Vector2(total_w, max_h)

static func _wire_slot_mouse_scroll(window: GridContainer, scroll: ScrollContainer) -> void:
	for child in window.get_children():
		if child is Control and not child.has_meta("scroll_wired"):
			child.set_meta("scroll_wired", true)
			child.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.is_pressed():
					var v_bar = scroll.get_v_scroll_bar()
					if not v_bar:
						return
					if event.button_index == MOUSE_BUTTON_WHEEL_UP:
						v_bar.value -= v_bar.page * 0.25
					elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
						v_bar.value += v_bar.page * 0.25
			)
