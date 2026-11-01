extends Object
func roll_loot(chain: ModLoaderHookChain) -> void:
	await chain.execute_next([])
	var chest = chain.reference_object
	if is_instance_valid(chest) and Gvars and Gvars.get("level") >= 50:
		if randf() < 0.15: # 15% chance for bonus endgame weapon
			var wep = load("res://scenes/equipment/plasma_raygun.tscn")
			if wep: chest.item_contents = wep
