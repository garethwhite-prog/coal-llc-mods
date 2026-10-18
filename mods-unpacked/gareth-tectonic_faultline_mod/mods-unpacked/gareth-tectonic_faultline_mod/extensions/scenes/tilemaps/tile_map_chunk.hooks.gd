extends Object

func generate_chunk(chunk: TileMapChunk, chain: ModLoaderHookChain) -> void:
	# If this is not Tectonic Faultline, pass through cleanly
	if not TectonicFaultlineHelper.is_faultline_level():
		chain.execute_next([chunk])
		return
	
	# Sky chunks above the surface should remain empty
	if "chunk_pos" in chunk and chunk.chunk_pos.y < 0:
		chain.execute_next([chunk])
		return
	
	chain.execute_next([chunk])
	
	# Replace subterranean matrix with seismic faultline strata
	if "chunk_pos" in chunk and chunk.chunk_pos.y >= 0:
		var noise = FastNoiseLite.new()
		noise.seed = Gvars.map_seed if "map_seed" in Gvars else 1337
		noise.frequency = 0.035
		
		for x in range(chunk.chunk_size):
			for y in range(chunk.chunk_size):
				var local_pos = Vector2i(x, y)
				var global_posi: Vector2i = Vector2i(chunk.to_global(chunk.map_to_local(local_pos)) / 16.0)
				
				# Only replace underground tiles
				if global_posi.y > 0:
					var idx = chunk.pos_to_array(local_pos) if chunk.has_method("pos_to_array") else (x + y * chunk.chunk_size)
					if idx >= 0 and idx < chunk.tiles.size():
						if chunk.tiles[idx] != chunk.Tiles.EMPTY:
							chunk.tiles[idx] = TectonicFaultlineHelper.pick_faultline_block(chunk, global_posi, noise)
		
		TectonicFaultlineHelper.tag_seismic_seams(chunk)

func generate_chests(chunk: TileMapChunk, current_locs: Array[Vector2i], chain: ModLoaderHookChain) -> void:
	if not TectonicFaultlineHelper.is_faultline_level():
		chain.execute_next([chunk, current_locs])
		return
	
	# Spawn fortified vaults and elemental pods
	current_locs = TectonicFaultlineHelper.spawn_magma_siphons(chunk, current_locs)
	chain.execute_next([chunk, current_locs])
