class_name ChronoIndustrialistEquipEffect
extends EquipEffect

@export var damage: float = 70.0
@export var strike_rate: float = 0.20

var weapon_visual: Sprite2D = null
var fire_cooldown: float = 0.0
var _is_using: bool = false
var _auto_fire_toggle: bool = false
var audio_player: AudioStreamPlayer2D = null
var _strike_count: int = 0

func start(player, item):
	if "tool" in player and player.tool:
		player.tool.visible = false

	if ResourceLoader.exists("res://assets/sound/sound effects/SwordHit.wav"):
		audio_player = AudioStreamPlayer2D.new()
		audio_player.stream = load("res://assets/sound/sound effects/SwordHit.wav")
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
		_execute_chrono_strike(player)

func _get_passive_stat(stat_name: String) -> float:
	if not Gvars or not ("passives" in Gvars) or not Gvars.passives:
		return 0.0
	var p = Gvars.passives
	if p.has_meta(stat_name):
		return float(p.get_meta(stat_name))
	if stat_name in p:
		return float(p.get(stat_name))
	return 0.0

func _execute_chrono_strike(player) -> void:
	var rate_mult: float = 1.0 + _get_passive_stat("chrono_tick_rate")
	fire_cooldown = max(0.04, strike_rate / rate_mult)
	_strike_count += 1

	if audio_player and is_instance_valid(audio_player):
		audio_player.pitch_scale = randf_range(1.2, 1.5)
		audio_player.play()

	var p_pos: Vector2 = player.global_position
	var pointer_pos: Vector2 = player.pointer_global_pos
	var dir: Vector2 = (pointer_pos - p_pos).normalized()

	if weapon_visual and is_instance_valid(weapon_visual):
		weapon_visual.position -= dir * 3.0
		var tween = player.create_tween()
		tween.tween_property(weapon_visual, "position", Vector2(4, 2), 0.05)

	var tilemap = player.tilemap
	if not tilemap:
		return

	var is_stasis_shockwave: bool = (_strike_count % 10 == 0)
	var dmg_mult: float = 1.0 + _get_passive_stat("chrono_shockwave_damage")
	var eff_dmg: float = damage * dmg_mult * (2.0 if is_stasis_shockwave else 1.0)

	var hit_cell = null
	var hit_pos: Vector2 = p_pos + (dir * 120.0)

	for dist in range(8, 120, 6):
		var test_pos: Vector2 = p_pos + (dir * float(dist))
		var local_pos: Vector2 = tilemap.to_local(test_pos)
		var cell: Vector2i = tilemap.local_to_map(local_pos)
		if tilemap.is_tile_breakable(cell):
			hit_cell = cell
			hit_pos = test_pos
			break

	if hit_cell != null:
		if tilemap.has_method("damageTile"):
			tilemap.damageTile(hit_pos, eff_dmg)
		if tilemap.has_method("damageTileCoords"):
			tilemap.damageTileCoords(hit_cell, eff_dmg)

		if is_stasis_shockwave:
			_spawn_stasis_ripple(player, hit_pos)
			for offset in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
				var n_cell: Vector2i = hit_cell + offset
				if tilemap.is_tile_breakable(n_cell):
					if tilemap.has_method("damageTileCoords"):
						tilemap.damageTileCoords(n_cell, eff_dmg * 0.7)

func _spawn_stasis_ripple(player: Node2D, at_pos: Vector2) -> void:
	var parent = player.get_parent()
	if not parent:
		parent = player

	var ripple := Line2D.new()
	ripple.top_level = true
	ripple.z_index = 51
	ripple.width = 3.0
	ripple.default_color = Color(1.0, 0.85, 0.25, 0.95)
	for i in range(17):
		var ang: float = float(i) * TAU / 16.0
		ripple.add_point(at_pos + Vector2(cos(ang), sin(ang)) * 6.0)
	parent.add_child(ripple)

	var tween = parent.create_tween()
	tween.tween_property(ripple, "scale", Vector2(3.5, 3.5), 0.14)
	tween.tween_property(ripple, "modulate:a", 0.0, 0.14)
	tween.tween_callback(ripple.queue_free)