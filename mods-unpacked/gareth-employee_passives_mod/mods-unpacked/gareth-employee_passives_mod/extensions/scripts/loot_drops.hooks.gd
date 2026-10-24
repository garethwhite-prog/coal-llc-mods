extends Object

func find_loot(chain: ModLoaderHookChain, collector) -> void:
	var ld = chain.reference_object
	if is_instance_valid(ld):
		var range_stat: float = _get_passive_stat("collector_range")
		if range_stat > 0.0 and ("collector_sample_live_limit" in ld):
			ld.collector_sample_live_limit = int(round(25.0 * (1.0 + range_stat)))
	chain.execute_next([collector])

func _get_passive_stat(stat_name: String) -> float:
	if not Gvars:
		return 0.0
	if ("custom_passives" in Gvars) and (Gvars.custom_passives is Dictionary) and Gvars.custom_passives.has(stat_name):
		return float(Gvars.custom_passives[stat_name])
	if ("passives" in Gvars) and Gvars.passives:
		if Gvars.passives.has_meta(stat_name):
			return float(Gvars.passives.get_meta(stat_name))
		if stat_name in Gvars.passives:
			return float(Gvars.passives.get(stat_name))
	return 0.0
