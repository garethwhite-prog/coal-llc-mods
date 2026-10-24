class_name AgentOrangeStrike
extends Node2D

var damage: float = 150.0
var spray_rate: float = 0.05
var speed: float = 240.0
var t: float = 0.0

var sprite: Sprite2D

func _ready() -> void:
	z_index = 60
	sprite = Sprite2D.new()
	sprite.texture = ElementalAirstrikeTextures.create_agent_orange_texture()
	sprite.scale = Vector2(2.2, 2.2)
	add_child(sprite)

func _process(delta: float) -> void:
	var speed_mod: float = (1.0 + 2.0 * abs(sprite.position.x / 1000.0))
	t += delta
	sprite.position.x -= delta * speed * speed_mod

	if sprite.position.x > 0:
		sprite.rotation_degrees = -15
		sprite.position.y += delta * speed * speed_mod * 0.4
	else:
		sprite.rotation_degrees = 15
		sprite.position.y -= delta * speed * speed_mod * 0.4

	if t > spray_rate:
		_spray_poison(sprite.global_position)
		t -= spray_rate

	if sprite.position.x < -1000:
		queue_free()

func _spray_poison(pos: Vector2) -> void:
	var tree = get_tree()
	if not tree:
		return
	var tilemaps = tree.get_nodes_in_group("tilemap")
	if tilemaps.is_empty():
		return
	var tm = tilemaps[0]

	var mult: float = 1.0
	if Gvars and ("passives" in Gvars) and Gvars.passives:
		if "poison_damage" in Gvars.passives:
			mult += float(Gvars.passives.poison_damage)
		if "airstrike_damage" in Gvars.passives:
			mult += float(Gvars.passives.airstrike_damage)

	var center_cell = tm.local_to_map(tm.to_local(pos))
	for dx in range(-3, 4):
		for dy in range(-2, 3):
			if dx*dx + dy*dy <= 6:
				var cell = center_cell + Vector2i(dx, dy)
				if tm.has_method("poison_tile_coords"):
					tm.poison_tile_coords(cell, damage * mult, 30)
				elif tm.has_method("poison_tile"):
					tm.poison_tile(pos, damage * mult, 30)
				elif "poisons" in tm and tm.poisons and tm.poisons.has_method("add_poison_tile"):
					tm.poisons.add_poison_tile(cell, damage * mult, 30)
				if tm.has_method("damageTileCoords"):
					tm.damageTileCoords(cell, 20.0 * mult)
