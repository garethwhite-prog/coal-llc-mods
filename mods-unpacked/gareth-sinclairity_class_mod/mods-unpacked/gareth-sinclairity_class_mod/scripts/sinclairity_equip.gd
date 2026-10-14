class_name SinclairityEquipEffect
extends EquipEffect

@export var damage: float = 85.0
@export var beam_width: float = 6.0

var weapon_visual: Sprite2D = null
var beam_line: Line2D = null
var _is_firing: bool = false
var _auto_fire_toggle: bool = false
var audio_player: AudioStreamPlayer2D = null
var _hue: float = 0.0

func start(player, item):
	if "tool" in player and player.tool:
		player.tool.visible = false

	weapon_visual = Sprite2D.new()
	weapon_visual.texture = item.itemTexture
	weapon_visual.offset = Vector2(8, 0)
	weapon_visual.position = Vector2(3, 2)
	weapon_visual.visible = true
	player.add_child(weapon_visual)

	beam_line = Line2D.new()
	beam_line.top_level = true
	beam_line.z_index = 50
	beam_line.width = beam_width
	beam_line.visible = false
	player.get_parent().add_child(beam_line)

	if ResourceLoader.exists("res://assets/sound/sound effects/laser.wav"):
		audio_player = AudioStreamPlayer2D.new()
		audio_player.stream = load("res://assets/sound/sound effects/laser.wav")
		player.add_child(audio_player)

	_is_firing = false
	_auto_fire_toggle = false

func end(player):
	if "tool" in player and player.tool:
		player.tool.visible = true
	if beam_line and is_instance_valid(beam_line):
		beam_line.queue_free()
	if audio_player and is_instance_valid(audio_player):
		audio_player.queue_free()
	if weapon_visual and is_instance_valid(weapon_visual):
		weapon_visual.queue_free()
	_is_firing = false
	_auto_fire_toggle = false

func physics_process(player, delta):
	if weapon_visual and is_instance_valid(weapon_visual):
		var p_pos: Vector2 = player.global_position
		var pointer_pos: Vector2 = player.pointer_global_pos
		var angle: float = (pointer_pos - p_pos).angle()
		weapon_visual.rotation = angle
		weapon_visual.flip_v = (pointer_pos.x < p_pos.x)

	if Input.is_action_pressed("useItem") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_is_firing = true
	elif Input.is_action_just_released("useItem") or (not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not _auto_fire_toggle):
		_is_firing = false

	if Input.is_action_just_pressed("toggle_use_item") or Input.is_action_just_pressed("rightMouseClick"):
		_auto_fire_toggle = not _auto_fire_toggle
		_is_firing = _auto_fire_toggle

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_is_firing = true

	if _is_firing:
		_process_prismatic_beam(player, delta)
	else:
		if beam_line and is_instance_valid(beam_line):
			beam_line.visible = false
		if audio_player and is_instance_valid(audio_player) and audio_player.playing:
			audio_player.stop()

func _get_passive_stat(stat_name: String) -> float:
	if not Gvars or not ("passives" in Gvars) or not Gvars.passives:
		return 0.0
	var p = Gvars.passives
	if p.has_meta(stat_name):
		return float(p.get_meta(stat_name))
	if stat_name in p:
		return float(p.get(stat_name))
	return 0.0

func _process_prismatic_beam(player, delta) -> void:
	if not beam_line or not is_instance_valid(beam_line):
		return

	if audio_player and is_instance_valid(audio_player) and not audio_player.playing:
		audio_player.play()

	_hue = fmod(_hue + delta * 2.5, 1.0)
	var beam_col := Color.from_hsv(_hue, 0.9, 1.0, 0.95)

	var p_pos: Vector2 = player.global_position
	var pointer_pos: Vector2 = player.pointer_global_pos
	var dir: Vector2 = (pointer_pos - p_pos).normalized()
	var muzzle_pos: Vector2 = p_pos + (dir * 20.0)

	var tilemap = player.tilemap
	if not tilemap:
		return

	var max_reach: float = 240.0
	var hit_pos: Vector2 = muzzle_pos + (dir * max_reach)
	var hit_cell = null

	for d in range(8, int(max_reach), 6):
		var check_pos: Vector2 = muzzle_pos + (dir * float(d))
		var cell: Vector2i = tilemap.local_to_map(check_pos)
		if tilemap.is_tile_breakable(cell):
			hit_cell = cell
			hit_pos = check_pos
			break

	beam_line.clear_points()
	beam_line.add_point(muzzle_pos)
	beam_line.add_point(hit_pos)
	beam_line.width = beam_width * (1.0 + _get_passive_stat("sinclair_beam_width"))
	beam_line.default_color = beam_col
	beam_line.visible = true

	if hit_cell != null:
		var eff_dmg: float = damage * (1.0 + _get_passive_stat("sinclair_melt_damage")) * delta * 60.0
		tilemap.damageTileCoords(hit_cell, eff_dmg)
		_spawn_melt_spark(player, hit_pos, beam_col)

func _spawn_melt_spark(player: Node2D, at_pos: Vector2, col: Color) -> void:
	var parent = player.get_parent()
	if not parent:
		parent = player
	var spark := Line2D.new()
	spark.top_level = true
	spark.z_index = 51
	spark.width = 3.0
	spark.default_color = col
	for i in range(7):
		var ang: float = float(i) * TAU / 6.0
		spark.add_point(at_pos + Vector2(cos(ang), sin(ang)) * 4.0)
	parent.add_child(spark)
	var tween = parent.create_tween()
	tween.tween_property(spark, "scale", Vector2(2.0, 2.0), 0.08)
	tween.tween_callback(spark.queue_free)