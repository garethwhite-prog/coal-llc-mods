extends Object

func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	if Gvars and ("level" in Gvars) and Gvars.level == 105:
		# Coordinates at or above ground level MUST return -2 (overground sky/grass)
		if pos.y <= 0:
			return -2
		# Rotate subterranean strata 45 degrees
		var diag = int((pos.x + pos.y) * 0.707)
		return clampi(diag / 25, 1, 15)
	return chain.execute_next([pos])
