class_name HeavyTurretEntity
extends Node2D

var fire_timer: float = 0.0
const FIRE_INTERVAL: float = 0.35
const DETECTION_RANGE: float = 350.0
const DAMAGE: float = 40.0

var sprite: Sprite2D
var tilemap: TileMapManager

func _ready() -> void:
	sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/Equipment/vehicles/tank_turret.png"):
		sprite.texture = load("res://assets/Equipment/vehicles/tank_turret.png")
	add_child(sprite)

func _physics_process(delta: float) -> void:
	fire_timer += delta
	if fire_timer >= FIRE_INTERVAL:
		fire_timer = 0.0
		_acquire_and_fire()

func _acquire_and_fire() -> void:
	if not tilemap and Game and Game.player:
		tilemap = Game.player.tilemap
	if not tilemap:
		return

	var center := tilemap.local_to_map(global_position)
	var best_target: Vector2i = Vector2i.ZERO
	var found: bool = false

	for r in range(1, 12):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var check_pos := center + Vector2i(dx, dy)
				if tilemap.is_tile_collision(check_pos):
					best_target = check_pos
					found = true
					break
			if found:
				break
		if found:
			break

	if found:
		var target_world := tilemap.map_to_local(best_target)
		sprite.rotation = (target_world - global_position).angle()
		tilemap.damage_tile(best_target, DAMAGE)