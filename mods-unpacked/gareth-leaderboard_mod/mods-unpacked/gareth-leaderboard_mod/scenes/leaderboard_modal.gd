class_name LeaderboardModal
extends Control

signal closed()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var vp_rect := get_viewport_rect()
	position = Vector2.ZERO
	size = vp_rect.size
	custom_minimum_size = vp_rect.size
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 95

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
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	var title := RichTextLabel.new()
	title.bbcode_enabled = true
	title.text = "[b][font_size=22]Career Records & Hall of Fame[/font_size][/b]"
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

	var tab_script = load("res://mods-unpacked/gareth-leaderboard_mod/scenes/leaderboard_tab.gd")
	var tab_content = tab_script.new()
	tab_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(tab_content)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("menu"):
		_on_close()

func _on_close() -> void:
	closed.emit()
	queue_free()