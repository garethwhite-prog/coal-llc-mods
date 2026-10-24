class_name DragonStrike
extends Node2D

var damage: float = 180.0
var bomb_rate: float = 0.05
var speed: float = 280.0
var t: float = 0.0

var sprite: Sprite2D

func _ready() -> void:
	z_index = 60
	sprite = Sprite2D.new()
	sprite.texture = ElementalAirstrikeTextures.create_dragon_texture()
	sprite.scale = Vector2(2.0, 2.0)
	add_child(sprite)

func _process(delta: float) -> void:
	var speed_mod: float = (1.0 + 2.0 * abs(sprite.position.x / 1000.0))
	t += delta
	sprite.position.x -= delta * speed * speed_mod

	if sprite.position.x > 0:
		sprite.rotation_degrees = -30
		sprite.position.y += delta * speed * speed_mod * 0.7
	else:
		sprite.rotation_degrees = 30
		sprite.position.y -= delta * speed * speed_mod * 0.7

	if t > bomb_rate:
		_drop_fireball(sprite.global_position)
		t -= bomb_rate

	if sprite.position.x < -1000:
		queue_free()

func _drop_fireball(pos: Vector2) -> void:
	var tree = get_tree()
	if not tree:
		return
	var tilemaps = tree.get_nodes_in_group("tilemap")
	if tilemaps.is_empty():
		return
	var tm = tilemaps[0]

	var mult: float = 1.0
	if Gvars and ("passives" in Gvars) and Gvars.passives:
		if "fire_damage" in Gvars.passives:
			mult += float(Gvars.passives.fire_damage)
		if "airstrike_damage" in Gvars.passives:
			mult += float(Gvars.passives.airstrike_damage)

	var center_cell = tm.local_to_map(tm.to_local(pos))
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			if dx*dx + dy*dy <= 4:
				var cell = center_cell + Vector2i(dx, dy)
				if tm.has_method("damageTileCoords"):
					tm.damageTileCoords(cell, (damage * 0.4) * mult)
				if tm.has_method("burn_tile"):
					tm.burn_tile(pos, damage * mult, 20)
				elif "fires" in tm and tm.fires and tm.fires.has_method("add_fire_tile"):
					tm.fires.add_fire_tile(cell, damage * mult, 20)
