class_name DebtExecutionerEquipEffect
extends EquipEffect

@export var damage: float = 25.0
@export var fire_rate: float = 0.09

var weapon_visual: Sprite2D = null
var fire_cooldown: float = 0.0
var _is_using: bool = false
var _auto_fire_toggle: bool = false
var audio_player: AudioStreamPlayer2D = null

func start(player, item):
	if "tool" in player and player.tool:
		player.tool.visible = false

	if ResourceLoader.exists("res://assets/sound/sound effects/gun.wav"):
		audio_player = AudioStreamPlayer2D.new()
		audio_player.stream = load("res://assets/sound/sound effects/gun.wav")
		player.add_child(audio_player)

	weapon_visual = Sprite2D.new()
	weapon_visual.texture = item.itemTexture
	weapon_visual.offset = Vector2(8, 0)
	weapon_visual.position = Vector2(4, 2)
	weapon_visual.visible = true
	player.add_child(weapon_visual)
	_is_using = false
	_auto_fire_toggle = false

func end(player):
	if "tool" in player and player.tool:
		player.tool.visible = true
	if audio_player and is_instance_valid(audio_player):
		audio_player.queue_free()
	if weapon_visual and is_instance_valid(weapon_visual):
		weapon_visual.queue_free()
	_is_using = false
	_auto_fire_toggle = false

func physics_process(player, delta):
	if fire_cooldown > 0.0:
		fire_cooldown -= delta

	if weapon_visual and is_instance_valid(weapon_visual):
		var p_pos: Vector2 = player.global_position
		var pointer_pos: Vector2 = player.pointer_global_pos
		var angle: float = (pointer_pos - p_pos).angle()
		weapon_visual.rotation = angle
		weapon_visual.flip_v = (pointer_pos.x < p_pos.x)

	if Input.is_action_pressed("useItem") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_is_using = true
	elif Input.is_action_just_released("useItem") or (not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not _auto_fire_toggle):
		_is_using = false

	if Input.is_action_just_pressed("toggle_use_item") or Input.is_action_just_pressed("rightMouseClick"):
		_auto_fire_toggle = not _auto_fire_toggle
		_is_using = _auto_fire_toggle

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_is_using = true

	if _is_using and fire_cooldown <= 0.0:
		_discharge_minigun(player)

func _get_passive_stat(stat_name: String) -> float:
	if not Gvars or not ("passives" in Gvars) or not Gvars.passives:
		return 0.0
	var p = Gvars.passives
	if p.has_meta(stat_name):
		return float(p.get_meta(stat_name))
	if stat_name in p:
		return float(p.get(stat_name))
	return 0.0

func _discharge_minigun(player) -> void:
	var rate_mult: float = 1.0 + _get_passive_stat("exec_fire_rate")
	fire_cooldown = max(0.02, fire_rate / rate_mult)

	if audio_player and is_instance_valid(audio_player):
		audio_player.pitch_scale = randf_range(1.1, 1.4)
		audio_player.play()

	var p_pos: Vector2 = player.global_position
	var pointer_pos: Vector2 = player.pointer_global_pos
	var spread: float = deg_to_rad(randf_range(-4.0, 4.0))
	var dir: Vector2 = (pointer_pos - p_pos).rotated(spread).normalized()
	var muzzle_pos: Vector2 = p_pos + (dir * 22.0)

	if weapon_visual and is_instance_valid(weapon_visual):
		weapon_visual.position -= dir * 2.0
		var tween = player.create_tween()
		tween.tween_property(weapon_visual, "position", Vector2(4, 2), 0.04)

	var tilemap = player.tilemap
	if not tilemap:
		return

	var dmg_mult: float = 1.0 + _get_passive_stat("exec_damage")
	var eff_dmg: float = damage * dmg_mult

	var hit_cell = null
	var hit_pos: Vector2 = muzzle_pos + (dir * 180.0)
	for d in range(8, 180, 8):
		var test_pos: Vector2 = muzzle_pos + (dir * float(d))
		var cell: Vector2i = tilemap.local_to_map(test_pos)
		if tilemap.is_tile_breakable(cell):
			hit_cell = cell
			hit_pos = test_pos
			break

	_spawn_tracer(player, muzzle_pos, hit_pos)

	if hit_cell != null:
		tilemap.damageTileCoords(hit_cell, eff_dmg)

func _spawn_tracer(player: Node2D, from_pos: Vector2, to_pos: Vector2) -> void:
	var parent = player.get_parent()
	if not parent:
		parent = player

	var tracer := Line2D.new()
	tracer.width = 2.0
	tracer.default_color = Color(1.0, 0.85, 0.3, 0.9)
	tracer.add_point(from_pos)
	tracer.add_point(to_pos)
	parent.add_child(tracer)

	var tween = parent.create_tween()
	tween.tween_property(tracer, "modulate:a", 0.0, 0.06)
	tween.tween_callback(tracer.queue_free)