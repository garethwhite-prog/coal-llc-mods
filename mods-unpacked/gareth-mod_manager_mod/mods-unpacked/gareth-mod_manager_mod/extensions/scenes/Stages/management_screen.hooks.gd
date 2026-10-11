extends Object

const ALL_CLASS_WEAPONS: Array[String] = [
	"pickaxe", "electric_pickaxe", "axe", "battleaxe", "drill",
	"pistol", "shotgun", "rifle", "minigun", "staff", "water_staff",
	"poison_staff", "bomb", "mortar_gun", "tank", "jet", "orb",
	"flamethrower", "water_gun", "poison_gun", "boxing_glove",
	"roundhouse_kick", "earthquake", "nuke", "sword", "void_core"
]

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var screen = chain.reference_object
	if not screen:
		return

	var reg = load("res://mods-unpacked/gareth-mod_manager_mod/scripts/mod_registry.gd")
	var prof_name: String = ""
	if Gvars and ("profession" in Gvars) and Gvars.profession and ("profession_name" in Gvars.profession):
		prof_name = str(Gvars.profession.profession_name).to_lower()

	var class_weapon_map: Dictionary = {
		"knight": ["sword"],
		"jedi": ["laser", "pistol"],
		"bouncing demolitionist": ["bomb", "grenade"],
		"rainbow sinclairity": ["laser"],
		"void siphon": ["void_core"],
		"debt executioner": ["staff", "poison_gun", "minigun"],
		"chrono-industrialist": ["pickaxe"],
		"gravitational dreadnought": ["shotgun", "tank"],
		"tectonic fracker": ["drill", "mortar_gun"]
	}

	var eq_shop = screen.get_node_or_null("%EquipmentShop")
	if not eq_shop and "equipment_shop" in screen:
		eq_shop = screen.equipment_shop
	if not eq_shop:
		return

	for card in eq_shop.get_children():
		if not ("item" in card) or not card.item:
			continue
		var item = card.item
		var itype: String = str(item.itemType).to_lower()
		var iname: String = str(item.itemName).to_lower()
		var should_hide: bool = false

		# 1. PURGE DISABLED MOD WEAPONS & EXPLOSIVES
		if iname.contains("hydrogen") and reg and not reg.is_mod_active_for_run("hydrogen_bomb"):
			should_hide = true
		elif iname.contains("neutron") and reg and not reg.is_mod_active_for_run("neutron_bomb"):
			should_hide = true
		elif (itype == "nuke" or iname.contains("nuke")) and reg and not reg.is_mod_active_for_run("more_nukes"):
			should_hide = true
		elif itype == "turret" and reg and not reg.is_mod_active_for_run("heavy_turrets"):
			should_hide = true
		elif itype == "water_spirit" and reg and not reg.is_mod_active_for_run("water_spirit"):
			should_hide = true
		elif itype == "laser" and reg and not reg.is_mod_active_for_run("laser_beam") and prof_name != "jedi" and prof_name != "rainbow sinclairity":
			should_hide = true

		# 2. ISOLATE CLASS-EXCLUSIVE WEAPONS
		if not should_hide and itype in ALL_CLASS_WEAPONS:
			if class_weapon_map.has(prof_name):
				var allowed: Array = class_weapon_map[prof_name]
				if not (itype in allowed):
					should_hide = true
			else:
				# Vanilla classes cannot purchase swords or void cores
				if itype in ["sword", "void_core"]:
					should_hide = true

		if should_hide:
			card.visible = false
			card.queue_free()