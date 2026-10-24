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
	var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	var fur = Color(0.35, 0.20, 0.10, 1.0)
	var chest = Color(0.65, 0.45, 0.30, 1.0)
	var eye = Color(1.0, 1.0, 1.0, 1.0)
	for x in range(24):
		for y in range(24):
			if (y in range(4, 10) and x in range(7, 17)) or (y in range(10, 20) and x in range(4, 20)):
				img.set_pixel(x, y, fur)
			elif y in range(11, 17) and x in range(8, 16):
				img.set_pixel(x, y, chest)
			elif y in range(6, 8) and (x == 10 or x == 14):
				img.set_pixel(x, y, eye)
	return ImageTexture.create_from_image(img)

func _toss_barrel(scene: Node, pos: Vector2) -> void:
	var barrel = Area2D.new()
	barrel.name = "RollingBarrel"
	barrel.global_position = pos

	var spr = Sprite2D.new()
	spr.texture = load("res://assets/Equipment/bombs/big_bomb_sheet_red.png")
	spr.hframes = 4
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
			var tw = body.create_tween()
			tw.tween_interval(5.0)
			tw.tween_callback(func(): body.set_physics_process(true))
			barrel.queue_free()
	)

	scene.add_child(barrel)
	var b_tween = barrel.create_tween()
	b_tween.tween_property(barrel, "global_position:y", 600.0, 7.0)
	b_tween.tween_callback(barrel.queue_free)
