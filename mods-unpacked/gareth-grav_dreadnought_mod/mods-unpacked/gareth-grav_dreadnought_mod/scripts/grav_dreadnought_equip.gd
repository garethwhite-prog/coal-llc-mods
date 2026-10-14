class_name GravDreadnoughtEquipEffect
extends EquipEffect

@export var damage: float = 110.0
@export var fire_rate: float = 0.55

var weapon_visual: Sprite2D = null
var fire_cooldown: float = 0.0
var _is_using: bool = false
var _auto_fire_toggle: bool = false
var audio_player: AudioStreamPlayer2D = null

# Active orbiting shells array: Array of Dictionary { "node": Node2D, "angle": float, "radius": float, "life": float }
var _orbiting_shells: Array = []
const MAX_ORBITAL_SHELLS: int = 6
const ORBIT_RADIUS: float = 38.0
const ORBIT_SPEED: float = 3.8

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

	for shell in _orbiting_shells:
		if is_instance_valid(shell.get("node")):
			shell["node"].queue_free()
	_orbiting_shells.clear()

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
		_spawn_orbital_shell(player)

	_update_orbiting_shells(player, delta)

func _get_passive_stat(stat_name: String) -> float:
	if not Gvars or not ("passives" in Gvars) or not Gvars.passives:
		return 0.0
	var p = Gvars.passives
	if p.has_meta(stat_name):
		return float(p.get_meta(stat_name))
	if stat_name in p:
		return float(p.get(stat_name))
	return 0.0

func _spawn_orbital_shell(player) -> void:
	var rate_mult: float = 1.0 + _get_passive_stat("dread_fire_rate")
	fire_cooldown = max(0.10, fire_rate / rate_mult)

	if audio_player and is_instance_valid(audio_player):
		audio_player.pitch_scale = randf_range(0.75, 0.9)
		audio_player.play()

	# Clean expired shells
	var active_shells: Array = []
	for s in _orbiting_shells:
		if is_instance_valid(s.get("node")):
			active_shells.append(s)
	_orbiting_shells = active_shells

	if _orbiting_shells.size() >= MAX_ORBITAL_SHELLS:
		var oldest = _orbiting_shells.pop_front()
		if is_instance_valid(oldest.get("node")):
			oldest["node"].queue_free()

	var p_pos: Vector2 = player.global_position
	var pointer_pos: Vector2 = player.pointer_global_pos
	var spawn_angle: float = (pointer_pos - p_pos).angle()

	var shell_node := Sprite2D.new()
	shell_node.top_level = true
	shell_node.z_index = 45
	if weapon_visual and weapon_visual.texture:
		shell_node.texture = weapon_visual.texture
		shell_node.scale = Vector2(0.45, 0.45)
	player.get_parent().add_child(shell_node)

	_orbiting_shells.append({
		"node": shell_node,
		"angle": spawn_angle,
		"radius": ORBIT_RADIUS,
		"life": 12.0
	})

func _update_orbiting_shells(player, delta: float) -> void:
	var tilemap = player.tilemap
	var p_pos: Vector2 = player.global_position
	var dmg_mult: float = 1.0 + _get_passive_stat("dread_shell_damage")
	var eff_dmg: float = damage * dmg_mult

	var surviving: Array = []
	for shell in _orbiting_shells:
		var node = shell.get("node")
		if not is_instance_valid(node):
			continue

		shell["life"] -= delta
		if shell["life"] <= 0.0:
			node.queue_free()
			continue

		shell["angle"] += ORBIT_SPEED * delta
		var shell_pos: Vector2 = p_pos + Vector2(cos(shell["angle"]), sin(shell["angle"])) * shell["radius"]
		node.global_position = shell_pos
		node.rotation = shell["angle"] + 1.57

		var collided: bool = false
		if tilemap:
			var local_pos: Vector2 = tilemap.to_local(shell_pos)
			var cell: Vector2i = tilemap.local_to_map(local_pos)
			if tilemap.is_tile_breakable(cell):
				if tilemap.has_method("damageTile"):
					tilemap.damageTile(shell_pos, eff_dmg)
				if tilemap.has_method("damageTileCoords"):
					tilemap.damageTileCoords(cell, eff_dmg)
				_spawn_kinetic_burst(player, shell_pos)
				node.queue_free()
				collided = true

		if not collided:
			surviving.append(shell)

	_orbiting_shells = surviving

func _spawn_kinetic_burst(player: Node2D, at_pos: Vector2) -> void:
	var parent = player.get_parent()
	if not parent:
		parent = player
	var ring := Line2D.new()
	ring.top_level = true
	ring.z_index = 50
	ring.width = 3.0
	ring.default_color = Color(0.65, 1.0, 0.25, 0.95)
	for i in range(13):
		var ang: float = float(i) * TAU / 12.0
		ring.add_point(at_pos + Vector2(cos(ang), sin(ang)) * 6.0)
	parent.add_child(ring)

	var tween = parent.create_tween()
	tween.tween_property(ring, "scale", Vector2(2.4, 2.4), 0.10)
	tween.tween_property(ring, "modulate:a", 0.0, 0.10)
	tween.tween_callback(ring.queue_free)