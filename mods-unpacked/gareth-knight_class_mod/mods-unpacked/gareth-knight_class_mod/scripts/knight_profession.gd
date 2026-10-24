class_name KnightProfession
extends Profession

func _profession_effect(data: Dictionary) -> Dictionary:
	if Gvars and ("passives" in Gvars) and Gvars.passives:
		for stat in ["sword_damage", "sword_speed", "sword_range"]:
			if not Gvars.passives.has_meta(stat):
				Gvars.passives.set_meta(stat, 0.0)
			Gvars.passives.set(stat, Gvars.passives.get_meta(stat))

	if data.has("inventory_starters"):
		var sword_res = load("res://mods-unpacked/gareth-knight_class_mod/items/KnightSword_01_shoddy.tres")
		if sword_res:
			data["inventory_starters"] = [{
				"item": sword_res,
				"count": 1
			}]

	if data.has("unlocked_passives"):
		data["unlocked_passives"] = [
			"sword_damage",
			"sword_speed",
			"sword_range",
			"employee_miner_speed",
			"employee_miner_damage",
			"employee_collector_speed",
			"employee_collector_capacity",
			"player_sprint_speed",
			"player_jump_velocity",
			"player_climb_speed"
		]

	return data
