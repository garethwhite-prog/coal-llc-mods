extends Object

func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	if Gvars and ("level" in Gvars) and Gvars.level == 103:
		if pos.y < 0:
			return -2 # Sky stratum air contract
		return 1
	return chain.execute_next([pos])

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	chain.execute_next([noise])
	if Gvars and ("level" in Gvars) and Gvars.level == 103:
		var chunk = chain.reference_object
		if chunk and "chunk_pos" in chunk and chunk.chunk_pos.y >= 0:
			var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
			if helper_script:
				helper_script.paint_chunk_from_canvas(chunk)
