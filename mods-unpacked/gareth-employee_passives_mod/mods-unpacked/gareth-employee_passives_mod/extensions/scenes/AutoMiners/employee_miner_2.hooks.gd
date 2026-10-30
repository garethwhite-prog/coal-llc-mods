extends Object

func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	var miner = chain.reference_object
	if is_instance_valid(miner):
		var range_stat: float = _get_passive_stat("employee_miner_range")
		var speed_stat: float = _get_passive_stat("employee_miner_pickup_speed")

		if range_stat > 0.0 and ("pickaxe_range" in miner):
			miner.pickaxe_range = int(round(3.0 * (1.0 + range_stat)))
			miner.search_range = int(round(10.0 * (1.0 + range_stat)))

		var is_moving = false
		if ("state" in miner) and ("States" in miner):
			is_moving = (miner.state == miner.States.MOVING_TO_TARGET)

		if speed_stat > 0.0 and is_moving and ("velocity" in miner):
			miner.velocity.x *= (1.0 + speed_stat)

		if range_stat > 0.0 and is_moving and ("target_pos" in miner):
			var reach: float = 16.0 * (1.0 + range_stat)
			if abs(miner.global_position.x - miner.target_pos.x) < reach:
				if "mining_animation_player" in miner:
					miner.mining_animation_player.play("mining")
				miner.state = miner.States.MINING

		if speed_stat > 0.0:
			_vacuum_nearby_loot(miner, 52.0 * (1.0 + range_stat), 260.0 * (1.0 + speed_stat), delta)

	chain.execute_next([delta])

func _vacuum_nearby_loot(miner: Node2D, radius: float, pull_speed: float, delta: float) -> void:
	var tree = miner.get_tree()
	if not tree or not tree.root:
		return
	var loot_mgr = tree.root.find_child("LootDrops", true, false)
	if not is_instance_valid(loot_mgr):
		return
		
	var m_pos = miner.global_position
	var r_sq = radius * radius
	
	for child in loot_mgr.get_children():
		if is_instance_valid(child) and ("global_position" in child):
			var d_sq = m_pos.distance_squared_to(child.global_position)
			if d_sq <= r_sq:
				var dir = (m_pos - child.global_position).normalized()
				child.global_position += dir * pull_speed * delta

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
