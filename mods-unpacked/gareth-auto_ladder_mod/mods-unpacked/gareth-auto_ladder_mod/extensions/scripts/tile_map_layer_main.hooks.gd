extends Object

func damageTileCoords(chain: ModLoaderHookChain, coords: Vector2i, damage: float) -> void:
	chain.execute_next([coords, damage])
	var tm = chain.reference_object
	if not is_instance_valid(tm):
		return

	# Center column check (X = 0)
	if coords.x == 0:
		if tm.has_method("place_ladder"):
			tm.place_ladder(coords)
		elif "ladders" in tm and tm.ladders and tm.ladders.has_method("add_ladder"):
			tm.ladders.add_ladder(coords)
