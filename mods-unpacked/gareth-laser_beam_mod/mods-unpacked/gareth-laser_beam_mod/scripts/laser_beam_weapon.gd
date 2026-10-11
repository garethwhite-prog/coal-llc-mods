class_name LaserBeamWeapon
extends Node2D

var beam_line: Line2D
var audio_player: AudioStreamPlayer2D
var max_range: float = 480.0
var damage_per_tick: float = 55.0

func _ready() -> void:
	beam_line = Line2D.new()
	beam_line.width = 14.0
	beam_line.default_color = Color(0.2, 0.9, 1.0, 0.95)
	beam_line.texture_mode = Line2D.LINE_TEXTURE_TILE

	if ResourceLoader.exists("res://shaders/laser.gdshader"):
		var sm := ShaderMaterial.new()
		sm.shader = load("res://shaders/laser.gdshader")
		sm.set_shader_parameter("energy", 4.0)
		sm.set_shader_parameter("speed", 2.5)
		sm.set_shader_parameter("color", Color(0.9, 1.0, 1.0, 1.0))
		sm.set_shader_parameter("outline_color", Color(0.2, 0.8, 1.0, 1.0))
		beam_line.material = sm

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
		var step_dist: float = 12.0
		var current_step: float = 0.0
		while current_step < max_range:
			var test_pos := origin + dir * current_step
			var map_pos := tilemap.local_to_map(test_pos)
			if tilemap.is_tile_collision(map_pos):
				tilemap.damage_tile(map_pos, damage_per_tick)
				beam_line.set_point_position(1, to_local(test_pos))
				break
			current_step += step_dist

func stop_beam() -> void:
	beam_line.visible = false
	beam_line.clear_points()
	if audio_player.playing:
		audio_player.stop()