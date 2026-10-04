class_name InfiniPlatformSpawner
extends Node2D

@export var tilemap: TileMapManager

var current_left: Vector2i
var current_right: Vector2i
var left_live: bool = true
var right_live: bool = true
var blocks_placed: int = 0
const MAX_BLOCKS: int = 200
var t: int = 0
var audio_player: AudioStreamPlayer2D

func _ready() -> void:
	current_left = tilemap.local_to_map(global_position)
	current_right = current_left + Vector2i(1, 0)

	audio_player = AudioStreamPlayer2D.new()
	audio_player.stream = load("res://assets/sound/sound effects/pickup.wav")
	add_child(audio_player)
	audio_player.play()

func _physics_process(_delta: float) -> void:
	t += 1

	if left_live:
		var coll_left = tilemap.is_tile_collision(current_left) or not tilemap.does_tile_chunk_exist(current_left) or blocks_placed >= MAX_BLOCKS
		if coll_left:
			left_live = false
		else:
			tilemap.change_tile(current_left, TileMapChunk.Tiles.PLATFORM)
			current_left += Vector2i(-1, 0)
			blocks_placed += 1
			if t % 3 == 0:
				audio_player.global_position = tilemap.map_to_local(current_left)
				audio_player.play()

	if right_live:
		var coll_right = tilemap.is_tile_collision(current_right) or not tilemap.does_tile_chunk_exist(current_right) or blocks_placed >= MAX_BLOCKS
		if coll_right:
			right_live = false
		else:
			tilemap.change_tile(current_right, TileMapChunk.Tiles.PLATFORM)
			current_right += Vector2i(1, 0)
			blocks_placed += 1
			if t % 3 == 0:
				audio_player.global_position = tilemap.map_to_local(current_right)
				audio_player.play()

	if (not left_live and not right_live) or blocks_placed >= MAX_BLOCKS:
		queue_free()