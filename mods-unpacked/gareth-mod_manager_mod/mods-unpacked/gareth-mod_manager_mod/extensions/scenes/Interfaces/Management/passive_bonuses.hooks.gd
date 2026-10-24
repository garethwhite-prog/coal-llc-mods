extends Object

func refresh(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var pb = chain.reference_object
	if not is_instance_valid(pb) or not Gvars or not ("passives" in Gvars) or not Gvars.passives:
		return

	var p = Gvars.passives

	var worker_stats = {
		"Employee Miner Speed": "employee_miner_speed",
		"Employee Miner Damage": "employee_miner_damage",
		"Employee Collector Speed": "employee_collector_speed",
		"Employee Collector Capacity": "employee_collector_capacity"
	}
	for s_name in worker_stats.keys():
		var prop: String = worker_stats[s_name]
		if prop in p:
			var val: float = float(p.get(prop))
			if val > 0.0:
				var lbl = RichTextLabel.new()
				lbl.text = "Increase %s +%d%%" % [s_name, roundi(val * 100)]
				lbl.fit_content = true
				pb.add_child(lbl)

	var custom_stats = [
		"sword_damage", "sword_speed", "sword_range",
		"employee_miner_range", "employee_miner_pickup_speed", "collector_range",
		"jedi_saber_damage", "jedi_swing_rate", "jedi_cleave_reach",
		"ball_blast_damage", "chrono_tick_rate", "exec_damage",
		"fracker_pulse_damage", "void_implosion_damage", "sinclair_melt_damage"
	]

	var cp_dict: Dictionary = {}
	if ("custom_passives" in Gvars) and (Gvars.custom_passives is Dictionary):
		cp_dict = Gvars.custom_passives

	for stat_key in custom_stats:
		var s_val: float = 0.0
		if cp_dict.has(stat_key):
			s_val = float(cp_dict[stat_key])
		elif p.has_meta(stat_key):
			s_val = float(p.get_meta(stat_key))
		elif stat_key in p:
			s_val = float(p.get(stat_key))

		if s_val > 0.0:
			var c_lbl = RichTextLabel.new()
			c_lbl.text = "Increase %s +%d%%" % [stat_key.replace("_", " ").capitalize(), roundi(s_val * 100)]
			c_lbl.fit_content = true
			pb.add_child(c_lbl)
