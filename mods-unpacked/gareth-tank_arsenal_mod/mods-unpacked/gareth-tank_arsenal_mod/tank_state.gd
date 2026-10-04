extends Object

static var active_tank_id: String = ""
static var catalog_registered: bool = false

static func get_color_for_id(item_id: String) -> Color:
	if "tank_fire" in item_id:
		return Color(2.0, 0.45, 0.1, 1.0)
	elif "tank_poison" in item_id:
		return Color(0.25, 2.0, 0.35, 1.0)
	elif "tank_uranium" in item_id:
		return Color(0.35, 1.0, 2.2, 1.0)
	return Color.WHITE

static func ensure_catalog_registered() -> void:
	if catalog_registered:
		return

	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks:
		return

	var tiers = [
		"01_shoddy", "02_copper", "03_iron", "04_sapphire", "05_emerald",
		"06_silver", "07_amethyst", "08_gold", "09_ruby", "10_diamond",
		"11_pinkdiamond", "12_spinel", "13_uranium", "14_moonstone", "15_onyx"
	]

	# 1. Strip any previous mod items to guarantee exact order without duplicates
	var cleaned_eq: Array[Item] = []
	for item in item_unlocks.all_equipment_items:
		if item and ("tank_fire" in item.itemID or "tank_poison" in item.itemID or "tank_uranium" in item.itemID):
			continue
		cleaned_eq.append(item)
	item_unlocks.all_equipment_items = cleaned_eq

	# 2. Interleave custom tanks directly beside their vanilla tier counterpart
	for t in tiers:
		var vanilla_id = "tank_" + t
		var target_idx = -1
		for i in range(item_unlocks.all_equipment_items.size()):
			var cur = item_unlocks.all_equipment_items[i]
			if cur and cur.itemID == vanilla_id:
				target_idx = i
				break

		var fire_item = load("res://mods-unpacked/gareth-tank_arsenal_mod/items/tank_fire_%s.tres" % t)
		var poison_item = load("res://mods-unpacked/gareth-tank_arsenal_mod/items/tank_poison_%s.tres" % t)
		var uranium_item = load("res://mods-unpacked/gareth-tank_arsenal_mod/items/tank_uranium_%s.tres" % t)

		var to_insert = [fire_item, poison_item, uranium_item]

		if target_idx != -1:
			for offset in range(to_insert.size()):
				var it = to_insert[offset]
				if it:
					item_unlocks.all_equipment_items.insert(target_idx + 1 + offset, it)
		else:
			for it in to_insert:
				if it:
					item_unlocks.all_equipment_items.append(it)

		for it in to_insert:
			if it and not it in item_unlocks.all_items:
				item_unlocks.all_items.append(it)

	catalog_registered = true
	ModLoaderLog.info("Registered and tier-sorted 45 custom tanks into shop.", "gareth-tank_arsenal_mod")