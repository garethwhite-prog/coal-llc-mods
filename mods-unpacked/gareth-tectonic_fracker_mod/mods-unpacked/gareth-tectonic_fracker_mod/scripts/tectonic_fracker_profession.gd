class_name TectonicFrackerProfession
extends Profession

func _profession_effect(data: Dictionary) -> Dictionary:
	var mod_node = Engine.get_main_loop().root.get_node_or_null("ModLoader/gareth-tectonic_fracker_mod")
	if mod_node and "starter_weapon" in mod_node and mod_node.starter_weapon:
		if data.has("inventory_starters"):
			data["inventory_starters"] = [{
				"item": mod_node.starter_weapon,
				"count": 1
			}]

	if data.has("unlocked_passives"):
		data["unlocked_passives"] = [
			"fracker_pulse_damage",
			"fracker_seam_resonance",
			"fracker_fire_rate",
			"player_sprint_speed",
			"player_jump_velocity",
			"player_climb_speed"
		]

	return data