class_name AirstrikeBomb
extends Node2D

var target_y: float = 0.0
var damage: float = 180.0
var radius: int = 2
var fall_speed: float = 340.0

func setup(pos: Vector2, tgt_y: float, dmg: float, rad: int, tex: Texture2D) -> void:
	global_position = pos
	target_y = tgt_y
	damage = dmg
	radius = rad

	var spr = Sprite2D.new()
	spr.texture = tex
	spr.scale = Vector2(1.5, 1.5)
	add_child(spr)

func _process(delta: float) -> void:
	position.y += fall_speed * delta
	if position.y >= target_y:
		_detonate()

func _detonate() -> void:
	var tree = get_tree()
	if tree and tree.root:
		var tm = tree.root.find_child("TileMapManager", true, false)
		if tm and tm.has_method("damageTileCoords"):
			var m_pos = tm.local_to_map(global_position)
			for dx in range(-radius, radius + 1):
				for dy in range(-radius, radius + 1):
					tm.damageTileCoords(Vector2i(m_pos.x + dx, m_pos.y + dy), float(damage))
	queue_free()
