extends Node

var canvas: CanvasLayer
var panel: PanelContainer
var lbl_speed: Label
var btn_slower: Button
var btn_faster: Button

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
	panel.offset_left = -160.0
	panel.offset_right = -10.0
	panel.offset_top = -40.0
	panel.offset_bottom = -14.0

	var empty_sb = StyleBoxEmpty.new()
	panel.add_theme_stylebox_override("panel", empty_sb)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 4)
	panel.add_child(hbox)

	btn_slower = Button.new()
	btn_slower.text = "◀"
	btn_slower.custom_minimum_size = Vector2(24, 22)
	btn_slower.add_theme_font_size_override("font_size", 10)
	btn_slower.pressed.connect(_decrease_speed)
	hbox.add_child(btn_slower)

	lbl_speed = Label.new()
	lbl_speed.text = "1.00x"
	lbl_speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_speed.custom_minimum_size = Vector2(44, 22)
	lbl_speed.add_theme_font_size_override("font_size", 10)
	hbox.add_child(lbl_speed)

	btn_faster = Button.new()
	btn_faster.text = "▶"
	btn_faster.custom_minimum_size = Vector2(24, 22)
	btn_faster.add_theme_font_size_override("font_size", 10)
	btn_faster.pressed.connect(_increase_speed)
	hbox.add_child(btn_faster)

	canvas.add_child(panel)

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
