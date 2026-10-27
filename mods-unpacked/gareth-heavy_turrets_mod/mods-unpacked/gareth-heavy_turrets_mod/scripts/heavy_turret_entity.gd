class_name HeavyTurretEntity
extends Node2D

var fire_timer: float = 0.0
const FIRE_INTERVAL: float = 0.35
const DAMAGE: float = 40.0

var sprite: Sprite2D
var tilemap = null

func _ready() -> void:
	sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/Equipment/vehicles/tank_turret.png"):
		sprite.texture = load("res://assets/Equipment/vehicles/tank_turret.png")
	add_child(sprite)
	_resolve_tilemap()

func _resolve_tilemap() -> void:
	var tree = get_tree()
	if tree and tree.root:
		var p = tree.root.find_child("Player", true, false)
		if p and ("tilemap" in p) and p.tilemap:
			tilemap = p.tilemap
			return
		var tm = tree.root.find_child("TileMapManager", true, false)
		if tm:
			tilemap = tm

func _physics_process(delta: float) -> void:
	fire_timer += delta
	if fire_timer >= FIRE_INTERVAL:
		fire_timer = 0.0
		_acquire_and_fire()

func _acquire_and_fire() -> void:
	if not tilemap:
		_resolve_tilemap()
		if not tilemap:
			return

	var center: Vector2i = tilemap.local_to_map(global_position)
	var best_target: Vector2i = Vector2i.ZERO
	var found: bool = false

	for r in range(1, 14):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var check_pos: Vector2i = center + Vector2i(dx, dy)
				if tilemap.has_method("is_tile_collision") and tilemap.is_tile_collision(check_pos):
					best_target = check_pos
					found = true
					break
			if found:
				break
		if found:
			break

	if found:
		var target_world: Vector2 = tilemap.map_to_local(best_target)
		sprite.rotation = (target_world - global_position).angle()
		if tilemap.has_method("damageTileCoords"):
			tilemap.damageTileCoords(best_target, DAMAGE)

		var boom = AudioStreamPlayer2D.new()
		boom.stream = load("res://assets/sound/sound effects/box_1.wav")
		boom.pitch_scale = 1.4
		boom.global_position = global_position
		get_tree().current_scene.add_child(boom)
		boom.play()
		boom.finished.connect(boom.queue_free)

