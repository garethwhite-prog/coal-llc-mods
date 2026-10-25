extends Object

func damageTileCoords(chain: ModLoaderHookChain, global_posi: Vector2i, damage: float) -> void:
	var tm = chain.reference_object
	if not is_instance_valid(tm):
		return

	var chunk_id = tm.get_chunk_id(global_posi)
	if not ("chunks_created" in tm) or not tm.chunks_created.has(chunk_id):
		return

	chain.execute_next([global_posi, float(damage)])
