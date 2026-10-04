extends Object

var punch_counter: int = 0

func attack_tile(chain: ModLoaderHookChain, count: float) -> void:
	chain.execute_next([count])
	var bg = chain.reference_object
	if not bg or not bg.tilemap:
		return

	var tree = bg.get_tree()
	if not tree:
		return
	var player = tree.get_first_node_in_group("player")
	if not player or not ("item_equipped" in player) or not player.item_equipped:
		return

	var item_id: String = player.item_equipped.itemID
	var player_tile: Vector2i = bg.tilemap.local_to_map(bg.global_position)
	var dir_vec: Vector2 = (bg.attack_direction.global_position - bg.global_position).normalized()
	var direction := Vector2i(round(dir_vec.x), round(dir_vec.y))
	if direction == Vector2i.ZERO:
		direction = Vector2i.RIGHT

	punch_counter += 1

	# MIKE TYSON EXPANSION
	if item_id == "boxing_gloves_mike_tyson":
		bg.attacks_per_second = 10.0
		var combo: int = punch_counter % 3
		if combo == 0:
			_berbick_left_hook(bg, player_tile, direction, count)
		elif combo == 1:
			_frazier_uppercut(bg, player_tile, direction, count)
		elif combo == 2:
			_spinks_uppercut(bg, player_tile, direction, count)
	elif item_id == "boxing_gloves_tyson_frazier":
		bg.attacks_per_second = 9.0
		_frazier_uppercut(bg, player_tile, direction, count)
	elif item_id == "boxing_gloves_tyson_berbick":
		bg.attacks_per_second = 8.0
		_berbick_left_hook(bg, player_tile, direction, count)
	elif item_id == "boxing_gloves_tyson_spinks":
		bg.attacks_per_second = 8.0
		_spinks_uppercut(bg, player_tile, direction, count)
	elif item_id == "boxing_gloves_chuck_norris":
		bg.attacks_per_second = 12.0
		for dist in range(1, 4):
			var target: Vector2i = player_tile + (direction * dist)
			if bg.tilemap.is_tile_breakable(target):
				bg.tilemap.damageTileCoords(target, bg.damage * 3.0 * count)
				bg.tilemap.sparks_manager.add_spark(bg.tilemap.map_to_local(target))
		if "kick_instance" in player and player.kick_instance:
			player.kick_instance.rotation_speed = 36.0

func _berbick_left_hook(bg: Node2D, pt: Vector2i, dir: Vector2i, count: float) -> void:
	var perp := Vector2i(-dir.y, dir.x)
	var targets := [
		pt + dir,
		pt + dir + perp,
		pt + dir - perp
	]
	for t in targets:
		if bg.tilemap.is_tile_breakable(t):
			bg.tilemap.damageTileCoords(t, bg.damage * 1.5 * count)
			bg.tilemap.sparks_manager.add_spark(bg.tilemap.map_to_local(t))

func _frazier_uppercut(bg: Node2D, pt: Vector2i, dir: Vector2i, count: float) -> void:
	var vert_dir := Vector2i.UP
	if dir.y > 0:
		vert_dir = Vector2i.DOWN
	for h in range(1, 4):
		var t: Vector2i = pt + (vert_dir * h)
		if bg.tilemap.is_tile_breakable(t):
			bg.tilemap.damageTileCoords(t, bg.damage * 2.0 * count)
			bg.tilemap.sparks_manager.add_spark(bg.tilemap.map_to_local(t))

func _spinks_uppercut(bg: Node2D, pt: Vector2i, dir: Vector2i, count: float) -> void:
	var target: Vector2i = pt + dir
	if bg.tilemap.is_tile_breakable(target):
		bg.tilemap.damageTileCoords(target, bg.damage * 10.0 * count)
		bg.tilemap.sparks_manager.add_spark(bg.tilemap.map_to_local(target))