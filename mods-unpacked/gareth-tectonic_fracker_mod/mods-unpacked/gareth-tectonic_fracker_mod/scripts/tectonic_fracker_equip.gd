class_name TectonicFrackerEquipEffect
extends EquipEffect

@export var damage: float = 80.0
@export var seam_limit: int = 18

var weapon_visual: Sprite2D = null
var fire_cooldown: float = 0.0
var _is_using: bool = false
var _auto_fire_toggle: bool = false
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
	weapon_visual.offset = Vector2(10, 0)
	weapon_visual.position = Vector2(2, 2)
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
		_fire_seismic_pulse(player)

func _get_passive_stat(stat_name: String) -> float:
	if not Gvars or not ("passives" in Gvars) or not Gvars.passives:
		return 0.0
	var p = Gvars.passives
	if p.has_meta(stat_name):
		return float(p.get_meta(stat_name))
	if stat_name in p:
		return float(p.get(stat_name))
	return 0.0

func _fire_seismic_pulse(player) -> void:
	var fire_rate_mult: float = 1.0 + _get_passive_stat("fracker_fire_rate")
	fire_cooldown = max(0.06, 0.26 / fire_rate_mult)

	if audio_player and is_instance_valid(audio_player):
		audio_player.pitch_scale = randf_range(0.72, 0.88)
		audio_player.play()

	var p_pos: Vector2 = player.global_position
	var pointer_pos: Vector2 = player.pointer_global_pos
	var dir: Vector2 = (pointer_pos - p_pos).normalized()
	var muzzle_pos: Vector2 = p_pos + (dir * 18.0)

	if weapon_visual and is_instance_valid(weapon_visual):
		var orig_pos = weapon_visual.position
		weapon_visual.position -= dir * 5.0
		var tween = player.create_tween()
		tween.tween_property(weapon_visual, "position", orig_pos, 0.08)

	var tilemap = player.tilemap
	if not tilemap:
		return

	var max_reach: float = 140.0
	var hit_cell = null
	var hit_world_pos: Vector2 = muzzle_pos + (dir * max_reach)

	for dist in range(6, int(max_reach), 6):
		var check_pos: Vector2 = muzzle_pos + (dir * float(dist))
		var cell: Vector2i = tilemap.local_to_map(check_pos)
		if tilemap.is_tile_breakable(cell):
			hit_cell = cell
			hit_world_pos = tilemap.map_to_local(cell)
			break

	_spawn_acoustic_beam(player, muzzle_pos, hit_world_pos)

	if hit_cell == null:
		return

	_spawn_impact_ring(player, hit_world_pos)

	var dmg_mult: float = 1.0 + _get_passive_stat("fracker_pulse_damage")
	var eff_dmg: float = damage * dmg_mult

	var seam_mult: float = 1.0 + _get_passive_stat("fracker_seam_resonance")
	var eff_limit: int = int(float(seam_limit) * seam_mult)

	var visited: Array[Vector2i] = []
	var queue: Array[Vector2i] = [hit_cell]
	visited.append(hit_cell)

	var target_atlas = null
	if tilemap.has_method("get_cell_atlas_coords"):
		target_atlas = tilemap.get_cell_atlas_coords(hit_cell)

	while queue.size() > 0 and visited.size() <= eff_limit:
		var curr = queue.pop_front()
		tilemap.damageTileCoords(curr, eff_dmg)

		for offset in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var neighbor: Vector2i = curr + offset
			if not visited.has(neighbor):
				visited.append(neighbor)
				if tilemap.is_tile_breakable(neighbor):
					var is_same_seam = true
					if target_atlas != null and tilemap.has_method("get_cell_atlas_coords"):
						var n_atlas = tilemap.get_cell_atlas_coords(neighbor)
						is_same_seam = (n_atlas == target_atlas)
					if is_same_seam:
						queue.append(neighbor)

func _spawn_acoustic_beam(player: Node2D, from_pos: Vector2, to_pos: Vector2) -> void:
	var parent = player.get_parent()
	if not parent:
		parent = player

	var beam := Line2D.new()
	beam.width = 6.0
	beam.default_color = Color(0.2, 0.95, 1.0, 0.95)
	beam.add_point(from_pos)
	beam.add_point(to_pos)
	parent.add_child(beam)

	var tween = parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(beam, "width", 14.0, 0.12)
	tween.tween_property(beam, "modulate:a", 0.0, 0.12)
	tween.set_parallel(false)
	tween.tween_callback(beam.queue_free)

func _spawn_impact_ring(player: Node2D, at_pos: Vector2) -> void:
	var parent = player.get_parent()
	if not parent:
		parent = player

	var ring := Line2D.new()
	ring.width = 2.5
	ring.default_color = Color(0.9, 1.0, 1.0, 0.9)
	var segs: int = 16
	for i in range(segs + 1):
		var ang: float = float(i) * TAU / float(segs)
		ring.add_point(at_pos + Vector2(cos(ang), sin(ang)) * 4.0)
	parent.add_child(ring)

	var tween = parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(3.5, 3.5), 0.16)
	tween.tween_property(ring, "modulate:a", 0.0, 0.16)
	tween.set_parallel(false)
	tween.tween_callback(ring.queue_free)