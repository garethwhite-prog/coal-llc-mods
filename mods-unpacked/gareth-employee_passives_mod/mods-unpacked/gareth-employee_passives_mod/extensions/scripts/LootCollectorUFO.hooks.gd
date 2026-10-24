extends Object

func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	chain.execute_next([delta])
	var ufo = chain.reference_object
	if not is_instance_valid(ufo):
		return

	var range_stat: float = _get_passive_stat("collector_range")
	if range_stat <= 0.0:
		return

	var magnet_radius: float = 64.0 * (1.0 + range_stat)
	var pull_speed: float = 350.0 * (1.0 + range_stat * 0.5)
	var tree = ufo.get_tree()
	if not tree or not tree.root:
		return
	var loot_mgr = tree.root.find_child("LootDrops", true, false)
	if not loot_mgr:
		return

	var u_pos = ufo.global_position
	var r_sq = magnet_radius * magnet_radius
	for child in loot_mgr.get_children():
		if is_instance_valid(child) and ("global_position" in child):
			var d_sq = u_pos.distance_squared_to(child.global_position)
			if d_sq <= r_sq:
				var dir = (u_pos - child.global_position).normalized()
				child.global_position += dir * pull_speed * delta
				if d_sq < 324.0:
					if child.has_method("pickup"):
						child.pickup(ufo)
					elif ufo.has_method("on_ItemPickup") and ("pickupItem" in child):
						ufo.on_ItemPickup(child.pickupItem, ufo)
						child.queue_free()

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
