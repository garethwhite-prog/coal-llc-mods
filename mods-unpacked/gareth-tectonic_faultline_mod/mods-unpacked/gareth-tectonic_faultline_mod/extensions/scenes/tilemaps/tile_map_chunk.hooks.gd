extends Object

const HelperScript = preload("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")

func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	if HelperScript.is_faultline_level():
		return HelperScript.calculate_faultline_tier(pos)
	return chain.execute_next([pos])

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	# 1. Let vanilla execute completely with noise argument to populate chunk.tiles
	chain.execute_next([noise])
	
	# 2. If Tectonic Faultline, sculpt strata and spawn elemental vaults
	if HelperScript.is_faultline_level():
		var chunk = chain.reference_object
		if chunk and "chunk_pos" in chunk and chunk.chunk_pos.y >= 0:
			var fnl = FastNoiseLite.new()
			fnl.seed = Gvars.map_seed if ("map_seed" in Gvars) else 1337
			fnl.frequency = 0.035
			HelperScript.generate_faultline_strata(chunk, fnl)
			HelperScript.spawn_magma_siphons(chunk)

func generate_chests(chain: ModLoaderHookChain, current_locs: Array[Vector2i]) -> Array[Vector2i]:
	return chain.execute_next([current_locs])

func destroy_tile(chain: ModLoaderHookChain, idx: int, tile_properties: Dictionary) -> void:
	chain.execute_next([idx, tile_properties])
