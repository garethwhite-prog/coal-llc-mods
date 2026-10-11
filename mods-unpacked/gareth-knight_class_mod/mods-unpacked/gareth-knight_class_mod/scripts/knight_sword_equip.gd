class_name KnightSwordEquipEffect
extends EquipEffect

const SWORD_THUD := preload("res://assets/sound/sound effects/SwordThud.wav")
var audio_player: AudioStreamPlayer2D
var sword_visual: Sprite2D = null
var is_swinging: bool = false
var swing_cooldown: float = 0.0

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

func end(player):
	if "tool" in player and player.tool:
		player.tool.visible = true
	if audio_player and is_instance_valid(audio_player):
		audio_player.queue_free()
	if sword_visual and is_instance_valid(sword_visual):
		sword_visual.queue_free()

func physics_process(player, delta):
	if swing_cooldown > 0.0:
		swing_cooldown -= delta

	if sword_visual and is_instance_valid(sword_visual) and not is_swinging:
		var p_pos: Vector2 = player.global_position
		var pointer_pos: Vector2 = player.pointer_global_pos
		var angle: float = (pointer_pos - p_pos).angle()
		sword_visual.rotation = angle + PI/4
		if pointer_pos.x < p_pos.x:
			sword_visual.flip_v = true
		else:
			sword_visual.flip_v = false

	if Input.is_action_just_pressed("useItem") and swing_cooldown <= 0.0:
		_cleave_attack(player)

func _cleave_attack(player) -> void:
	swing_cooldown = 0.28
	is_swinging = true
	if audio_player:
		audio_player.play()

	var p_pos: Vector2 = player.global_position
	var pointer_pos: Vector2 = player.pointer_global_pos
	var dir: Vector2 = (pointer_pos - p_pos).normalized()
	var base_dmg: float = 70.0
	if Gvars and ("passives" in Gvars) and Gvars.passives and ("axe_damage" in Gvars.passives):
		base_dmg *= (1.0 + Gvars.passives.axe_damage)

	if sword_visual and is_instance_valid(sword_visual):
		var center_angle: float = dir.angle()
		var tween = player.create_tween()
		sword_visual.rotation = center_angle - deg_to_rad(65)
		tween.tween_property(sword_visual, "rotation", center_angle + deg_to_rad(65), 0.14)
		tween.tween_callback(func(): is_swinging = false)

	var tilemap = player.tilemap
	if tilemap:
		for angle_deg in [-60, -30, 0, 30, 60]:
			var test_dir: Vector2 = dir.rotated(deg_to_rad(angle_deg))
			for dist in [16.0, 32.0, 48.0]:
				var t_pos: Vector2 = p_pos + test_dir * dist
				var m_pos: Vector2i = tilemap.local_to_map(t_pos)
				if tilemap.is_tile_collision(m_pos):
					tilemap.damageTileCoords(m_pos, base_dmg)