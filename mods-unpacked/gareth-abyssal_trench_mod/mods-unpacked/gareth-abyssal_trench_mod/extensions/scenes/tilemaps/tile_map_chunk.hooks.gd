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
				
				# Self-healing guard: if TILE_PROPERTIES is missing this ID, inject a duplicate from a known key
				if not chunk.TILE_PROPERTIES.has(t_id):
					var fallback_id = 211 if chunk.TILE_PROPERTIES.has(211) else (24 if chunk.TILE_PROPERTIES.has(24) else 41)
					if chunk.TILE_PROPERTIES.has(fallback_id):
						chunk.TILE_PROPERTIES[t_id] = chunk.TILE_PROPERTIES[fallback_id].duplicate(true)
				
				if chunk.TILE_PROPERTIES.has(t_id) and chunk.TILE_PROPERTIES[t_id].has("health"):
					var max_hp = float(chunk.TILE_PROPERTIES[t_id]["health"])
					# Guarantee every trench block breaks in 2-3 swings with starter pickaxe
					damage = max(damage, max_hp * 0.40)
	chain.execute_next([idx, damage])

func destroy_tile(chain: ModLoaderHookChain, idx: int, pos: Vector2i) -> void:
	var helper_script = load("res://mods-unpacked/gareth-abyssal_trench_mod/helpers/AbyssalTrenchHelper.gd")
	if helper_script and helper_script.is_abyssal_level():
		var chunk = chain.reference_object
		if chunk and ("tiles" in chunk) and idx >= 0 and idx < chunk.tiles.size():
			var t_id = chunk.tiles[idx]
			# If breaking basic stone (211 or 92), give a 50% chance to drop coal so every block is rewarding
			if (t_id == 211 or t_id == 92) and randf() < 0.50:
				if "coal_resource" in chunk and chunk.coal_resource:
					if chunk.has_method("spawn_item_drop"):
						chunk.spawn_item_drop(chunk.coal_resource, chunk.map_to_local(Vector2i(idx % chunk.chunk_size, idx / chunk.chunk_size)))
	chain.execute_next([idx, pos])
