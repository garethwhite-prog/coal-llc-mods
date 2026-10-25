extends Object

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	# Execute base game chunk generation first so surface rows and empty sky are respected
	chain.execute_next([noise])

	var chunk = chain.reference_object
	if not chunk or not ("tiles" in chunk) or not chunk.has_method("array_to_global_pos"):
		return

	# Only apply hardware worker acceleration to subterranean regions (Y > 0)
	for idx in range(chunk.tiles.size()):
		var global_pos: Vector2i = Vector2i(chunk.array_to_global_pos(idx))
		if global_pos.y <= 0:
			# Ensure sky and surface air remain completely open
			chunk.tiles[idx] = chunk.Tiles.EMPTY
			chunk.build_tile(idx)
