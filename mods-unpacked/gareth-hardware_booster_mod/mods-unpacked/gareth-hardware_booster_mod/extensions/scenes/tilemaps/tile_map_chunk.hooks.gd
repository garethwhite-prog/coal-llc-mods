extends Object

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	var chunk = chain.reference_object
	# Always let vanilla generate chunk 0 (surface grass, cabin, stockpile & drop-off pit)
	if not chunk or not ("chunk_pos" in chunk) or chunk.chunk_pos.y <= 0:
		chain.execute_next([noise])
		return

	# Only apply acceleration to deep subterranean chunks (Y > 0)
	chain.execute_next([noise])
