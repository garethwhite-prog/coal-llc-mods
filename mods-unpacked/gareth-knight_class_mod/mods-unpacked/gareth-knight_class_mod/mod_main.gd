extends Node

func _ready() -> void:
	# Inject swords into item_unlocks.tres
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if item_unlocks:
		for id_str in ["01_shoddy", "02_copper", "03_iron", "04_sapphire", "05_emerald", "06_silver", "07_amethyst", "08_gold", "09_ruby", "10_diamond", "11_pinkdiamond"]:
			var path := "res://mods-unpacked/gareth-knight_class_mod/items/KnightSword_%s.tres" % id_str
			if ResourceLoader.exists(path):
				var res = load(path)
				if res and not (res in item_unlocks.all_equipment_items):
					item_unlocks.all_equipment_items.append(res)
				if res and not (res in item_unlocks.all_items):
					item_unlocks.all_items.append(res)

	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return

	var pm = Gvars.profession_manager
	var prof_script = load("res://mods-unpacked/gareth-knight_class_mod/scripts/knight_profession.gd")
	var p = prof_script.new()
	p.profession_name = "Knight"
	p.description = "Master of chivalric blade combat.\nStarts with a Shoddy Sword.\nOnly swords and basic mining equipment are purchasable in the shop."
	if ResourceLoader.exists("res://assets/Equipment/Sword-Shoddy.png"):
		p.image = load("res://assets/Equipment/Sword-Shoddy.png")

	pm.all_professions[101] = { "profession": p, "is_unlocked": true }
	ModLoaderLog.info("Knight Class (ID 101) registered cleanly with direct class instantiation.", "gareth-knight_class_mod")