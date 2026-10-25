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
		gorilla.position.x += 45.0 * delta * gorilla.get_meta("dir", 1.0)
		if gorilla.position.x > 600.0:
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
	gorilla.global_position = Vector2(460, -32)
	gorilla.set_meta("dir", 1.0)

	var spr = Sprite2D.new()
	spr.texture = _create_gorilla_texture()
	spr.scale = Vector2(1.6, 1.6)
	gorilla.add_child(spr)
	scene.add_child(gorilla)

func _create_gorilla_texture() -> ImageTexture:
	var img = Image.create(36, 36, false, Image.FORMAT_RGBA8)
	var fur_dark = Color(0.22, 0.11, 0.04, 1.0)
	var fur_mid  = Color(0.36, 0.18, 0.08, 1.0)
	var chest    = Color(0.74, 0.52, 0.34, 1.0)
	var tie_red  = Color(0.95, 0.15, 0.15, 1.0)
	var tie_gold = Color(1.0, 0.85, 0.20, 1.0)
	var eye_w    = Color(1.0, 1.0, 1.0, 1.0)
	var eye_b    = Color(0.05, 0.05, 0.05, 1.0)

	for x in range(36):
		for y in range(36):
			if y in range(4, 13) and x in range(11, 25):
				img.set_pixel(x, y, fur_mid if y < 9 else fur_dark)
			elif (y in range(13, 30) and x in range(8, 28)) or (y in range(14, 32) and (x in range(3, 9) or x in range(27, 33))):
				img.set_pixel(x, y, fur_mid if x % 2 == 0 else fur_dark)
			if (y in range(9, 13) and x in range(13, 23)) or (y in range(15, 24) and x in range(12, 24)):
				img.set_pixel(x, y, chest)
			if (y in range(15, 26) and x in range(16, 20)):
				img.set_pixel(x, y, tie_red)
			if (y == 20 or y == 21) and (x == 17 or x == 18):
				img.set_pixel(x, y, tie_gold)
			if y in range(7, 9) and (x == 14 or x == 20):
				img.set_pixel(x, y, eye_w)
			if y == 8 and (x == 15 or x == 21):
				img.set_pixel(x, y, eye_b)

	return ImageTexture.create_from_image(img)

func _create_barrel_texture() -> ImageTexture:
	var img = Image.create(22, 22, false, Image.FORMAT_RGBA8)
	var w_dark  = Color(0.40, 0.22, 0.10, 1.0)
	var w_light = Color(0.58, 0.36, 0.18, 1.0)
	var metal   = Color(0.24, 0.24, 0.26, 1.0)

	for x in range(22):
		for y in range(22):
			var dx = float(x - 11)
			var dy = float(y - 11)
			if dx*dx + dy*dy <= 105.0:
				if y in range(4, 7) or y in range(15, 18):
					img.set_pixel(x, y, metal)
				elif x % 3 == 0:
					img.set_pixel(x, y, w_dark)
				else:
					img.set_pixel(x, y, w_light)

	return ImageTexture.create_from_image(img)

func _toss_barrel(scene: Node, pos: Vector2) -> void:
	var barrel = Area2D.new()
	barrel.name = "RollingBarrel"
	barrel.global_position = pos
	barrel.collision_layer = 0
	barrel.collision_mask = 0xFFFFFFFF

	var spr = Sprite2D.new()
	spr.texture = _create_barrel_texture()
	spr.scale = Vector2(1.7, 1.7)
	barrel.add_child(spr)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16.0
	col.shape = shape
	barrel.add_child(col)

	var on_hit = func(target: Node):
		var p_node = target if (target.name == "Player" or target.is_in_group("player")) else target.get_parent()
		if p_node and (p_node.name == "Player" or p_node.is_in_group("player")):
			if "velocity" in p_node:
				p_node.velocity = Vector2.ZERO
			if "able_to_mine" in p_node:
				p_node.able_to_mine = false
			if p_node.has_node("StateMachine"):
				p_node.get_node("StateMachine").set_physics_process(false)

			var toast = Label.new()
			toast.text = "★ BONK! STUNNED! ★"
			toast.modulate = Color(1.0, 0.85, 0.2)
			toast.position = Vector2(-60, -40)
			p_node.add_child(toast)

			var bonk = AudioStreamPlayer2D.new()
			bonk.stream = load("res://assets/sound/sound effects/box_1.wav")
			bonk.pitch_scale = 1.3
			p_node.add_child(bonk)
			bonk.play()

			var tw = p_node.create_tween()
			tw.tween_interval(2.5)
			tw.tween_callback(func():
				if is_instance_valid(p_node):
					if "able_to_mine" in p_node:
						p_node.able_to_mine = true
					if p_node.has_node("StateMachine"):
						p_node.get_node("StateMachine").set_physics_process(true)
				toast.queue_free()
				bonk.queue_free()
			)
			barrel.queue_free()

	barrel.body_entered.connect(on_hit)
	barrel.area_entered.connect(on_hit)

	scene.add_child(barrel)
	var b_tween = barrel.create_tween()
	b_tween.parallel().tween_property(barrel, "global_position:x", 160.0, 4.0)
	b_tween.parallel().tween_property(barrel, "global_position:y", 680.0, 6.0)
	b_tween.parallel().tween_property(barrel, "rotation", 14.0, 6.0)
	b_tween.tween_callback(barrel.queue_free)
