extends Object

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	var chunk = chain.reference_object
	if not chunk or not ("tiles" in chunk) or not chunk.has_method("array_to_global_pos"):
		chain.execute_next([noise])
		return

	if Gvars and ("level" in Gvars) and Gvars.level >= 100:
		chain.execute_next([noise])
		return

	var total_tiles: int = chunk.tiles.size()
	var temp_tiles = chunk.tiles.duplicate()

	var group_id = WorkerThreadPool.add_group_task(
		func(i: int):
			var pos = Vector2i(chunk.array_to_global_pos(i))
			var val = noise.get_noise_2d(float(pos.x), float(pos.y))
			if val < -0.35 and pos.y > 6:
				temp_tiles[i] = chunk.Tiles.EMPTY
			elif val > 0.28:
				temp_tiles[i] = chunk.Tiles.COAL_STONE
		,
		total_tiles,
		32
	)

	WorkerThreadPool.wait_for_group_task_completion(group_id)
	chunk.tiles = temp_tiles
	chain.execute_next([noise])
