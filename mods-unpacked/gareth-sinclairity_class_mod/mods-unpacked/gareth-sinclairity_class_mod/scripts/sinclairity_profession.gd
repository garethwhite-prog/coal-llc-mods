class_name SinclairityProfession
extends Profession

func _profession_effect(data: Dictionary) -> Dictionary:
	var mod_node = Engine.get_main_loop().root.get_node_or_null("ModLoader/gareth-sinclairity_class_mod")
	if mod_node and "starter_weapon" in mod_node and mod_node.starter_weapon:
		if data.has("inventory_starters"):
			data["inventory_starters"] = [{
				"item": mod_node.starter_weapon,
				"count": 1
			}]

	if data.has("unlocked_passives"):
		data["unlocked_passives"] = [
			"sinclair_melt_damage",
			"sinclair_beam_width",
			"sinclair_spectrum_ticks",
			"player_sprint_speed",
			"player_jump_velocity",
			"player_climb_speed"
		]

	return data