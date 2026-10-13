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
	fire_cooldown = 0.28
	if audio_player and is_instance_valid(audio_player):
		audio_player.pitch_scale = randf_range(0.75, 0.9)
		audio_player.play()

	var p_pos: Vector2 = player.global_position
	var pointer_pos: Vector2 = player.pointer_global_pos
	var dir: Vector2 = (pointer_pos - p_pos).normalized()

	if weapon_visual and is_instance_valid(weapon_visual):
		var orig_pos = weapon_visual.position
		weapon_visual.position -= dir * 4.0
		var tween = player.create_tween()
		tween.tween_property(weapon_visual, "position", orig_pos, 0.08)

	var tilemap = player.tilemap
	if not tilemap:
		return

	var hit_cell = null
	for dist in range(8, 120, 6):
		var check_pos: Vector2 = p_pos + (dir * float(dist))
		var cell: Vector2i = tilemap.local_to_map(check_pos)
		if tilemap.is_tile_breakable(cell):
			hit_cell = cell
			break

	if hit_cell == null:
		return

	var eff_dmg: float = damage * (1.0 + _get_passive_stat("pickaxe_damage"))
	var eff_limit: int = seam_limit + int(_get_passive_stat("pickaxe_range") * 6.0)

	var visited: Array[Vector2i] = []
	var queue: Array[Vector2i] = [hit_cell]
	visited.append(hit_cell)

	var target_atlas = null
	if tilemap.has_method("get_cell_atlas_coords"):
		target_atlas = tilemap.get_cell_atlas_coords(0, hit_cell)

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
						var n_atlas = tilemap.get_cell_atlas_coords(0, neighbor)
						is_same_seam = (n_atlas == target_atlas)
					if is_same_seam:
						queue.append(neighbor)
