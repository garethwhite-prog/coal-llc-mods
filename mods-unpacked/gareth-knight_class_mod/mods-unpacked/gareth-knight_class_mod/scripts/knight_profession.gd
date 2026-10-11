extends Profession

func _profession_effect(data: Dictionary) -> Dictionary:
	if not data.has("items_locked"):
		data["items_locked"] = []
	var non_class_weapons: Array[String] = [
		"pistol", "shotgun", "rifle", "minigun", "staff", "water_staff",
		"poison_staff", "bomb", "mortar_gun", "drill", "tank", "jet",
		"orb", "laser", "flamethrower", "water_gun", "poison_gun",
		"boxing_glove", "roundhouse_kick", "turret"
	]
	for w in non_class_weapons:
		if not data["items_locked"].has(w):
			data["items_locked"].append(w)
	return data