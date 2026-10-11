extends Object

func destroy_tile(chain: ModLoaderHookChain, tile_pos: Vector2i, drop_ores: bool = true) -> void:
	var reg = load("res://mods-unpacked/gareth-mod_manager_mod/scripts/mod_registry.gd")
	if reg and not reg.is_mod_active_for_run("seismic_hazards"):
		chain.execute_next([tile_pos, drop_ores])
		return

	chain.execute_next([tile_pos, drop_ores])
	# Seismic hazard cave-in logic continues below...