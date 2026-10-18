extends Object

const HelperScript = preload("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")

func lvl_from_global_pos(pos, chain: ModLoaderHookChain) -> int:
	if HelperScript.is_faultline_level():
		return HelperScript.calculate_faultline_tier(Vector2i(pos))
	return chain.execute_next([pos])

func generate_chunk(chain: ModLoaderHookChain) -> void:
	var chunk = chain.reference_object
	if not chunk or not HelperScript.is_faultline_level():
		chain.execute_next([])
		return
	
	# Pass through sky chunks cleanly
	if "chunk_pos" in chunk and chunk.chunk_pos.y < 0:
		chain.execute_next([])
		return
	
	chain.execute_next([])
	
	# Generate faultline matrix below surface
	if "chunk_pos" in chunk and chunk.chunk_pos.y >= 0:
		var noise = FastNoiseLite.new()
		noise.seed = Gvars.map_seed if "map_seed" in Gvars else 1337
		noise.frequency = 0.035
		
		for x in range(chunk.chunk_size):
			for y in range(chunk.chunk_size):
				var local_pos = Vector2i(x, y)
				var global_posi: Vector2i = Vector2i(chunk.to_global(chunk.map_to_local(local_pos)) / 16.0)
				
				if global_posi.y > 0:
					var idx: int = -1
					if chunk.has_method("local_pos_to_array"):
						idx = chunk.local_pos_to_array(local_pos)
					elif chunk.has_method("pos_to_array"):
						idx = chunk.pos_to_array(local_pos)
					else:
						idx = x + y * chunk.chunk_size
					
					if idx >= 0 and idx < chunk.tiles.size():
						if chunk.tiles[idx] != chunk.Tiles.EMPTY:
							chunk.tiles[idx] = HelperScript.pick_faultline_block(chunk, global_posi, noise)
		
		HelperScript.tag_seismic_seams(chunk)

func generate_chests(current_locs: Array[Vector2i], chain: ModLoaderHookChain) -> Array[Vector2i]:
	var chunk = chain.reference_object
	if not chunk or not HelperScript.is_faultline_level():
		return chain.execute_next([current_locs])
	
	current_locs = HelperScript.spawn_magma_siphons(chunk, current_locs)
	return chain.execute_next([current_locs])

func destroy_tile(idx: int, tile_properties: Dictionary, chain: ModLoaderHookChain) -> void:
	chain.execute_next([idx, tile_properties])
