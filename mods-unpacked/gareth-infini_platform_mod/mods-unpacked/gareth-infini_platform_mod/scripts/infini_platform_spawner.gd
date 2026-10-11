class_name InfiniPlatformSpawner
extends Node2D

@export var tilemap: TileMapManager

var origin_tile: Vector2i

var current_left: Vector2i
var current_right: Vector2i
var current_up: Vector2i
var current_down: Vector2i

var left_live: bool = true
var right_live: bool = true
var up_live: bool = true
var down_live: bool = true

var blocks_placed: int = 0
const MAX_BLOCKS_PER_DIR: int = 250
var t: int = 0
var audio_player: AudioStreamPlayer2D

func _ready() -> void:
	origin_tile = tilemap.local_to_map(global_position)
	current_left = origin_tile + Vector2i(-1, 0)
	current_right = origin_tile + Vector2i(1, 0)
	current_up = origin_tile + Vector2i(0, -1)
	current_down = origin_tile + Vector2i(0, 1)

	# Place Intersection Platform-Ladder at origin
	tilemap.change_tile(origin_tile, TileMapChunk.Tiles.PLATFORMLADDER)

	audio_player = AudioStreamPlayer2D.new()
	audio_player.stream = load("res://assets/sound/sound effects/pickup.wav")
	add_child(audio_player)
	audio_player.play()

func _physics_process(_delta: float) -> void:
	t += 1
	var any_active: bool = false

	# 1. HORIZONTAL EXPANSION (PLATFORMS)
	if left_live:
		any_active = true
		if tilemap.is_tile_collision(current_left) or not tilemap.does_tile_chunk_exist(current_left) or blocks_placed >= MAX_BLOCKS_PER_DIR * 4:
			left_live = false
		else:
			var existing = tilemap.get_tile_enum(current_left)
			if existing == TileMapChunk.Tiles.LADDER or existing == TileMapChunk.Tiles.PLATFORMLADDER:
				tilemap.change_tile(current_left, TileMapChunk.Tiles.PLATFORMLADDER)
			else:
				tilemap.change_tile(current_left, TileMapChunk.Tiles.PLATFORM)
			current_left += Vector2i(-1, 0)
			blocks_placed += 1

	if right_live:
		any_active = true
		if tilemap.is_tile_collision(current_right) or not tilemap.does_tile_chunk_exist(current_right) or blocks_placed >= MAX_BLOCKS_PER_DIR * 4:
			right_live = false
		else:
			var existing = tilemap.get_tile_enum(current_right)
			if existing == TileMapChunk.Tiles.LADDER or existing == TileMapChunk.Tiles.PLATFORMLADDER:
				tilemap.change_tile(current_right, TileMapChunk.Tiles.PLATFORMLADDER)
			else:
				tilemap.change_tile(current_right, TileMapChunk.Tiles.PLATFORM)
			current_right += Vector2i(1, 0)
			blocks_placed += 1

	# 2. VERTICAL EXPANSION (LADDERS)
	if up_live:
		any_active = true
		if tilemap.is_tile_collision(current_up) or not tilemap.does_tile_chunk_exist(current_up) or blocks_placed >= MAX_BLOCKS_PER_DIR * 4:
			up_live = false
		else:
			var existing = tilemap.get_tile_enum(current_up)
			if existing == TileMapChunk.Tiles.PLATFORM or existing == TileMapChunk.Tiles.PLATFORMLADDER:
				tilemap.change_tile(current_up, TileMapChunk.Tiles.PLATFORMLADDER)
			else:
				tilemap.change_tile(current_up, TileMapChunk.Tiles.LADDER)
			current_up += Vector2i(0, -1)
			blocks_placed += 1

	if down_live:
		any_active = true
		if tilemap.is_tile_collision(current_down) or not tilemap.does_tile_chunk_exist(current_down) or blocks_placed >= MAX_BLOCKS_PER_DIR * 4:
			down_live = false
		else:
			var existing = tilemap.get_tile_enum(current_down)
			if existing == TileMapChunk.Tiles.PLATFORM or existing == TileMapChunk.Tiles.PLATFORMLADDER:
				tilemap.change_tile(current_down, TileMapChunk.Tiles.PLATFORMLADDER)
			else:
				tilemap.change_tile(current_down, TileMapChunk.Tiles.LADDER)
			current_down += Vector2i(0, 1)
			blocks_placed += 1

	if t % 4 == 0 and any_active:
		audio_player.play()

	if not any_active:
		set_physics_process(false)