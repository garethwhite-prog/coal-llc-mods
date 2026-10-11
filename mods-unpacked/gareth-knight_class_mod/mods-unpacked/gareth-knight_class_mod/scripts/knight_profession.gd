extends Profession

func _profession_effect(data: Dictionary) -> Dictionary:
	# 1. Starting equipment: Shoddy Knight Sword only (no pickaxe)
	if data.has("inventory_starters"):
		var sword_res = load("res://mods-unpacked/gareth-knight_class_mod/items/KnightSword_01_shoddy.tres")
		if sword_res:
			data["inventory_starters"] = [{
				"item": sword_res,
				"count": 1
			}]

	# 2. Shop locking: only allow swords and essential utilities
	if not data.has("items_locked"):
		data["items_locked"] = []
	var forbidden: Array[String] = [
		"pickaxe", "axe", "battleaxe", "drill", "pistol", "shotgun", "rifle",
		"minigun", "staff", "water_staff", "poison_staff", "bomb", "mortar_gun",
		"tank", "jet", "orb", "laser", "flamethrower", "water_gun", "poison_gun",
		"boxing_glove", "roundhouse_kick", "turret"
	]
	for f in forbidden:
		if not data["items_locked"].has(f):
			data["items_locked"].append(f)
	return data