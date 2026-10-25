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
		gorilla.position.x += 60.0 * delta * gorilla.get_meta("dir", 1.0)
		if abs(gorilla.position.x) > 350.0:
			gorilla.set_meta("dir", -gorilla.get_meta("dir", 1.0))
			gorilla.scale.x = -abs(gorilla.scale.x) if gorilla.get_meta("dir", 1.0) > 0 else abs(gorilla.scale.x)

		barrel_timer += delta
		if barrel_timer >= 6.0:
			barrel_timer = 0.0
			_toss_barrel(tree.current_scene, gorilla.global_position)

func _spawn_gorilla(scene: Node) -> void:
	gorilla = Node2D.new()
	gorilla.name = "DonkeyKongGorilla"
	gorilla.global_position = Vector2(180, -28)
	gorilla.set_meta("dir", -1.0)

	var spr = Sprite2D.new()
	spr.texture = _create_gorilla_texture()
	spr.scale = Vector2(2.5, 2.5)
	gorilla.add_child(spr)
	scene.add_child(gorilla)

func _create_gorilla_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var fur = Color(0.35, 0.18, 0.08, 1.0)
	var tan_skin = Color(0.72, 0.52, 0.35, 1.0)
	var tie_red = Color(0.9, 0.15, 0.15, 1.0)
	var eye = Color(1.0, 1.0, 1.0, 1.0)

	for x in range(32):
		for y in range(32):
			# Broad gorilla torso and massive ape arms
			if (y in range(12, 28) and x in range(6, 26)) or (y in range(14, 30) and (x in range(2, 8) or x in range(24, 30))):
				img.set_pixel(x, y, fur)
			# Gorilla head and brow ridge
			elif (y in range(4, 13) and x in range(10, 22)):
				img.set_pixel(x, y, fur)
			# Tan muzzle and chest plate
			elif (y in range(9, 13) and x in range(12, 20)) or (y in range(15, 24) and x in range(11, 21)):
				img.set_pixel(x, y, tan_skin)
			# Classic DK Red Tie
			elif (y in range(15, 25) and (x in range(15, 17) or (y in range(22, 25) and x in range(14, 18)))):
				img.set_pixel(x, y, tie_red)
			# Eyes
			elif (y in range(7, 9) and (x == 13 or x == 18)):
				img.set_pixel(x, y, eye)

	return ImageTexture.create_from_image(img)

func _create_barrel_texture() -> ImageTexture:
	var img = Image.create(20, 20, false, Image.FORMAT_RGBA8)
	var wood_dark = Color(0.45, 0.26, 0.12, 1.0)
	var wood_light = Color(0.60, 0.38, 0.20, 1.0)
	var hoop_metal = Color(0.25, 0.25, 0.28, 1.0)

	for x in range(20):
		for y in range(20):
			var dx = float(x - 10)
			var dy = float(y - 10)
			if dx*dx + dy*dy <= 90.0:
				if y in range(4, 7) or y in range(13, 16):
					img.set_pixel(x, y, hoop_metal)
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
	spr.scale = Vector2(1.8, 1.8)
	barrel.add_child(spr)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16.0
	col.shape = shape
	barrel.add_child(col)

	barrel.body_entered.connect(func(body):
		if body.is_in_group("player") or body.name == "Player":
			if "velocity" in body:
				body.velocity = Vector2.ZERO
			body.set_physics_process(false)

			# Bonk Sound and Dizzy Notification
			var bonk = AudioStreamPlayer2D.new()
			bonk.stream = load("res://assets/sound/sound effects/box_1.wav")
			bonk.pitch_scale = 1.3
			bonk.global_position = body.global_position
			body.add_child(bonk)
			bonk.play()

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
				bonk.queue_free()
			)
			barrel.queue_free()
	)

	scene.add_child(barrel)

	# Roll barrel down and rotate
	var b_tween = barrel.create_tween()
	b_tween.parallel().tween_property(barrel, "global_position:y", 650.0, 7.0)
	b_tween.parallel().tween_property(barrel, "rotation", 14.0, 7.0)
	b_tween.tween_callback(barrel.queue_free)
