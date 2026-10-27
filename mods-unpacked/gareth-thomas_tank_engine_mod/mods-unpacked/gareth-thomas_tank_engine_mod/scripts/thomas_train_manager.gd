class_name ThomasTrainManager
extends Node2D

var left_stop: float = 64.0
var right_stop: float = 880.0
var speed: float = 140.0
var direction: float = 1.0

var loco_tier: int = 1 # 1: Thomas, 2: Edward, 3: Henry, 4: Gordon
var wagon_count: int = 2
var wagon_capacity: float = 150.0
var current_haul: float = 0.0

var loco_sprite: Sprite2D
var wagons: Array[Sprite2D] = []

func _ready() -> void:
	z_index = 20
	position = Vector2(left_stop, 24.0)

	loco_sprite = Sprite2D.new()
	loco_sprite.texture = _generate_loco_texture(loco_tier)
	loco_sprite.scale = Vector2(1.8, 1.8)
	add_child(loco_sprite)

func _process(delta: float) -> void:
	position.x += direction * speed * delta

	# Physical buffer stops at cavern edges
	if position.x >= right_stop:
		position.x = right_stop
		direction = -1.0
		loco_sprite.scale.x = -abs(loco_sprite.scale.x)
	elif position.x <= left_stop:
		position.x = left_stop
		direction = 1.0
		loco_sprite.scale.x = abs(loco_sprite.scale.x)
		_unload_at_stockpile()

	_sweep_dropped_ore()

func _sweep_dropped_ore() -> void:
	var tree = get_tree()
	if not tree or not tree.root: return
	var ld = tree.root.find_child("LootDrops", true, false)
	if not ld or not ("loot_drops" in ld): return

	for drop in ld.loot_drops.get_children():
		if is_instance_valid(drop) and drop.global_position.distance_to(global_position) < 48.0:
			if current_haul < (wagon_count * wagon_capacity):
				current_haul += 1.0
				drop.queue_free()

func _unload_at_stockpile() -> void:
	if current_haul > 0.0 and Gvars:
		Gvars.CashCount += current_haul * 2.0
		current_haul = 0.0

func _generate_loco_texture(tier: int) -> ImageTexture:
	var img = Image.create(36, 24, false, Image.FORMAT_RGBA8)
	var body_color = Color(0.15, 0.45, 0.90, 1.0) # Thomas blue
	if tier == 2: body_color = Color(0.20, 0.60, 0.95, 1.0) # Edward
	elif tier == 3: body_color = Color(0.15, 0.70, 0.25, 1.0) # Henry Green
	elif tier == 4: body_color = Color(0.10, 0.35, 0.85, 1.0) # Gordon Express

	var boiler = Color(0.12, 0.12, 0.14, 1.0)
	var red = Color(0.90, 0.15, 0.15, 1.0)
	var face = Color(0.85, 0.85, 0.88, 1.0)

	for x in range(36):
		for y in range(24):
			# Boiler and Cab
			if (y in range(8, 18) and x in range(6, 26)) or (y in range(4, 18) and x in range(4, 12)):
				img.set_pixel(x, y, body_color)
			# Smokebox and Funnel
			if (y in range(7, 18) and x in range(25, 32)) or (y in range(2, 7) and x in range(27, 30)):
				img.set_pixel(x, y, boiler)
			# Face on front of smokebox
			if y in range(9, 16) and x in range(30, 34):
				img.set_pixel(x, y, face)
			# Red Buffer Beam
			if y in range(16, 20) and (x in range(2, 6) or x in range(31, 35)):
				img.set_pixel(x, y, red)
	return ImageTexture.create_from_image(img)
