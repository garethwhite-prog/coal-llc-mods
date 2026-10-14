extends Object

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var ms = chain.reference_object
	if not ms or not Gvars or not Gvars.profession:
		return

	var prof_name: String = str(Gvars.profession.profession_name).to_lower()
	var allowed_weapon_map := {
		"knight": "sword",
		"jedi": "jedi_saber",
		"bouncing ball": "bouncing_ball",
		"rainbow sinclairity": "sinclair_prism",
		"void siphon": "void_core",
		"debt executioner": "debt_executioner",
		"chrono-industrialist": "chrono_drill",
		"gravitational dreadnought": "dread_cannon",
		"tectonic fracker": "fracker"
	}

	if not allowed_weapon_map.has(prof_name):
		return

	var my_weapon_type: String = allowed_weapon_map[prof_name]
	var all_weapon_types := [
		"pickaxe", "axe", "battleaxe", "drill", "pistol", "shotgun", "rifle",
		"minigun", "staff", "water_staff", "poison_staff", "bomb", "mortar_gun",
		"tank", "jet", "orb", "laser", "flamethrower", "water_gun", "poison_gun",
		"boxing_glove", "roundhouse_kick", "turret", "sword", "bouncing_ball",
		"fracker", "jedi_saber", "sinclair_prism", "void_core", "debt_executioner",
		"dread_cannon", "chrono_drill"
	]

	var shop_container = ms.find_child("EquipmentContainer", true, false)
	if not shop_container:
		shop_container = ms.find_child("GridContainer", true, false)

	if shop_container:
		for child in shop_container.get_children():
			if "item" in child and child.item:
				var itype: String = str(child.item.itemType)
				if all_weapon_types.has(itype) and itype != my_weapon_type:
					child.visible = false