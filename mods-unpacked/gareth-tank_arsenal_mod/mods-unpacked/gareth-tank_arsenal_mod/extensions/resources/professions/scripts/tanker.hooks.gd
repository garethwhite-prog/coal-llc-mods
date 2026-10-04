extends Object

func _profession_effect(chain: ModLoaderHookChain, data: Dictionary) -> Dictionary:
	var res: Dictionary = chain.execute_next([data])
	if res.has("unlocked_passives"):
		if not "fire_damage" in res["unlocked_passives"]:
			res["unlocked_passives"].append("fire_damage")
		if not "poison_damage" in res["unlocked_passives"]:
			res["unlocked_passives"].append("poison_damage")
	return res