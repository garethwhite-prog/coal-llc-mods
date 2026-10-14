extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var ms = chain.reference_object
	if not ms or not Gvars:
		return

	if Gvars.profession and str(Gvars.profession.profession_name).to_lower().contains("debt"):
		if "CashCount" in Gvars and Gvars.CashCount >= 0.0:
			Gvars.CashCount = -50000000.0
		if "cash" in Gvars and Gvars.cash >= 0.0:
			Gvars.cash = -50000000.0
		if ms.has_method("refresh_cash"):
			ms.refresh_cash()

func refresh_cash(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var ms = chain.reference_object
	if not ms or not Gvars:
		return

	if Gvars.profession and str(Gvars.profession.profession_name).to_lower().contains("debt"):
		if "CashCount" in Gvars and Gvars.CashCount >= 0.0 and ("day" in Gvars and Gvars.day <= 1):
			Gvars.CashCount = -50000000.0
			if "current_cash" in ms and ms.current_cash:
				ms.current_cash.text = "[b]Cash: -50,000,000"

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var ms = chain.reference_object
	if not ms or not Gvars or not Gvars.profession:
		return

	var prof_name: String = str(Gvars.profession.profession_name).to_lower()
	var allowed_map := {
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

	if not allowed_map.has(prof_name):
		return

	var my_type: String = allowed_map[prof_name]
	var weapon_types := [
		"pickaxe", "axe", "battleaxe", "drill", "pistol", "shotgun", "rifle",
		"minigun", "staff", "water_staff", "poison_staff", "bomb", "mortar_gun",
		"tank", "jet", "orb", "laser", "flamethrower", "water_gun", "poison_gun",
		"boxing_glove", "roundhouse_kick", "turret", "sword", "bouncing_ball",
		"fracker", "jedi_saber", "sinclair_prism", "void_core", "debt_executioner",
		"dread_cannon", "chrono_drill", "incendiary_tank", "caustic_tank",
		"nuke", "water_spirit"
	]

	var all_items = ms.find_children("", "Control", true, false)
	for child in all_items:
		if "item" in child and child.item:
			var itype: String = str(child.item.itemType)
			if weapon_types.has(itype) and itype != my_type:
				child.visible = false