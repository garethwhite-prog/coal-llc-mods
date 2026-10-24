class_name WaterBomberStrike
extends Node2D

var damage: float = 120.0
var drop_rate: float = 0.04
var speed: float = 260.0
var t: float = 0.0

var sprite: Sprite2D

func _ready() -> void:
	z_index = 60
	sprite = Sprite2D.new()
	sprite.texture = ElementalAirstrikeTextures.create_water_bomber_texture()
	sprite.scale = Vector2(2.0, 2.0)
	add_child(sprite)

func _process(delta: float) -> void:
	var speed_mod: float = (1.0 + 2.0 * abs(sprite.position.x / 1000.0))
	t += delta
	sprite.position.x -= delta * speed * speed_mod

	if sprite.position.x > 0:
		sprite.rotation_degrees = -25
		sprite.position.y += delta * speed * speed_mod * 0.5
	else:
		sprite.rotation_degrees = 25
		sprite.position.y -= delta * speed * speed_mod * 0.5

	if t > drop_rate:
		_drop_water(sprite.global_position)
		t -= drop_rate

	if sprite.position.x < -1000:
		queue_free()

func _drop_water(pos: Vector2) -> void:
	var tree = get_tree()
	if not tree:
		return
	var tilemaps = tree.get_nodes_in_group("tilemap")
	if tilemaps.is_empty():
		return
	var tm = tilemaps[0]

	var mult: float = 1.0
	if Gvars and ("passives" in Gvars) and Gvars.passives:
		if "wet_damage" in Gvars.passives:
			mult += float(Gvars.passives.wet_damage)
		if "airstrike_damage" in Gvars.passives:
			mult += float(Gvars.passives.airstrike_damage)

	var center_cell = tm.local_to_map(tm.to_local(pos))
	for dx in range(-3, 4):
		for dy in range(-2, 3):
			if dx*dx + dy*dy <= 7:
				var cell = center_cell + Vector2i(dx, dy)
				if tm.has_method("wet_tile_coords"):
					tm.wet_tile_coords(cell)
				elif tm.has_method("wet_tile"):
					tm.wet_tile(pos)
				if tm.has_method("damageTileCoords"):
					tm.damageTileCoords(cell, 35.0 * mult)
