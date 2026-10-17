extends Object

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	if Gvars.level == 101:
		var ms = chain.reference_object
		if not ms:
			return
		var all_items = ms.find_children("", "Control", true, false)
		var allowed_types := ["pickaxe", "item_filter", "increase_stack_size", "ladder", "whistle", "collector_whistle", "mining_whistle"]
		for child in all_items:
			if "item" in child and child.item:
				var itype: String = str(child.item.itemType)
				if not allowed_types.has(itype):
					child.visible = false
