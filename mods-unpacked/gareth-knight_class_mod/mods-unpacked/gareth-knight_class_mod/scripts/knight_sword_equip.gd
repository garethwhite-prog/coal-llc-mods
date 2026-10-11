class_name KnightSwordEquipEffect
extends EquipEffect

const SWORD_THUD := preload("res://assets/sound/sound effects/SwordThud.wav")
var audio_player: AudioStreamPlayer2D

func start(player, _item):
	audio_player = AudioStreamPlayer2D.new()
	audio_player.stream = SWORD_THUD
	player.add_child(audio_player)

func end(player):
	if audio_player and is_instance_valid(audio_player):
		audio_player.queue_free()

func physics_process(player, _delta):
	if Input.is_action_just_pressed("useItem") or Input.is_action_just_pressed("mine"):
		_cleave_attack(player)

func _cleave_attack(player) -> void:
	if audio_player:
		audio_player.play()
	var p_pos: Vector2 = player.global_position
	var pointer_pos: Vector2 = player.pointer_global_pos
	var dir: Vector2 = (pointer_pos - p_pos).normalized()
	var base_dmg: float = 70.0
	if Gvars and ("passives" in Gvars) and Gvars.passives and ("axe_damage" in Gvars.passives):
		base_dmg *= (1.0 + Gvars.passives.axe_damage)

	var tilemap = player.tilemap
	if tilemap:
		for angle_deg in [-60, -30, 0, 30, 60]:
			var test_dir: Vector2 = dir.rotated(deg_to_rad(angle_deg))
			for dist in [16.0, 32.0, 48.0]:
				var t_pos: Vector2 = p_pos + test_dir * dist
				var m_pos: Vector2i = tilemap.local_to_map(t_pos)
				if tilemap.is_tile_collision(m_pos):
					tilemap.damage_tile(m_pos, base_dmg)