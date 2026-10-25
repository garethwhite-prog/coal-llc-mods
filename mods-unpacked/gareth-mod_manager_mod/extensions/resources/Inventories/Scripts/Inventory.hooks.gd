extends Object

func initialise_slots(chain: ModLoaderHookChain) -> void:
	var inv = chain.reference_object
	if not is_instance_valid(inv):
		chain.execute_next([])
		return

	var target_slots: int = 10
	if "maxSlots" in inv and inv.maxSlots > 0:
		target_slots = int(inv.maxSlots)

	var empty_res = load("res://resources/Items/Empty.tres")
	var current_size: int = inv.items.size()

	for n in range(current_size, target_slots):
		var empty_slot = InventoryItem.new()
		if empty_res:
			empty_slot.set("item", empty_res)
		empty_slot.count = 0.0
		inv.items.append(empty_slot)
