extends Object

func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	var helper_script = load("res://mods-unpacked/gareth-abyssal_trench_mod/helpers/AbyssalTrenchHelper.gd")
	if helper_script and helper_script.is_abyssal_level():
		if pos.y < 0:
			return -2
		return 1
	return chain.execute_next([pos])

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	chain.execute_next([noise])
	var helper_script = load("res://mods-unpacked/gareth-abyssal_trench_mod/helpers/AbyssalTrenchHelper.gd")
	if helper_script and helper_script.is_abyssal_level():
		var chunk = chain.reference_object
		if chunk:
			helper_script.generate_abyssal_strata(chunk, noise)

func damage_tile_idx(chain: ModLoaderHookChain, idx: int, damage: float) -> void:
	var helper_script = load("res://mods-unpacked/gareth-abyssal_trench_mod/helpers/AbyssalTrenchHelper.gd")
	if helper_script and helper_script.is_abyssal_level():
		var chunk = chain.reference_object
		if chunk and ("tiles" in chunk) and ("TILE_PROPERTIES" in chunk):
			if idx >= 0 and idx < chunk.tiles.size():
				var t_id = chunk.tiles[idx]
				if not chunk.TILE_PROPERTIES.has(t_id):
					var fallback_id = 211 if chunk.TILE_PROPERTIES.has(211) else (24 if chunk.TILE_PROPERTIES.has(24) else 41)
					if chunk.TILE_PROPERTIES.has(fallback_id):
						chunk.TILE_PROPERTIES[t_id] = chunk.TILE_PROPERTIES[fallback_id].duplicate(true)
		# Guaranteed damage floor for Abyssal Trench so starter pickaxe carves in 1-2 hits
		damage = max(damage * 6.0, 35.0)

	chain.execute_next([idx, damage])

func destroy_tile(chain: ModLoaderHookChain, idx: int) -> void:
	var helper_script = load("res://mods-unpacked/gareth-abyssal_trench_mod/helpers/AbyssalTrenchHelper.gd")
	if helper_script and helper_script.is_abyssal_level():
		var chunk = chain.reference_object
		if chunk and ("tiles" in chunk) and idx >= 0 and idx < chunk.tiles.size():
			var t_id = chunk.tiles[idx]
			# 50% bonus coal nugget drop for filler ocean stone
			if (t_id == 211 or t_id == 92) and randf() < 0.50:
				if "coal_resource" in chunk and chunk.coal_resource:
					if chunk.has_method("spawn_item_drop"):
						var local_coords = Vector2i(idx % chunk.chunk_size, idx / chunk.chunk_size)
						chunk.spawn_item_drop(chunk.coal_resource, chunk.map_to_local(local_coords))

	# Strictly pass single idx parameter matching vanilla destroy_tile(idx) signature
	chain.execute_next([idx])
