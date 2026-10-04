extends Node

func _ready() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks:
		return

	var cleaned: Array[Item] = []
	for it in item_unlocks.all_bonus_items:
		if it and it.itemID.begins_with("AddInventoryStacks") and not it.itemID in ["AddInventoryStacks1", "AddInventoryStacks2", "AddInventoryStacks3", "AddInventoryStacks4", "AddInventoryStacks5", "AddInventoryStacks6"]:
			continue
		cleaned.append(it)
	item_unlocks.all_bonus_items = cleaned

	var target_idx = -1
	for i in range(item_unlocks.all_bonus_items.size()):
		if item_unlocks.all_bonus_items[i] and item_unlocks.all_bonus_items[i].itemID == "AddInventoryStacks6":
			target_idx = i
			break

	var new_items: Array[Item] = []
	for t in range(7, 17):
		var it = load("res://mods-unpacked/gareth-more_inventory_stacks_mod/items/add_inventory_stacks_%d.tres" % t)
		if it:
			new_items.append(it)
			if not it in item_unlocks.all_items:
				item_unlocks.all_items.append(it)

	if target_idx != -1:
		for offset in range(new_items.size()):
			item_unlocks.all_bonus_items.insert(target_idx + 1 + offset, new_items[offset])
	else:
		for it in new_items:
			item_unlocks.all_bonus_items.append(it)