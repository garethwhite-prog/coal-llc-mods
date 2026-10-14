class_name DebtExecutionerProfession
extends Profession

func _profession_effect(data: Dictionary) -> Dictionary:
	if Gvars and ("cash" in Gvars):
		Gvars.cash = -50000000.0

	var mod_node = Engine.get_main_loop().root.get_node_or_null("ModLoader/gareth-debt_executioner_mod")
	if mod_node and "starter_weapon" in mod_node and mod_node.starter_weapon:
		if data.has("inventory_starters"):
			data["inventory_starters"] = [{
				"item": mod_node.starter_weapon,
				"count": 1
			}]

	if not data.has("items_locked"):
		data["items_locked"] = []
	data["items_locked"].append_array([
		"pickaxe", "axe", "battleaxe", "drill", "pistol", "shotgun", "rifle",
		"staff", "water_staff", "poison_staff", "bomb", "mortar_gun",
		"tank", "jet", "orb", "laser", "flamethrower", "water_gun", "poison_gun",
		"boxing_glove", "roundhouse_kick", "turret", "sword", "bouncing_ball", "fracker"
	])

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