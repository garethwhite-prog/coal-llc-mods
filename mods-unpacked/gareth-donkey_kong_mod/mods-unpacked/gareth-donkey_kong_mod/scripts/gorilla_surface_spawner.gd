extends Node

var gorilla: Node2D
var barrel_timer: float = 0.0

func _process(delta: float) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return

	var p = tree.root.find_child("Player", true, false)
	var in_mine = is_instance_valid(p) and is_instance_valid(tree.root.find_child("TileMapManager", true, false))

	if in_mine and not is_instance_valid(gorilla):
		_spawn_gorilla(tree.current_scene)

	if is_instance_valid(gorilla):
		# Patrol on right plateau (X = 360 to 620), safely away from surface pit
		gorilla.position.x += 50.0 * delta * gorilla.get_meta("dir", 1.0)
		if gorilla.position.x > 620.0:
			gorilla.set_meta("dir", -1.0)
			gorilla.scale.x = abs(gorilla.scale.x)
		elif gorilla.position.x < 360.0:
			gorilla.set_meta("dir", 1.0)
			gorilla.scale.x = -abs(gorilla.scale.x)

		barrel_timer += delta
		if barrel_timer >= 6.0:
			barrel_timer = 0.0
			_toss_barrel(tree.current_scene, gorilla.global_position)

func _spawn_gorilla(scene: Node) -> void:
	gorilla = Node2D.new()
	gorilla.name = "DonkeyKongGorilla"
	# Spawn on far-right surface plateau, leaving mine entrance wide open
	gorilla.global_position = Vector2(420, -32)
	gorilla.set_meta("dir", 1.0)

	var spr = Sprite2D.new()
	spr.texture = _create_gorilla_texture()
	spr.scale = Vector2(1.8, 1.8)
	gorilla.add_child(spr)
	scene.add_child(gorilla)

func _create_gorilla_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var fur = Color(0.28, 0.14, 0.06, 1.0)
	var chest = Color(0.70, 0.50, 0.32, 1.0)
	var tie = Color(0.95, 0.15, 0.15, 1.0)
	var eye = Color(1.0, 1.0, 1.0, 1.0)
	var pupil = Color(0.05, 0.05, 0.05, 1.0)

	for x in range(32):
		for y in range(32):
			# Head
			if y in range(4, 12) and x in range(10, 22):
				img.set_pixel(x, y, fur)
			# Broad ape torso
			elif y in range(12, 28) and x in range(7, 25):
				img.set_pixel(x, y, fur)
			# Arms
			elif y in range(13, 29) and (x in range(3, 8) or x in range(24, 29)):
				img.set_pixel(x, y, fur)
			# Chest plate & muzzle
			if (y in range(8, 12) and x in range(12, 20)) or (y in range(14, 22) and x in range(11, 21)):
				img.set_pixel(x, y, chest)
			# Red tie
			if (y in range(13, 24) and x in range(15, 17)) or (y in range(22, 26) and x in range(14, 18)):
				img.set_pixel(x, y, tie)
			# Eyes
			if y in range(6, 8) and (x == 13 or x == 18):
				img.set_pixel(x, y, eye)
			if y == 7 and (x == 14 or x == 19):
				img.set_pixel(x, y, pupil)

	return ImageTexture.create_from_image(img)

func _create_barrel_texture() -> ImageTexture:
	var img = Image.create(20, 20, false, Image.FORMAT_RGBA8)
	var wood_dark = Color(0.42, 0.24, 0.10, 1.0)
	var wood_light = Color(0.58, 0.36, 0.18, 1.0)
	var metal_band = Color(0.24, 0.24, 0.26, 1.0)

	for x in range(20):
		for y in range(20):
			var dx = float(x - 10)
			var dy = float(y - 10)
			if dx*dx + dy*dy <= 85.0:
				if y in range(4, 7) or y in range(13, 16):
					img.set_pixel(x, y, metal_band)
				elif x % 3 == 0:
					img.set_pixel(x, y, wood_dark)
				else:
					img.set_pixel(x, y, wood_light)

	return ImageTexture.create_from_image(img)

func _toss_barrel(scene: Node, pos: Vector2) -> void:
	var barrel = Area2D.new()
	barrel.name = "RollingBarrel"
	barrel.global_position = pos

	var spr = Sprite2D.new()
	spr.texture = _create_barrel_texture()
	spr.scale = Vector2(1.7, 1.7)
	barrel.add_child(spr)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 15.0
	col.shape = shape
	barrel.add_child(col)

	barrel.body_entered.connect(func(body):
		if body.is_in_group("player") or body.name == "Player":
			if "velocity" in body:
				body.velocity = Vector2.ZERO
			body.set_physics_process(false)

			var toast = Label.new()
			toast.text = "★ BONK! STUNNED! ★"
			toast.modulate = Color(1.0, 0.85, 0.2)
			toast.position = Vector2(-60, -40)
			body.add_child(toast)

			var tw = body.create_tween()
			tw.tween_interval(3.0)
			tw.tween_callback(func():
				body.set_physics_process(true)
				toast.queue_free()
			)
			barrel.queue_free()
	)

	scene.add_child(barrel)
	var b_tween = barrel.create_tween()
	b_tween.parallel().tween_property(barrel, "global_position:x", 180.0, 4.0)
	b_tween.parallel().tween_property(barrel, "global_position:y", 650.0, 6.0)
	b_tween.parallel().tween_property(barrel, "rotation", 14.0, 6.0)
	b_tween.tween_callback(barrel.queue_free)
