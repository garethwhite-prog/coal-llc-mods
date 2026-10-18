extends Object

func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
	if helper_script and helper_script.is_canvas_level():
		if pos.y < 0:
			return -2
		return 1
	return chain.execute_next([pos])

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	chain.execute_next([noise])
	var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
	if helper_script and helper_script.is_canvas_level():
		var chunk = chain.reference_object
		if chunk:
			helper_script.paint_chunk_from_canvas(chunk)

func damage_tile_idx(chain: ModLoaderHookChain, idx: int, damage: float, damage_type: int) -> void:
	var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
	if helper_script and helper_script.is_canvas_level():
		var chunk = chain.reference_object
		if chunk and chunk.has_method("array_to_global_pos"):
			var global_pos: Vector2i = Vector2i(chunk.array_to_global_pos(idx))
			# Apply damage multiplier to early canvas blocks so starter pickaxe can carve them
			if global_pos.y > 12 and global_pos.y < 35:
				damage *= 3.5
	chain.execute_next([idx, damage, damage_type])
