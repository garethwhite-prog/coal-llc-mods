extends Node

const SPEEDS := [0.5, 0.75, 1.0, 1.5, 2.0]
var speed_index: int = 2

var canvas: CanvasLayer
var panel: PanelContainer
var lbl_speed: Label
var btn_slower: Button
var btn_faster: Button
var btn_end_day: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()

func _build_hud() -> void:
	canvas = CanvasLayer.new()
	canvas.name = "SpeedControlHUD"
	canvas.layer = 95
	add_child(canvas)

	panel = PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -264.0
	panel.offset_right = -16.0
	panel.offset_top = -48.0
	panel.offset_bottom = -12.0

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)

	btn_slower = Button.new()
	btn_slower.text = "◀"
	btn_slower.custom_minimum_size = Vector2(28, 24)
	btn_slower.tooltip_text = "Slower [ [ ]"
	btn_slower.pressed.connect(func(): _step_speed(-1))
	hbox.add_child(btn_slower)

	lbl_speed = Label.new()
	lbl_speed.text = "1.00x"
	lbl_speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_speed.custom_minimum_size = Vector2(48, 24)
	hbox.add_child(lbl_speed)

	btn_faster = Button.new()
	btn_faster.text = "▶"
	btn_faster.custom_minimum_size = Vector2(28, 24)
	btn_faster.tooltip_text = "Faster [ ] ]"
	btn_faster.pressed.connect(func(): _step_speed(1))
	hbox.add_child(btn_faster)

	var sep = VSeparator.new()
	hbox.add_child(sep)

	btn_end_day = Button.new()
	btn_end_day.text = "End Day"
	btn_end_day.custom_minimum_size = Vector2(70, 24)
	btn_end_day.modulate = Color(1.0, 0.45, 0.45, 1.0)
	btn_end_day.tooltip_text = "Finish Level / Emergency Exit [ F8 ]"
	btn_end_day.pressed.connect(Callable(self, "_finish_level"))
	hbox.add_child(btn_end_day)

	panel.add_child(hbox)
	canvas.add_child(panel)

func _process(_delta: float) -> void:
	var tree = get_tree()
	var in_mining_shift := false
	if tree and tree.root:
		var p = tree.root.find_child("Player", true, false)
		var tm = tree.root.find_child("TileMapManager", true, false)
		var pause = tree.root.find_child("PauseMenu", true, false)
		in_mining_shift = is_instance_valid(p) and is_instance_valid(tm) and (not is_instance_valid(pause) or not pause.visible)

	if panel:
		panel.visible = in_mining_shift

	if not in_mining_shift and Engine.time_scale != 1.0:
		Engine.time_scale = 1.0
		speed_index = 2
		_update_label()

func _unhandled_input(event: InputEvent) -> void:
	if not panel.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_BRACKETLEFT:
			_step_speed(-1)
		elif event.keycode == KEY_BRACKETRIGHT:
			_step_speed(1)
		elif event.keycode == KEY_F8:
			_finish_level()

func _step_speed(dir: int) -> void:
	speed_index = clampi(speed_index + dir, 0, SPEEDS.size() - 1)
	Engine.time_scale = SPEEDS[speed_index]
	_update_label()

func _update_label() -> void:
	if is_instance_valid(lbl_speed):
		lbl_speed.text = "%.2fx" % SPEEDS[speed_index]

func _finish_level() -> void:
	Engine.time_scale = 1.0
	speed_index = 2
	_update_label()

	if Game:
		if Game.has_method("on_EndDay"):
			Game.on_EndDay()
		elif Game.has_method("change_stage") and Gconsts and ("Stages" in Gconsts):
			Game.change_stage(Gconsts.Stages._END_OF_DAY_OVERLAY, Vector2.ZERO)
