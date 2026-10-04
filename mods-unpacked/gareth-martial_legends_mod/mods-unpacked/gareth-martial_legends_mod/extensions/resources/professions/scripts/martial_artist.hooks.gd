extends Object

func _profession_effect(chain: ModLoaderHookChain, _data: Dictionary) -> Dictionary:
	var res: Dictionary = chain.execute_next([_data])
	if res.has("unlocked_passives"):
		if not "punch_damage" in res["unlocked_passives"]:
			res["unlocked_passives"].append("punch_damage")
		if not "punch_speed" in res["unlocked_passives"]:
			res["unlocked_passives"].append("punch_speed")
		if not "kick_damage" in res["unlocked_passives"]:
			res["unlocked_passives"].append("kick_damage")
		if not "kick_speed" in res["unlocked_passives"]:
			res["unlocked_passives"].append("kick_speed")
	return res