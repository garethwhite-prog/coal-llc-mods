extends Object

func refresh(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var pb = chain.reference_object
	if not is_instance_valid(pb) or not Gvars or not ("passives" in Gvars) or not Gvars.passives:
		return

	var p = Gvars.passives

	# Worker passives
	var worker_stats = {
		"Employee Miner Speed": p.employee_miner_speed,
		"Employee Miner Damage": p.employee_miner_damage,
		"Employee Collector Speed": p.employee_collector_speed,
		"Employee Collector Capacity": p.employee_collector_capacity
	}
	for s_name in worker_stats.keys():
		var val: float = float(worker_stats[s_name])
		if val > 0.0:
			var lbl = RichTextLabel.new()
			lbl.text = "%s +%d%%" % [s_name, roundi(val * 100)]
			lbl.fit_content = true
			pb.add_child(lbl)

	# Custom class weapon passives
	for stat_key in ["sword_damage", "sword_speed", "sword_range", "jedi_saber_damage", "jedi_saber_speed"]:
		var s_val: float = 0.0
		if p.has_meta(stat_key):
			s_val = float(p.get_meta(stat_key))
		elif stat_key in p:
			s_val = float(p.get(stat_key))

		if s_val > 0.0:
			var c_lbl = RichTextLabel.new()
			c_lbl.text = "Increase %s +%d%%" % [stat_key.replace("_", " ").capitalize(), roundi(s_val * 100)]
			c_lbl.fit_content = true
			pb.add_child(c_lbl)
