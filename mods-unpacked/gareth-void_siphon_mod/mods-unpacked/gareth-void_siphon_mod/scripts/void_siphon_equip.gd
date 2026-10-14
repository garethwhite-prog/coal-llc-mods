class_name VoidSiphonEquipEffect
extends EquipEffect

@export var damage: float = 120.0
@export var radius: float = 3.5

var weapon_visual: Sprite2D = null
var pulse_cooldown: float = 0.0
var _is_using: bool = false
var _auto_pulse_toggle: bool = false
var audio_player: AudioStreamPlayer2D = null

func start(player, item):
	if "tool" in player and player.tool:
		player.tool.visible = false

	if ResourceLoader.exists("res://assets/sound/sound effects/SwordThud.wav"):
		audio_player = AudioStreamPlayer2D.new()
		audio_player.stream = load("res://assets/sound/sound effects/SwordThud.wav")
		player.add_child(audio_player)

	weapon_visual = Sprite2D.new()
	weapon_visual.texture = item.itemTexture
	weapon_visual.offset = Vector2(0, -4)
	weapon_visual.position = Vector2(4, 2)
	weapon_visual.visible = true
	player.add_child(weapon_visual)
	_is_using = false
	_auto_pulse_toggle = false

func end(player):
	if "tool" in player and player.tool:
		player.tool.visible = true
	if audio_player and is_instance_valid(audio_player):
		audio_player.queue_free()
	if weapon_visual and is_instance_valid(weapon_visual):
		weapon_visual.queue_free()
	_is_using = false
	_auto_pulse_toggle = false

func physics_process(player, delta):
	if pulse_cooldown > 0.0:
		pulse_cooldown -= delta

	if weapon_visual and is_instance_valid(weapon_visual):
		weapon_visual.rotation += delta * 4.0

	if Input.is_action_pressed("useItem") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_is_using = true
	elif Input.is_action_just_released("useItem") or (not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not _auto_pulse_toggle):
		_is_using = false

	if Input.is_action_just_pressed("toggle_use_item") or Input.is_action_just_pressed("rightMouseClick"):
		_auto_pulse_toggle = not _auto_pulse_toggle
		_is_using = _auto_pulse_toggle

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_is_using = true

	if _is_using and pulse_cooldown <= 0.0:
		_trigger_singularity_implosion(player)

func _get_passive_stat(stat_name: String) -> float:
	if not Gvars or not ("passives" in Gvars) or not Gvars.passives:
		return 0.0
	var p = Gvars.passives
	if p.has_meta(stat_name):
		return float(p.get_meta(stat_name))
	if stat_name in p:
		return float(p.get(stat_name))
	return 0.0

func _trigger_singularity_implosion(player) -> void:
	pulse_cooldown = 0.38
	if audio_player and is_instance_valid(audio_player):
		audio_player.pitch_scale = randf_range(0.65, 0.8)
		audio_player.play()

	var p_pos: Vector2 = player.global_position
	var pointer_pos: Vector2 = player.pointer_global_pos
	var dir: Vector2 = (pointer_pos - p_pos).normalized()
	var center_pos: Vector2 = p_pos + (dir * 48.0)

	var tilemap = player.tilemap
	if not tilemap:
		return

	var dmg_mult: float = 1.0 + _get_passive_stat("void_implosion_damage")
	var eff_dmg: float = damage * dmg_mult

	var rad_mult: float = 1.0 + _get_passive_stat("void_pull_radius")
	var eff_rad: float = radius * rad_mult

	# Singularity Implosion Damage
	var cell_center: Vector2i = tilemap.local_to_map(center_pos)
	var r_int: int = int(ceil(eff_rad))
	for dx in range(-r_int, r_int + 1):
		for dy in range(-r_int, r_int + 1):
			if Vector2(dx, dy).length() <= eff_rad:
				var cell: Vector2i = cell_center + Vector2i(dx, dy)
				if tilemap.is_tile_breakable(cell):
					tilemap.damageTileCoords(cell, eff_dmg)

	# Gravitational Ore Vacuum Pull
	var items = player.get_tree().get_nodes_in_group("pickups")
	for item_node in items:
		if is_instance_valid(item_node) and "global_position" in item_node:
			if (item_node.global_position - center_pos).length() <= (eff_rad * 24.0):
				var pull_dir = (p_pos - item_node.global_position).normalized()
				if "velocity" in item_node:
					item_node.velocity += pull_dir * 320.0
				else:
					item_node.global_position += pull_dir * 12.0

	_spawn_singularity_visual(player, center_pos, eff_rad * 14.0)

func _spawn_singularity_visual(player: Node2D, at_pos: Vector2, max_radius: float) -> void:
	var parent = player.get_parent()
	if not parent:
		parent = player

	var ring := Line2D.new()
	ring.width = 3.5
	ring.default_color = Color(0.7, 0.2, 0.95, 0.95)
	var segs: int = 18
	for i in range(segs + 1):
		var ang: float = float(i) * TAU / float(segs)
		ring.add_point(at_pos + Vector2(cos(ang), sin(ang)) * max_radius)
	parent.add_child(ring)

	var tween = parent.create_tween()
	tween.set_parallel(true)
	# Implosion effect: shrinks rapidly into nothingness
	tween.tween_property(ring, "scale", Vector2(0.1, 0.1), 0.18)
	tween.tween_property(ring, "modulate:a", 0.0, 0.18)
	tween.set_parallel(false)
	tween.tween_callback(ring.queue_free)