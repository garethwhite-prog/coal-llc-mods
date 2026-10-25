extends Node

var canvas: CanvasLayer
var panel: PanelContainer
var btn_dragon: Button
var btn_water: Button
var btn_poison: Button

func _ready() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 94
	add_child(canvas)

	panel = PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -160.0
	panel.offset_right = -10.0
	panel.offset_top = -104.0
	panel.offset_bottom = -78.0

	var empty_sb = StyleBoxEmpty.new()
	panel.add_theme_stylebox_override("panel", empty_sb)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 4)
	panel.add_child(hbox)

	btn_dragon = Button.new()
	btn_dragon.text = "🔥 7"
	btn_dragon.tooltip_text = "Dragon Firebombing (Press 7)"
	btn_dragon.custom_minimum_size = Vector2(46, 22)
	btn_dragon.add_theme_font_size_override("font_size", 10)
	btn_dragon.pressed.connect(_launch_dragon)
	hbox.add_child(btn_dragon)

	btn_water = Button.new()
	btn_water.text = "💧 8"
	btn_water.tooltip_text = "Water Bomber (Press 8)"
	btn_water.custom_minimum_size = Vector2(46, 22)
	btn_water.add_theme_font_size_override("font_size", 10)
	btn_water.pressed.connect(_launch_water)
	hbox.add_child(btn_water)

	btn_poison = Button.new()
	btn_poison.text = "☣️ 9"
	btn_poison.tooltip_text = "Poison Gas Strike (Press 9)"
	btn_poison.custom_minimum_size = Vector2(46, 22)
	btn_poison.add_theme_font_size_override("font_size", 10)
	btn_poison.pressed.connect(_launch_poison)
	hbox.add_child(btn_poison)

	canvas.add_child(panel)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_7:
			_launch_dragon()
		elif event.keycode == KEY_8:
			_launch_water()
		elif event.keycode == KEY_9:
			_launch_poison()

func _launch_dragon() -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	var script = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/dragon_strike.gd")
	if script:
		var strike = Node2D.new()
		strike.set_script(script)
		tree.current_scene.add_child(strike)

func _launch_water() -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	var script = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/water_bomber_strike.gd")
	if script:
		var strike = Node2D.new()
		strike.set_script(script)
		tree.current_scene.add_child(strike)

func _launch_poison() -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	var script = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/dragon_strike.gd")
	if script:
		var strike = Node2D.new()
		strike.set_script(script)
		strike.modulate = Color(0.2, 1.0, 0.4)
		tree.current_scene.add_child(strike)
