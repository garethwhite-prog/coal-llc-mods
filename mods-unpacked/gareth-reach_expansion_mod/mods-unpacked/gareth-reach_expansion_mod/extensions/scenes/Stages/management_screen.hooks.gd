extends Object

func load_bonus_shop(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var mgmt = chain.reference_object
	if not is_instance_valid(mgmt) or not Gvars: return

	# Register custom passive property if missing
	if ("passives" in Gvars) and Gvars.passives and not ("player_reach_bonus" in Gvars.passives):
		Gvars.passives.set_meta("player_reach_bonus", 0.0)
