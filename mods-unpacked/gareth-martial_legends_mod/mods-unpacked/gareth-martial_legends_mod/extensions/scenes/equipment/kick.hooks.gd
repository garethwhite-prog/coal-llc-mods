extends Object

func _process(chain: ModLoaderHookChain, delta: float) -> void:
	var kick = chain.reference_object
	if kick:
		var tree = kick.get_tree()
		if tree:
			var player = tree.get_first_node_in_group("player")
			if player and ("item_equipped" in player) and player.item_equipped:
				var item_id: String = player.item_equipped.itemID
				if item_id.begins_with("kick_jcvd"):
					kick.rotation_speed = 32.0
				elif item_id.begins_with("kick_chuck_norris"):
					kick.rotation_speed = 40.0
					if "boxing_gloves_instance" in player and player.boxing_gloves_instance:
						player.boxing_gloves_instance.attacks_per_second = 15.0
	chain.execute_next([delta])

func damage_tiles(chain: ModLoaderHookChain, damage_idxes: Array[int]) -> void:
	chain.execute_next([damage_idxes])
	var kick = chain.reference_object
	if not kick or not kick.tilemap:
		return

	var tree = kick.get_tree()
	if not tree:
		return
	var player = tree.get_first_node_in_group("player")
	if not player or not ("item_equipped" in player) or not player.item_equipped:
		return

	var item_id: String = player.item_equipped.itemID
	var centre_tile: Vector2i = kick.tilemap.local_to_map(kick.global_position)

	# JCVD: The Epic Split
	if item_id == "kick_jcvd_epic_split":
		for dist in range(1, 5):
			var left_tile: Vector2i = centre_tile + Vector2i(-dist, 0)
			var right_tile: Vector2i = centre_tile + Vector2i(dist, 0)
			if kick.tilemap.is_tile_breakable(left_tile):
				kick.tilemap.damageTileCoords(left_tile, kick.damage * 1.5)
				kick.tilemap.sparks_manager.add_spark(kick.tilemap.map_to_local(left_tile))
			if kick.tilemap.is_tile_breakable(right_tile):
				kick.tilemap.damageTileCoords(right_tile, kick.damage * 1.5)
				kick.tilemap.sparks_manager.add_spark(kick.tilemap.map_to_local(right_tile))

	# JCVD: Helicopter Split-Kick
	elif item_id == "kick_jcvd_helicopter":
		for x in range(-5, 6):
			for y in range(-5, 6):
				if abs(x) == 5 or abs(y) == 5 or (abs(x) == 4 and abs(y) == 4):
					var outer_tile: Vector2i = centre_tile + Vector2i(x, y)
					if kick.tilemap.is_tile_breakable(outer_tile):
						kick.tilemap.damageTileCoords(outer_tile, kick.damage * 1.0)

	# Chuck Norris: Roundhouse Kick (8-tile shockwave)
	elif item_id == "kick_chuck_norris_roundhouse":
		var facing := Vector2i.RIGHT
		if "facing_direction" in player:
			var fd: Vector2 = player.facing_direction
			facing = Vector2i(round(fd.x), round(fd.y))
		if facing == Vector2i.ZERO:
			facing = Vector2i.RIGHT
		for dist in range(1, 9):
			var shock_tile: Vector2i = centre_tile + (facing * dist)
			if kick.tilemap.is_tile_breakable(shock_tile):
				kick.tilemap.damageTileCoords(shock_tile, kick.damage * 5.0)
				kick.tilemap.sparks_manager.add_spark(kick.tilemap.map_to_local(shock_tile))

	# Chuck Norris: Spinning Back Heel (Crushing point impact)
	elif item_id == "kick_chuck_norris_spinning_heel":
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				var close_tile: Vector2i = centre_tile + Vector2i(dx, dy)
				if kick.tilemap.is_tile_breakable(close_tile):
					kick.tilemap.damageTileCoords(close_tile, kick.damage * 12.0)