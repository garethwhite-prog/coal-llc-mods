extends Node

func _ready() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks:
		return

	var target_idx = -1
	for i in range(item_unlocks.all_equipment_items.size()):
		if item_unlocks.all_equipment_items[i] and item_unlocks.all_equipment_items[i].itemID == "mortar_gun_05":
			target_idx = i
			break

	var new_items: Array[Item] = []
	for t in ["06", "07", "08", "09", "10"]:
		var it = load("res://mods-unpacked/gareth-more_mortars_mod/items/mortar_gun_%s.tres" % t)
		if it:
			new_items.append(it)
			if not it in item_unlocks.all_items:
				item_unlocks.all_items.append(it)

	if target_idx != -1:
		for offset in range(new_items.size()):
			item_unlocks.all_equipment_items.insert(target_idx + 1 + offset, new_items[offset])
	else:
		for it in new_items:
			item_unlocks.all_equipment_items.append(it)