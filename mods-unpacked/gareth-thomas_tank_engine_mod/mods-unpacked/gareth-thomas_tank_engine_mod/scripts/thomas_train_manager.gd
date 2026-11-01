class_name ThomasTrainManager
extends Node2D

var left_stop: float = 64.0
var right_stop: float = 880.0
var speed: float = 140.0
var direction: float = 1.0

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
		wag.position = Vector2(-40.0 - (i * 36.0), 0.0)
		wagons.append(wag)
		call_deferred("add_child", wag)

func _physics_process(delta: float) -> void:
	# Locomotive Upgrade logic: Speed scales with tier (140 -> 260)
	var current_speed = speed + (loco_tier * 40.0)
	position.x += current_speed * direction * delta
	
	if position.x >= right_stop:
		direction = -1.0
		loco_sprite.flip_h = true
	elif position.x <= left_stop:
		direction = 1.0
		loco_sprite.flip_h = false
		_unload_haul()
		
func _unload_haul() -> void:
	if current_haul > 0.0:
		if Gvars and ("cash" in Gvars):
			Gvars.cash += current_haul
		current_haul = 0.0

func _generate_loco_texture(tier: int) -> ImageTexture:
	var img = Image.create(32, 16, false, Image.FORMAT_RGBA8)
	var color = Color.CORNFLOWER_BLUE # Thomas
	if tier == 2: color = Color.STEEL_BLUE # Edward
	elif tier == 3: color = Color.FOREST_GREEN # Henry
	elif tier >= 4: color = Color.ROYAL_BLUE # Gordon
	img.fill(color)
	return ImageTexture.create_from_image(img)

func _generate_wagon_texture() -> ImageTexture:
	var img = Image.create(24, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color.SADDLE_BROWN)
	return ImageTexture.create_from_image(img)
