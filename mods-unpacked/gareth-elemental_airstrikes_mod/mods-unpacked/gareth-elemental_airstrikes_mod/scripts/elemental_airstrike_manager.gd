extends Node

var canvas: CanvasLayer
var panel: PanelContainer
var btn_dragon: Button
var btn_water: Button
var btn_poison: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()

func _build_hud() -> void:
	canvas = CanvasLayer.new()
	canvas.name = "AirWingsHUDCanvas"
	canvas.layer = 94
	add_child(canvas)

	panel = PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -348.0
	panel.offset_right = -16.0
	panel.offset_top = 58.0
	panel.offset_bottom = 92.0

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)

	btn_dragon = Button.new()
	btn_dragon.text = "🔥 Dragon (7)"
	btn_dragon.modulate = Color(1.0, 0.4, 0.2, 1.0)
	btn_dragon.tooltip_text = "Deploy Fire Dragon Airstrike [ Key 7 ]"
	btn_dragon.pressed.connect(func(): trigger_strike("dragon"))
	hbox.add_child(btn_dragon)

	btn_water = Button.new()
	btn_water.text = "💧 Water (8)"
	btn_water.modulate = Color(0.3, 0.7, 1.0, 1.0)
	btn_water.tooltip_text = "Deploy Water Bomber Airstrike [ Key 8 ]"
	btn_water.pressed.connect(func(): trigger_strike("water"))
	hbox.add_child(btn_water)

	btn_poison = Button.new()
	btn_poison.text = "☣️ Poison (9)"
	btn_poison.modulate = Color(0.4, 1.0, 0.4, 1.0)
	btn_poison.tooltip_text = "Deploy Agent Orange Poison Bomber [ Key 9 ]"
	btn_poison.pressed.connect(func(): trigger_strike("poison"))
	hbox.add_child(btn_poison)

	panel.add_child(hbox)
	canvas.add_child(panel)

func _process(_delta: float) -> void:
	var tree = get_tree()
	var in_game := false
	if tree and tree.root:
		var p = tree.root.find_child("Player", true, false)
		in_game = is_instance_valid(p)

	if panel:
		panel.visible = in_game

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_7:
			trigger_strike("dragon")
		elif event.keycode == KEY_8:
			trigger_strike("water")
		elif event.keycode == KEY_9:
			trigger_strike("poison")

func trigger_strike(strike_type: String) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return

	var p = tree.root.find_child("Player", true, false)
	var target_pos: Vector2 = p.global_position if is_instance_valid(p) else Vector2.ZERO

	var strike_node: Node2D = null
	if strike_type == "dragon":
		var scr = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/dragon_strike.gd")
		strike_node = Node2D.new()
		strike_node.set_script(scr)
	elif strike_type == "water":
		var scr = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/water_bomber_strike.gd")
		strike_node = Node2D.new()
		strike_node.set_script(scr)
	elif strike_type == "poison":
		var scr = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/agent_orange_strike.gd")
		strike_node = Node2D.new()
		strike_node.set_script(scr)

	if strike_node:
		strike_node.global_position = target_pos
		tree.current_scene.add_child(strike_node)

		var boom_audio = AudioStreamPlayer2D.new()
		boom_audio.stream = load("res://assets/sound/sound effects/box_1.wav")
		boom_audio.pitch_scale = 0.8
		boom_audio.global_position = target_pos
		tree.current_scene.add_child(boom_audio)
		boom_audio.play()
		boom_audio.finished.connect(boom_audio.queue_free)
