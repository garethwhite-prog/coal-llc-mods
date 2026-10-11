class_name SaveSlotModal
extends Control

signal slot_chosen_play(slot_id: int)
signal slot_chosen_new(slot_id: int)
signal modal_closed()

var _grid: GridContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var vp_rect := get_viewport_rect()
	position = Vector2.ZERO
	size = vp_rect.size
	custom_minimum_size = vp_rect.size
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 80

	var backdrop := ColorRect.new()
	backdrop.position = Vector2.ZERO
	backdrop.size = vp_rect.size
	backdrop.color = Color(0.0, 0.0, 0.0, 0.85)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var center := CenterContainer.new()
	center.position = Vector2.ZERO
	center.size = vp_rect.size
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(920, 560)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	var title := RichTextLabel.new()
	title.bbcode_enabled = true
	title.text = "[b][font_size=22]Career Profiles (Multi-Save Slots)[/font_size][/b]"
	title.fit_content = true
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = " Close (Esc) "
	close_btn.pressed.connect(_on_close)
	header.add_child(close_btn)
	vbox.add_child(header)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 16)
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_grid)

	_populate_slots()

func _populate_slots() -> void:
	for child in _grid.get_children():
		child.queue_free()

	var ssm = get_node_or_null("/root/SaveSlotManager")
	for i in range(1, 7):
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(270, 200)

		var c_margin := MarginContainer.new()
		c_margin.add_theme_constant_override("margin_left", 14)
		c_margin.add_theme_constant_override("margin_right", 14)
		c_margin.add_theme_constant_override("margin_top", 12)
		c_margin.add_theme_constant_override("margin_bottom", 12)
		card.add_child(c_margin)

		var c_vbox := VBoxContainer.new()
		c_vbox.add_theme_constant_override("separation", 8)
		c_margin.add_child(c_vbox)

		var slot_lbl := Label.new()
		slot_lbl.text = "PROFILE SLOT %d" % i
		slot_lbl.modulate = Color(1.0, 0.85, 0.25)
		c_vbox.add_child(slot_lbl)

		if ssm and ssm.has_save(i):
			var meta: Dictionary = ssm.get_slot_meta(i)
			var prof: String = meta.get("profession", "Internship")
			var day: int = int(meta.get("day", 1))
			var cash: float = float(meta.get("cash", 0.0))
			var time_str: String = meta.get("timestamp", "")

			var details := Label.new()
			details.text = "Class: %s\nDay: %d | Cash: $%s\nSaved: %s" % [prof, day, Gconsts.add_comma_to_float_no_dp(cash), time_str]
			details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			c_vbox.add_child(details)

			var spacer := Control.new()
			spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
			c_vbox.add_child(spacer)

			var btn_box := HBoxContainer.new()
			btn_box.add_theme_constant_override("separation", 8)
			c_vbox.add_child(btn_box)

			var resume_btn := Button.new()
			resume_btn.text = "Resume"
			resume_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			resume_btn.pressed.connect(func(): slot_chosen_play.emit(i))
			btn_box.add_child(resume_btn)

			var del_btn := Button.new()
			del_btn.text = "Delete"
			del_btn.modulate = Color(1.0, 0.35, 0.35)
			del_btn.pressed.connect(func():
				ssm.delete_slot(i)
				_populate_slots()
			)
			btn_box.add_child(del_btn)
		else:
			var empty_lbl := Label.new()
			empty_lbl.text = "\n[ EMPTY PROFILE ]\n\nReady for new game"
			empty_lbl.modulate = Color(0.6, 0.6, 0.6)
			c_vbox.add_child(empty_lbl)

			var spacer := Control.new()
			spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
			c_vbox.add_child(spacer)

			var new_btn := Button.new()
			new_btn.text = "+ Start New Run"
			new_btn.pressed.connect(func(): slot_chosen_new.emit(i))
			c_vbox.add_child(new_btn)

		_grid.add_child(card)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("menu"):
		_on_close()

func _on_close() -> void:
	modal_closed.emit()
	queue_free()