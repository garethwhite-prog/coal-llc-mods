extends Object

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	var chunk = chain.reference_object
	if not chunk or not ("tiles" in chunk) or not chunk.has_method("array_to_global_pos"):
		chain.execute_next([noise])
		return

	# If the chunk has a custom map active, allow the map chain to proceed normally
	if Gvars and ("level" in Gvars) and Gvars.level >= 100:
		chain.execute_next([noise])
		return

	# Multi-threaded standard chunk calculation across available CPU threads
	var total_tiles = chunk.tiles.size()
	var temp_tiles = chunk.tiles.duplicate()

	var group_id = WorkerThreadPool.add_group_task(
		func(i: int):
			var pos = Vector2i(chunk.array_to_global_pos(i))
			# Background thread noise sampling
			var val = noise.get_noise_2d(float(pos.x), float(pos.y))
			if val < -0.35 and pos.y > 6:
				temp_tiles[i] = chunk.Tiles.EMPTY
			elif val > 0.28:
				temp_tiles[i] = chunk.Tiles.COAL_STONE
		,
		total_tiles,
		32 # Process in batches of 32 tiles per thread task
	)

	# Await parallel background worker tasks
	WorkerThreadPool.wait_for_group_task_completion(group_id)

	# Commit completed thread data back to the chunk
	chunk.tiles = temp_tiles
	chain.execute_next([noise])
