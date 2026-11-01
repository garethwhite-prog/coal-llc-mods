class_name ThomasTrainManager
extends Node2D

var left_stop: float = 64.0
var right_stop: float = 880.0
var speed: float = 140.0
var direction: float = 1.0

# Shop Exposed Configuration Variables
@export var loco_tier: int = 1
@export var wagon_count: int = 2
@export var wagon_capacity: float = 150.0

var current_haul: float = 0.0
var loco_sprite: Sprite2D
var wagons: Array[Sprite2D] = []

func _ready() -> void:
	z_index = 20
	position = Vector2(left_stop, 24.0)

	loco_sprite = Sprite2D.new()
	loco_sprite.texture = _generate_loco_texture(loco_tier)
	loco_sprite.scale = Vector2(1.8, 1.8)
	call_deferred("add_child", loco_sprite)
	
	for i in range(wagon_count):
		var wag = Sprite2D.new()
		wag.texture = _generate_wagon_texture()
		wag.scale = Vector2(1.8, 1.8)
		# Couple wagons linearly behind the locomotive
		wag.position = Vector2(-40.0 - (i * 36.0), 0.0)
		wagons.append(wag)
		call_deferred("add_child", wag)

func _generate_loco_texture(tier: int) -> ImageTexture:
	var img = Image.create(32, 16, false, Image.FORMAT_RGBA8)
	var color = Color.CORNFLOWER_BLUE # Thomas (1), Edward (2), Gordon (4)
	if tier == 3: color = Color.FOREST_GREEN # Henry
	img.fill(color)
	return ImageTexture.create_from_image(img)

func _generate_wagon_texture() -> ImageTexture:
	var img = Image.create(24, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color.SADDLE_BROWN)
	return ImageTexture.create_from_image(img)
