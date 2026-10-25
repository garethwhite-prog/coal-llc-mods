class_name WaterBomberStrike
extends Node2D

const Textures = preload("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/texture_factory.gd")

var damage: float = 120.0
var drop_rate: float = 0.04
var speed: float = 260.0
var t: float = 0.0

var sprite: Sprite2D

func _ready() -> void:
	z_index = 60
	sprite = Sprite2D.new()
	sprite.texture = Textures.create_water_bomber_texture()
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
	if not tree or not tree.current_scene:
		return
	var b = Node2D.new()
	b.global_position = pos
	var spr = Sprite2D.new()
	spr.texture = Textures.create_water_drop_texture()
	spr.scale = Vector2(1.5, 1.5)
	b.add_child(spr)
	tree.current_scene.add_child(b)

	var tw = b.create_tween()
	tw.parallel().tween_property(b, "global_position:y", pos.y + 600.0, 2.0)
	tw.tween_callback(func():
		var tm = tree.root.find_child("TileMapManager", true, false)
		if tm:
			var m_pos = tm.local_to_map(b.global_position)
			for dx in range(-3, 4):
				for dy in range(-3, 4):
					tm.damageTileCoords(Vector2i(m_pos.x + dx, m_pos.y + dy), damage)
		b.queue_free()
	)
