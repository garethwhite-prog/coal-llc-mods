extends Object

func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	if Gvars and ("map_id" in Gvars) and Gvars.map_id == 104:
		# 45-degree strata shift: X + Y
		var diag = int((pos.x + pos.y) * 0.707)
		return clampi(diag / 25, 1, 15)
	return chain.execute_next([pos])
