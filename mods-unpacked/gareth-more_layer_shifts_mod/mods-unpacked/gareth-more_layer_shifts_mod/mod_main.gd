extends Node

func _ready() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks:
		return

	# Remove previous copies to prevent duplicates
	var cleaned: Array[Item] = []
	for it in item_unlocks.all_bonus_items:
		if it and it.itemID.begins_with("shift_layers_") and it.itemID.replace("shift_layers_", "").to_int() >= 6:
			continue
		cleaned.append(it)
	item_unlocks.all_bonus_items = cleaned

	# Find Shift 5 and insert sequentially
	var target_idx = -1
	for i in range(item_unlocks.all_bonus_items.size()):
		if item_unlocks.all_bonus_items[i] and item_unlocks.all_bonus_items[i].itemID == "shift_layers_5":
			target_idx = i
			break

	var new_items: Array[Item] = []
	for t in range(6, 13):
		var it = load("res://mods-unpacked/gareth-more_layer_shifts_mod/items/shift_layers_%d.tres" % t)
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