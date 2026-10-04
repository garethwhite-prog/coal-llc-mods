extends Object

func generate_vacuum_cleaner(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var mgr = chain.reference_object
	if not mgr or not mgr.bem:
		return
	var cur_lvl = int(mgr.bem.current_vacuum)
	var target_len = 0
	match cur_lvl:
		5: target_len = 220 * 16
		6: target_len = 300 * 16
		7: target_len = 420 * 16
		8: target_len = 600 * 16
		_: target_len = 0

	if target_len > 0:
		for child in mgr.get_children():
			if child is VacuumCleaner:
				child.vacuum_length = target_len
				ModLoaderLog.info("Upgraded vacuum tether length to %d px (%d tiles)." % [target_len, target_len / 16], "gareth-buyable_vacuums_mod")