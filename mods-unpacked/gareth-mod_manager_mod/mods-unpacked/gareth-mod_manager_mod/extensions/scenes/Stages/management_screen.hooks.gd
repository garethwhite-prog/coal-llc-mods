extends Object

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var ms = chain.reference_object
	if not ms or not Gvars:
		return

	# Enforce Day 1 starting debt balance for Debt Executioner
	if Gvars.profession and str(Gvars.profession.profession_name).to_lower() == "debt executioner":
		if Gvars.cash >= 0.0 and ("day" in Gvars and Gvars.day <= 1):
			Gvars.cash = -50000000.0
			for label_name in ["Cash", "CashLabel", "%Cash", "%CashLabel"]:
				var lbl = ms.find_child(label_name, true, false)
				if lbl and "text" in lbl:
					lbl.text = "Cash: -50,000,000"
			if Bus and Bus.has_signal("cash_changed"):
				Bus.cash_changed.emit(Gvars.cash)

	if not Gvars.profession:
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
		"dread_cannon", "chrono_drill", "incendiary_tank", "caustic_tank"
	]

	# Hide weapons belonging to other classes
	var all_items = ms.find_children("", "Control", true, false)
	for child in all_items:
		if "item" in child and child.item:
			var itype: String = str(child.item.itemType)
			if all_weapon_types.has(itype) and itype != my_weapon_type:
				child.visible = false