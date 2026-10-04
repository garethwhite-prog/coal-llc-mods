extends Node

func _ready() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks:
		return
	var item = load("res://mods-unpacked/gareth-neutron_bomb_mod/items/neutron_bomb.tres")
	if item:
		var target_idx = -1
		for i in range(item_unlocks.all_equipment_items.size()):
			if item_unlocks.all_equipment_items[i] and item_unlocks.all_equipment_items[i].itemID == "tactical_nuke":
				target_idx = i
				break
		if target_idx != -1 and not item in item_unlocks.all_equipment_items:
			item_unlocks.all_equipment_items.insert(target_idx + 2, item)
		elif not item in item_unlocks.all_equipment_items:
			item_unlocks.all_equipment_items.append(item)
		if not item in item_unlocks.all_items:
			item_unlocks.all_items.append(item)