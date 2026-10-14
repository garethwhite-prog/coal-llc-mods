class_name DebtExecutionerProfession
extends Profession

func _profession_effect(data: Dictionary) -> Dictionary:
	if Gvars and ("cash" in Gvars):
		if Gvars.cash >= 0:
			Gvars.cash = -50000000.0

	var mod_node = Engine.get_main_loop().root.get_node_or_null("ModLoader/gareth-debt_executioner_mod")
	if mod_node and "starter_weapon" in mod_node and mod_node.starter_weapon:
		if data.has("inventory_starters"):
			data["inventory_starters"] = [{
				"item": mod_node.starter_weapon,
				"count": 1
			}]

	if data.has("unlocked_passives"):
		data["unlocked_passives"] = [
			"exec_damage",
			"exec_fire_rate",
			"exec_bounty",
			"player_sprint_speed",
			"player_jump_velocity",
			"player_climb_speed"
		]

	return data