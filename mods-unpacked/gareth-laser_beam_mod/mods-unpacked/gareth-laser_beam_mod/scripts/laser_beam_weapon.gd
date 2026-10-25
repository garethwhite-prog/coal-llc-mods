class_name LaserBeamWeapon
extends Node2D

var beam_line: Line2D
var audio_player: AudioStreamPlayer2D
var max_range: float = 520.0
var base_damage_per_tick: float = 65.0

func _ready() -> void:
	z_index = 50
	beam_line = Line2D.new()
	beam_line.width = 8.0
	beam_line.default_color = Color(0.2, 0.9, 1.0, 0.95)
	beam_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	beam_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	beam_line.z_index = 50
	add_child(beam_line)

	audio_player = AudioStreamPlayer2D.new()
	if ResourceLoader.exists("res://assets/sound/sound effects/laser.wav"):
		audio_player.stream = load("res://assets/sound/sound effects/laser.wav")
	add_child(audio_player)

func fire_beam(origin: Vector2, target: Vector2, tilemap: TileMapManager) -> void:
	global_position = origin
	var dir := (target - origin).normalized()
	var end_point := origin + dir * max_range

	beam_line.clear_points()
	beam_line.add_point(Vector2.ZERO)
	beam_line.add_point(to_local(end_point))
	beam_line.visible = true

	if not audio_player.playing:
		audio_player.play()

	if tilemap:
		var step_dist: float = 8.0
		var current_step: float = 0.0
		var mining_mult: float = 1.0
		if Gvars and ("passives" in Gvars) and Gvars.passives:
			mining_mult = 1.0 + float(Gvars.passives.player_pickaxe_mining_damage)
		var tick_damage = base_damage_per_tick * mining_mult

		while current_step < max_range:
			var test_pos := origin + dir * current_step
			var map_pos := tilemap.local_to_map(test_pos)
			if tilemap.is_tile_collision(map_pos) or tilemap.is_tile_breakable(map_pos):
				tilemap.damageTileCoords(map_pos, tick_damage)
				beam_line.set_point_position(1, to_local(test_pos))
				break
			current_step += step_dist

func stop_beam() -> void:
	if is_instance_valid(beam_line):
		beam_line.visible = false
		beam_line.clear_points()
	if is_instance_valid(audio_player) and audio_player.playing:
		audio_player.stop()
