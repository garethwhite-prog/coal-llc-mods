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
		if chunk and ("TILE_PROPERTIES" in chunk) and ("tiles" in chunk):
			if idx >= 0 and idx < chunk.tiles.size():
				var t_id = chunk.tiles[idx]
				if chunk.TILE_PROPERTIES.has(t_id) and chunk.TILE_PROPERTIES[t_id].has("health"):
					var max_hp = float(chunk.TILE_PROPERTIES[t_id]["health"])
					# Guarantee every trench block breaks in 2-3 swings with starter pickaxe
					damage = max(damage, max_hp * 0.40)
	chain.execute_next([idx, damage])
