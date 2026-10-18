extends Object

func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	if Gvars.level == 102:
		var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
		if helper_script:
			return helper_script.calculate_faultline_tier(pos)
	return chain.execute_next([pos])

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	chain.execute_next([noise])
	if Gvars.level == 102:
		var chunk = chain.reference_object
		if chunk and "chunk_pos" in chunk and chunk.chunk_pos.y >= 0:
			var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
			if helper_script:
				var fnl = FastNoiseLite.new()
				fnl.seed = Gvars.map_seed if ("map_seed" in Gvars) else 1337
				fnl.frequency = 0.035
				helper_script.generate_faultline_strata(chunk, fnl)

func generate_chests(chain: ModLoaderHookChain, current_block_chest_locations: Array[Vector2i]) -> Array[Vector2i]:
	var locs: Array[Vector2i] = chain.execute_next([current_block_chest_locations])
	if Gvars.level == 102:
		var chunk = chain.reference_object
		if chunk:
			var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
			if helper_script:
				locs = helper_script.spawn_magma_siphons(chunk, locs)
	return locs

func destroy_tile(chain: ModLoaderHookChain, idx: int, tile_properties: Dictionary) -> void:
	chain.execute_next([idx, tile_properties])

func apply_tile_effects(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var chunk = chain.reference_object
	if chunk and ("level" in Gvars) and Gvars.level == 102:
		var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
		if helper_script:
			var tick_bonus: float = helper_script.get_elemental_tick_bonus()
			if tick_bonus > 0.0:
				var acc: float = chunk.get_meta("elem_tick_acc", 0.0) + tick_bonus
				while acc >= 1.0:
					acc -= 1.0
					if chunk.has_method("poisons_loop"):
						chunk.poisons_loop()
					if chunk.has_method("burns_loop"):
						chunk.burns_loop()
				chunk.set_meta("elem_tick_acc", acc)
