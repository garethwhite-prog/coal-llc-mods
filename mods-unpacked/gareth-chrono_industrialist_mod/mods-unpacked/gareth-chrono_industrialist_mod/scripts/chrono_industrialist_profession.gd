class_name ChronoIndustrialistProfession
extends Profession

func _profession_effect(data: Dictionary) -> Dictionary:
	var mod_node = Engine.get_main_loop().root.get_node_or_null("ModLoader/gareth-chrono_industrialist_mod")
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
		"minigun", "staff", "water_staff", "poison_staff", "bomb", "mortar_gun",
		"tank", "jet", "orb", "laser", "flamethrower", "water_gun", "poison_gun",
		"boxing_glove", "roundhouse_kick", "turret", "sword", "bouncing_ball", "fracker"
	])

	if data.has("unlocked_passives"):
		data["unlocked_passives"] = [
			"chrono_tick_rate",
			"chrono_shockwave_damage",
			"chrono_stasis_duration",
			"player_sprint_speed",
			"player_jump_velocity",
			"player_climb_speed"
		]

	return data