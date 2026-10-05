extends Object

func _profession_effect(chain: ModLoaderHookChain, data: Dictionary) -> Dictionary:
	var res: Dictionary = chain.execute_next([data])
	if res.has("unlocked_passives"):
		for stat in ["drill_speed", "axe_speed", "gun_rate"]:
			if not stat in res["unlocked_passives"]:
				res["unlocked_passives"].append(stat)
	return res