class_name KnightSwordEquipEffect
extends EquipEffect

const SWORD_THUD := preload("res://assets/sound/sound effects/SwordThud.wav")
var audio_player: AudioStreamPlayer2D
var sword_visual: Sprite2D = null
var is_swinging: bool = false
var swing_cooldown: float = 0.0
var _is_using: bool = false
var _auto_swing_toggle: bool = false

func start(player, item):
	if "tool" in player and player.tool:
		player.tool.visible = false

	audio_player = AudioStreamPlayer2D.new()
	audio_player.stream = SWORD_THUD
	player.add_child(audio_player)

	sword_visual = Sprite2D.new()
	sword_visual.texture = item.itemTexture
	sword_visual.offset = Vector2(0, -14)
	sword_visual.position = Vector2(4, 0)
	sword_visual.visible = true
	player.add_child(sword_visual)
	_is_using = false
	_auto_swing_toggle = false

func end(player):
	if "tool" in player and player.tool:
		player.tool.visible = true
	if audio_player and is_instance_valid(audio_player):
		audio_player.queue_free()
	if sword_visual and is_instance_valid(sword_visual):
		sword_visual.queue_free()
	_is_using = false
	_auto_swing_toggle = false

func physics_process(player, delta):
	if swing_cooldown > 0.0:
		swing_cooldown -= delta

	if sword_visual and is_instance_valid(sword_visual) and not is_swinging:
		var p_pos: Vector2 = player.global_position
		var pointer_pos: Vector2 = player.pointer_global_pos
		var angle: float = (pointer_pos - p_pos).angle()
		sword_visual.rotation = angle + PI/4
		sword_visual.flip_v = (pointer_pos.x < p_pos.x)

	# 1. Left-click hold and release
	if Input.is_action_pressed("useItem") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_is_using = true
	elif Input.is_action_just_released("useItem") or (not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not _auto_swing_toggle):
		_is_using = false

	# 2. Right-click toggle continuous attack (vanilla toggle_use_item pattern)
	if Input.is_action_just_pressed("toggle_use_item") or Input.is_action_just_pressed("rightMouseClick"):
		_auto_swing_toggle = not _auto_swing_toggle
		_is_using = _auto_swing_toggle

	# 3. Direct Right-click hold
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_is_using = true

	if _is_using and swing_cooldown <= 0.0:
		_cleave_attack(player)

func _get_passive_stat(stat_name: String) -> float:
	if not Gvars or not ("passives" in Gvars) or not Gvars.passives:
		return 0.0
	var p = Gvars.passives
	if p.has_meta(stat_name):
		return float(p.get_meta(stat_name))
	if stat_name in p:
		return float(p.get(stat_name))
	return 0.0

func _cleave_attack(player) -> void:
	var speed_mult: float = 1.0 + _get_passive_stat("sword_speed")
	swing_cooldown = max(0.06, 0.28 / speed_mult)
	is_swinging = true
	if audio_player:
		audio_player.play()

	var p_pos: Vector2 = player.global_position
	var pointer_pos: Vector2 = player.pointer_global_pos
	var dir: Vector2 = (pointer_pos - p_pos).normalized()

	var dmg_mult: float = 1.0 + _get_passive_stat("sword_damage") + _get_passive_stat("axe_damage")
	var base_dmg: float = 70.0 * dmg_mult

	var range_mult: float = 1.0 + _get_passive_stat("sword_range")

	if sword_visual and is_instance_valid(sword_visual):
		var center_angle: float = dir.angle()
		var tween = player.create_tween()
		sword_visual.rotation = center_angle - deg_to_rad(65)
		var tween_time: float = max(0.04, 0.14 / speed_mult)
		tween.tween_property(sword_visual, "rotation", center_angle + deg_to_rad(65), tween_time)
		tween.tween_callback(func(): is_swinging = false)

	var tilemap = player.tilemap
	if tilemap:
		var cells_damaged: Array[Vector2i] = []
		var max_dist: float = 48.0 * range_mult
		var distances = [16.0, 32.0, max_dist]
		if range_mult > 1.2:
			distances.append(max_dist * 1.15)

		for angle_deg in [-60, -30, 0, 30, 60]:
			var test_dir: Vector2 = dir.rotated(deg_to_rad(angle_deg))
			for dist in distances:
				var t_pos: Vector2 = p_pos + test_dir * dist
				var cell: Vector2i = tilemap.local_to_map(t_pos)
				if not cells_damaged.has(cell):
					cells_damaged.append(cell)
					if tilemap.is_tile_breakable(cell):
						tilemap.damageTileCoords(cell, base_dmg)