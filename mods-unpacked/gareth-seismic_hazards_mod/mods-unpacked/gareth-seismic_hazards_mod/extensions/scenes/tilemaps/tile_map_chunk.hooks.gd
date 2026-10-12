extends Object

func destroy_tile(chain: ModLoaderHookChain, idx: int, tile_properties: Dictionary) -> void:
	var reg = load("res://mods-unpacked/gareth-mod_manager_mod/scripts/mod_registry.gd")
	if reg and not reg.is_mod_active_for_run("seismic_hazards"):
		chain.execute_next([idx, tile_properties])
		return

	chain.execute_next([idx, tile_properties])