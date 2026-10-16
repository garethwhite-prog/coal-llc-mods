func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	if Gvars.level == 101:
		var helper_script = load("res://mods-unpacked/gareth-lost_expedition_mod/helpers/LostExpeditionHelper.gd")
		if helper_script:
			var helper = helper_script.new()
			return helper.calculate_tier(pos)
	return chain.execute_next([pos])

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	chain.execute_next([noise])
	if Gvars.level == 101:
		var helper_script = load("res://mods-unpacked/gareth-lost_expedition_mod/helpers/LostExpeditionHelper.gd")
		if helper_script:
			var helper = helper_script.new()
			helper.tag_uxo_tiles(self)

func destroy_tile(chain: ModLoaderHookChain, idx: int, tile_properties: Dictionary) -> void:
	if Gvars.level == 101:
		var helper_script = load("res://mods-unpacked/gareth-lost_expedition_mod/helpers/LostExpeditionHelper.gd")
		if helper_script:
			var helper = helper_script.new()
			helper.handle_tile_destroyed(self, idx)
	chain.execute_next([idx, tile_properties])

func generate_chests(chain: ModLoaderHookChain, current_block_chest_locations: Array[Vector2i]) -> Array[Vector2i]:
	var locs: Array[Vector2i] = chain.execute_next([current_block_chest_locations])
	if Gvars.level == 101:
		var helper_script = load("res://mods-unpacked/gareth-lost_expedition_mod/helpers/LostExpeditionHelper.gd")
		if helper_script:
			var helper = helper_script.new()
			locs = helper.spawn_cryo_pods(self, locs)
	return locs
