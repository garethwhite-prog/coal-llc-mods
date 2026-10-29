extends Node

var canvas: CanvasLayer
var panel: PanelContainer
var lbl_speed: Label
var btn_slower: Button
var btn_faster: Button
var btn_end_day: Button

const SPEEDS := [0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0]
var current_idx := 3

func _ready() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 95
	add_child(canvas)

	panel = PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -210.0
	panel.offset_right = -10.0
	panel.offset_top = -42.0
	panel.offset_bottom = -16.0
	panel.visible = false

	var empty_sb = StyleBoxEmpty.new()
	panel.add_theme_stylebox_override("panel", empty_sb)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 4)
	panel.add_child(hbox)

	btn_slower = Button.new()
	btn_slower.text = "◀"
	btn_slower.custom_minimum_size = Vector2(22, 22)
	btn_slower.add_theme_font_size_override("font_size", 10)
	btn_slower.pressed.connect(_decrease_speed)
	hbox.add_child(btn_slower)

	lbl_speed = Label.new()
	lbl_speed.text = "1.00x"
	lbl_speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_speed.custom_minimum_size = Vector2(40, 22)
	lbl_speed.add_theme_font_size_override("font_size", 10)
	hbox.add_child(lbl_speed)

	btn_faster = Button.new()
	btn_faster.text = "▶"
	btn_faster.custom_minimum_size = Vector2(22, 22)
	btn_faster.add_theme_font_size_override("font_size", 10)
	btn_faster.pressed.connect(_increase_speed)
	hbox.add_child(btn_faster)

	btn_end_day = Button.new()
	btn_end_day.text = "⏰ End Day"
	btn_end_day.tooltip_text = "Finish Shift Early / Emergency Exit [Hotkey F8]"
	btn_end_day.custom_minimum_size = Vector2(78, 22)
	btn_end_day.add_theme_font_size_override("font_size", 10)
	btn_end_day.modulate = Color(1.0, 0.5, 0.5)
	btn_end_day.pressed.connect(_finish_shift_early)
	hbox.add_child(btn_end_day)

	canvas.add_child(panel)

func _process(_delta: float) -> void:
	var mining = _is_actively_mining()
	if panel and panel.visible != mining:
		panel.visible = mining

func _unhandled_input(event: InputEvent) -> void:
	if panel and panel.visible and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F8:
			_finish_shift_early()

func _is_actively_mining() -> bool:
	var tree = get_tree()
	if not tree or not tree.root: return false
	var scene = tree.current_scene
	if scene and (scene.name == "MainMenu" or scene.name == "level_select"): return false

	var mgmt = tree.root.find_child("management_screen", true, false)
	if not mgmt: mgmt = tree.root.find_child("ManagementScreen", true, false)
	if mgmt and mgmt.is_visible_in_tree(): return false

	var tm = tree.root.find_child("TileMapManager", true, false)
	var p = tree.root.find_child("Player", true, false)
	return is_instance_valid(tm) and is_instance_valid(p)

func _increase_speed() -> void:
	if current_idx < SPEEDS.size() - 1:
		current_idx += 1
		_apply_speed()

func _decrease_speed() -> void:
	if current_idx > 0:
		current_idx -= 1
		_apply_speed()

func _apply_speed() -> void:
	var sp = SPEEDS[current_idx]
	Engine.time_scale = sp
	lbl_speed.text = "%.2fx" % sp

func _finish_shift_early() -> void:
	Engine.time_scale = 1.0
	current_idx = 3
	_apply_speed()
	var g = Engine.get_main_loop().root.get_node_or_null("/root/Game")
	if g:
		if g.has_method("on_EndDay"):
			g.on_EndDay()
		elif g.has_method("change_stage") and Gconsts and ("Stages" in Gconsts):
			g.change_stage(Gconsts.Stages._END_OF_DAY_OVERLAY, Vector2.ZERO)
