class_name DragonStrike
extends Node2D

const Textures = preload("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/texture_factory.gd")

var damage: float = 180.0
var bomb_rate: float = 0.06
var speed: float = 280.0
var t: float = 0.0
var sprite: Sprite2D
var start_x: float = 0.0

func _ready() -> void:
	z_index = 60
	sprite = Sprite2D.new()
	sprite.texture = Textures.create_dragon_texture()
	sprite.scale = Vector2(2.0, 2.0)
	add_child(sprite)

	var p = get_tree().root.find_child("Player", true, false)
	if p:
		global_position = Vector2(p.global_position.x + 850.0, p.global_position.y - 130.0)
		start_x = p.global_position.x

func _process(delta: float) -> void:
	t += delta
	position.x -= delta * speed
	position.y += sin(t * 4.0) * 1.5

	if t > bomb_rate:
		_drop_fireball(global_position)
		t -= bomb_rate

	var p = get_tree().root.find_child("Player", true, false)
	if p and position.x < (p.global_position.x - 900.0):
		queue_free()

func _drop_fireball(pos: Vector2) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	var b = Node2D.new()
	b.global_position = pos
	var spr = Sprite2D.new()
	spr.texture = Textures.create_fireball_texture()
	spr.scale = Vector2(1.5, 1.5)
	b.add_child(spr)
	tree.current_scene.add_child(b)

	var tw = b.create_tween()
	tw.parallel().tween_property(b, "global_position:y", pos.y + 450.0, 1.5)
	tw.tween_callback(func():
		var tm = tree.root.find_child("TileMapManager", true, false)
		if tm:
			var m_pos = tm.local_to_map(b.global_position)
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					tm.damageTileCoords(Vector2i(m_pos.x + dx, m_pos.y + dy), damage)
		b.queue_free()
	)
