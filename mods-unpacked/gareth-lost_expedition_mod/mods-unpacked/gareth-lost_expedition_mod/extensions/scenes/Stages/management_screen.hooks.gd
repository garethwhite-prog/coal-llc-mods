extends Object

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	if Gvars.level == 101:
		var ms = chain.reference_object
		if ms and "equipment_shop" in ms and ms.equipment_shop:
			var allowed := ["pickaxe", "item_filter", "increase_stack_size", "ladder", "whistle", "collector_whistle", "mining_whistle"]
			for card in ms.equipment_shop.get_children():
				if "item" in card and card.item:
					var itype: String = str(card.item.itemType).to_lower()
					if not allowed.has(itype):
						card.visible = false
