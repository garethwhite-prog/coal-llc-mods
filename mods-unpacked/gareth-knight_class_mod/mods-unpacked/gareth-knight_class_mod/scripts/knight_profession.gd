class_name KnightProfession
extends Profession

func _profession_effect(data: Dictionary) -> Dictionary:
	if data.has("inventory_starters"):
		var sword_res = load("res://mods-unpacked/gareth-knight_class_mod/items/KnightSword_01_shoddy.tres")
		if sword_res:
			data["inventory_starters"] = [{
				"item": sword_res,
				"count": 1
			}]
	return data