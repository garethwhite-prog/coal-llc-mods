class_name JediSaberEquipEffect
extends EquipEffect

@export var damage: float = 75.0
@export var reach: float = 28.0
@export var swing_speed: float = 0.28

var weapon_visual: Sprite2D = null
var swing_cooldown: float = 0.0
var _is_using: bool = false
var _auto_swing_toggle: bool = false
var audio_player: AudioStreamPlayer2D = null
var _swing_animating: bool = false

func start(player, item):
	if "tool" in player and player.tool:
		player.tool.visible = false

	if ResourceLoader.exists("res://assets/sound/sound effects/SwordHit.wav"):
		audio_player = AudioStreamPlayer2D.new()
		audio_player.stream = load("res://assets/sound/sound effects/SwordHit.wav")
		player.add_child(audio_player)

	weapon_visual = Sprite2D.new()
	weapon_visual.texture = item.itemTexture
	weapon_visual.offset = Vector2(8, -8)
	weapon_visual.position = Vector2(2, 2)
	weapon_visual.visible = true
	player.add_child(weapon_visual)
	_is_using = false
	_auto_swing_toggle = false

func end(player):
	if "tool" in player and player.tool:
		player.tool.visible = true
	if audio_player and is_instance_valid(audio_player):
		audio_player.queue_free()
	if weapon_visual and is_instance_valid(weapon_visual):
		weapon_visual.queue_free()
	_is_using = false
	_auto_swing_toggle = false

func physics_process(player, delta):
	if swing_cooldown > 0.0:
		swing_cooldown -= delta

	if weapon_visual and is_instance_valid(weapon_visual) and not _swing_animating:
		var p_pos: Vector2 = player.global_position
		var pointer_pos: Vector2 = player.pointer_global_pos
		var angle: float = (pointer_pos - p_pos).angle()
		weapon_visual.rotation = angle + 0.785
		weapon_visual.flip_v = (pointer_pos.x < p_pos.x)

	if Input.is_action_pressed("useItem") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_is_using = true
	elif Input.is_action_just_released("useItem") or (not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not _auto_swing_toggle):
		_is_using = false

	if Input.is_action_just_pressed("toggle_use_item") or Input.is_action_just_pressed("rightMouseClick"):
		_auto_swing_toggle = not _auto_swing_toggle
		_is_using = _auto_swing_toggle

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_is_using = true

	if _is_using and swing_cooldown <= 0.0:
		_execute_saber_cleave(player)

func _get_passive_stat(stat_name: String) -> float:
	if not Gvars or not ("passives" in Gvars) or not Gvars.passives:
		return 0.0
	var p = Gvars.passives
	if p.has_meta(stat_name):
		return float(p.get_meta(stat_name))
	if stat_name in p:
		return float(p.get(stat_name))
	return 0.0

func _execute_saber_cleave(player) -> void:
	var speed_mult: float = 1.0 + _get_passive_stat("jedi_swing_rate")
	swing_cooldown = max(0.06, swing_speed / speed_mult)

	if audio_player and is_instance_valid(audio_player):
		audio_player.pitch_scale = randf_range(1.15, 1.45)
		audio_player.play()

	var p_pos: Vector2 = player.global_position
	var pointer_pos: Vector2 = player.pointer_global_pos
	var base_angle: float = (pointer_pos - p_pos).angle()

	# Animated Melee Cleave
	if weapon_visual and is_instance_valid(weapon_visual):
		_swing_animating = true
		weapon_visual.rotation = base_angle - 1.1
		var tween = player.create_tween()
		tween.tween_property(weapon_visual, "rotation", base_angle + 1.1, 0.09)
		tween.tween_callback(func(): _swing_animating = false)

	var tilemap = player.tilemap
	if not tilemap:
		return

	var dmg_mult: float = 1.0 + _get_passive_stat("jedi_saber_damage")
	var eff_dmg: float = damage * dmg_mult

	var reach_mult: float = 1.0 + _get_passive_stat("jedi_cleave_reach")
	var eff_reach: float = reach * reach_mult

	# Cleave across 7 arc rays
	var hit_cells: Array[Vector2i] = []
	for offset_deg in [-45, -30, -15, 0, 15, 30, 45]:
		var rad: float = base_angle + deg_to_rad(offset_deg)
		var check_dir: Vector2 = Vector2(cos(rad), sin(rad))
		for d in range(8, int(eff_reach), 6):
			var cell_pos: Vector2 = p_pos + (check_dir * float(d))
			var cell: Vector2i = tilemap.local_to_map(cell_pos)
			if not hit_cells.has(cell) and tilemap.is_tile_breakable(cell):
				hit_cells.append(cell)
				tilemap.damageTileCoords(cell, eff_dmg)

	_spawn_saber_arc_visual(player, p_pos, base_angle, eff_reach)

func _spawn_saber_arc_visual(player: Node2D, origin: Vector2, angle: float, arc_radius: float) -> void:
	var parent = player.get_parent()
	if not parent:
		parent = player

	var arc := Line2D.new()
	arc.width = 4.0
	arc.default_color = Color(0.3, 0.8, 1.0, 0.95)
	for i in range(-5, 6):
		var rad: float = angle + deg_to_rad(float(i) * 9.0)
		arc.add_point(origin + Vector2(cos(rad), sin(rad)) * arc_radius)
	parent.add_child(arc)

	var tween = parent.create_tween()
	tween.tween_property(arc, "modulate:a", 0.0, 0.08)
	tween.tween_callback(arc.queue_free)