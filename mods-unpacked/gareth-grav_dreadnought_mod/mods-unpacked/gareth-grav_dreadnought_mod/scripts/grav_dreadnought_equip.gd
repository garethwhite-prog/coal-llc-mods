class_name GravDreadnoughtEquipEffect
extends EquipEffect

@export var damage: float = 110.0
@export var fire_rate: float = 0.55

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
		_fire_orbital_shell(player)

func _get_passive_stat(stat_name: String) -> float:
	if not Gvars or not ("passives" in Gvars) or not Gvars.passives:
		return 0.0
	var p = Gvars.passives
	if p.has_meta(stat_name):
		return float(p.get_meta(stat_name))
	if stat_name in p:
		return float(p.get(stat_name))
	return 0.0

func _fire_orbital_shell(player) -> void:
	var rate_mult: float = 1.0 + _get_passive_stat("dread_fire_rate")
	fire_cooldown = max(0.12, fire_rate / rate_mult)

	if audio_player and is_instance_valid(audio_player):
		audio_player.pitch_scale = randf_range(0.7, 0.85)
		audio_player.play()

	var p_pos: Vector2 = player.global_position
	var pointer_pos: Vector2 = player.pointer_global_pos
	var dir: Vector2 = (pointer_pos - p_pos).normalized()

	if weapon_visual and is_instance_valid(weapon_visual):
		weapon_visual.position -= dir * 4.0
		var tween = player.create_tween()
		tween.tween_property(weapon_visual, "position", Vector2(4, 2), 0.08)

	var tilemap = player.tilemap
	if not tilemap:
		return

	var dmg_mult: float = 1.0 + _get_passive_stat("dread_shell_damage")
	var eff_dmg: float = damage * dmg_mult

	# Fires heavy mass penetrator
	for dist in range(12, 160, 8):
		var check_pos: Vector2 = p_pos + (dir * float(dist))
		var cell: Vector2i = tilemap.local_to_map(check_pos)
		if tilemap.is_tile_breakable(cell):
			tilemap.damageTileCoords(cell, eff_dmg)
			_spawn_impact(player, check_pos)
			break

func _spawn_impact(player: Node2D, at_pos: Vector2) -> void:
	var parent = player.get_parent()
	if not parent:
		parent = player
	var ring := Line2D.new()
	ring.width = 3.0
	ring.default_color = Color(0.6, 1.0, 0.2, 0.95)
	for i in range(13):
		var rad: float = float(i) * TAU / 12.0
		ring.add_point(at_pos + Vector2(cos(rad), sin(rad)) * 6.0)
	parent.add_child(ring)
	var tween = parent.create_tween()
	tween.tween_property(ring, "scale", Vector2(2.5, 2.5), 0.12)
	tween.tween_callback(ring.queue_free)