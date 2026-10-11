extends Profession

func _profession_effect(data: Dictionary) -> Dictionary:
	# Starts with ZERO tools
	if data.has("inventory_starters"):
		data["inventory_starters"] = []

	# Locks all manufactured equipment
	if not data.has("items_locked"):
		data["items_locked"] = []
	var forbidden: Array[String] = [
		"pickaxe", "axe", "battleaxe", "drill", "pistol", "shotgun", "rifle",
		"minigun", "staff", "water_staff", "poison_staff", "bomb", "mortar_gun",
		"tank", "jet", "orb", "laser", "flamethrower", "water_gun", "poison_gun",
		"boxing_glove", "roundhouse_kick", "turret", "sword"
	]
	for f in forbidden:
		if not data["items_locked"].has(f):
			data["items_locked"].append(f)
	return data