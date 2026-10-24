extends Object

func find_loot(chain: ModLoaderHookChain, collector) -> void:
	var ld = chain.reference_object
	if not is_instance_valid(ld) or not is_instance_valid(collector):
		chain.execute_next([collector])
		return

	# Check priority mode: 0 = Closest, 1 = Most Valuable First
	var priority_mode: int = 1
	if Gvars and ("collector_priority_mode" in Gvars):
		priority_mode = int(Gvars.collector_priority_mode)

	if priority_mode == 0:
		chain.execute_next([collector])
		return

	var loots = ld.loot_drops.get_children()
	if loots.is_empty():
		chain.execute_next([collector])
		return

	var best_loot = null
	var highest_val: float = -1.0
	for loot in loots:
		if is_instance_valid(loot) and ("pickupItem" in loot) and loot.pickupItem:
			var val: float = float(loot.pickupItem.itemSellPrice)
			if val > highest_val:
				highest_val = val
				best_loot = loot

	if best_loot:
		collector.target_pos = best_loot.global_position
		collector.state = collector.States.MOVING_TO_LOOT
		return

	chain.execute_next([collector])
