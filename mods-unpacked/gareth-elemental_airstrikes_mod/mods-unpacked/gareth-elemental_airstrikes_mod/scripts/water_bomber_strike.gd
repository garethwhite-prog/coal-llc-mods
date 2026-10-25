class_name WaterBomberStrike
extends Node2D

const Textures = preload("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/texture_factory.gd")
const BombScript = preload("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/airstrike_bomb.gd")

var damage: float = 120.0
var drop_rate: float = 0.05
var speed: float = 260.0
var t: float = 0.0
var sprite: Sprite2D
var player_ref: Node2D = null

func _ready() -> void:
	z_index = 60
	sprite = Sprite2D.new()
	sprite.texture = Textures.create_water_bomber_texture()
	sprite.scale = Vector2(2.0, 2.0)
	add_child(sprite)

	player_ref = get_tree().root.find_child("Player", true, false)
	if player_ref:
		global_position = Vector2(player_ref.global_position.x + 850.0, player_ref.global_position.y - 130.0)

func _process(delta: float) -> void:
	t += delta
	position.x -= delta * speed

	if t > drop_rate:
		_drop_water(global_position)
		t -= drop_rate

	if is_instance_valid(player_ref) and position.x < (player_ref.global_position.x - 900.0):
		queue_free()
	elif position.x < -1500.0:
		queue_free()

func _drop_water(pos: Vector2) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	var b = Node2D.new()
	b.set_script(BombScript)
	var tgt_y = pos.y + 450.0
	b.setup(pos, tgt_y, damage, 3, Textures.create_water_drop_texture())
	tree.current_scene.add_child(b)
