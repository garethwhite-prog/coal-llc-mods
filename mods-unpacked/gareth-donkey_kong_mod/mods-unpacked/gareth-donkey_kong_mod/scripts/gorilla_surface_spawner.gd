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

	var torso = Sprite2D.new()
	torso.texture = load("res://assets/NPCs/PlayerSkins/Torsos/playerSheet_Torso_Brown.png")
	torso.hframes = 4
	torso.vframes = 4
	torso.frame = 0
	torso.scale = Vector2(2.2, 2.2)
	gorilla.add_child(torso)

	var head = Sprite2D.new()
	head.texture = load("res://assets/NPCs/PlayerSkins/Heads/playerSheet_Head_HelmetBrown.png")
	head.hframes = 4
	head.vframes = 4
	head.frame = 0
	head.scale = Vector2(2.2, 2.2)
	head.position = Vector2(0, -18)
	gorilla.add_child(head)

	scene.add_child(gorilla)

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
