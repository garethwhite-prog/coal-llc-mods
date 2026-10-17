extends Object

func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	if Gvars.level == 102:
		var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
		if helper_script:
			var helper = helper_script.new()
			return helper.calculate_faultline_tier(pos)
	return chain.execute_next([pos])

func generate_chunk(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	if Gvars.level == 102:
		var chunk = chain.reference_object
		var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
		if helper_script and chunk:
			var helper = helper_script.new()
			helper.tag_seismic_seams(chunk)

func destroy_tile(chain: ModLoaderHookChain, idx: int) -> void:
	var chunk = chain.reference_object
	var tile_props: Dictionary = {}
	if chunk and idx >= 0 and idx < chunk.tiles.size():
		var tile_id = chunk.tiles[idx]
		if chunk.TILE_PROPERTIES.has(tile_id):
			tile_props = chunk.TILE_PROPERTIES[tile_id]
	
	chain.execute_next([idx])
	
	if Gvars.level == 102 and chunk:
		var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
		if helper_script:
			var helper = helper_script.new()
			helper.handle_tile_destroyed(chunk, idx, tile_props)

func generate_chests(chain: ModLoaderHookChain, current_locs: Array[Vector2i]) -> Array[Vector2i]:
	var result_locs: Array[Vector2i] = chain.execute_next([current_locs])
	if Gvars.level == 102:
		var chunk = chain.reference_object
		var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
		if helper_script and chunk:
			var helper = helper_script.new()
			result_locs = helper.spawn_magma_siphons(chunk, result_locs)
	return result_locs
