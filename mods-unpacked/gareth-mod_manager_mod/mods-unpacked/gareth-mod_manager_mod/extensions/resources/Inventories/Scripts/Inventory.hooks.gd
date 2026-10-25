extends Object

func initialise_slots(chain: ModLoaderHookChain) -> void:
	var inv = chain.reference_object
	if not is_instance_valid(inv) or inv.maxSlots == -1:
		chain.execute_next([])
		return

	var current_size = inv.items.size()
	var empty_res = load("res://resources/Items/Empty.tres")
	for n in range(current_size, int(inv.maxSlots)):
		var empty_slot = InventoryItem.new()
		if empty_res:
			empty_slot.set("item", empty_res)
		empty_slot.count = 0
		inv.items.append(empty_slot)
