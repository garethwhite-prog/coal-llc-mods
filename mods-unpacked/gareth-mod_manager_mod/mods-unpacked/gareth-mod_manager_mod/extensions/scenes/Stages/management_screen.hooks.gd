extends Object

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var screen = chain.reference_object
	if screen:
		Callable(self, "_filter_shop_cards").call_deferred(screen)

func _filter_shop_cards(screen: Node) -> void:
	var prof = Gvars.profession if ("profession" in Gvars and Gvars.profession) else null
	var prof_name: String = prof.name if (prof and "name" in prof) else ""

	if prof_name == "Internship" or prof_name == "":
		if not is_instance_valid(screen):
			return

		var tooltips = screen.find_children("*", "EmployeeShopTooltip", true, false)
		for card in tooltips:
			if "item" in card and card.item:
				var item_name: String = card.item.itemName if ("itemName" in card.item) else ""
				if item_name.contains("Optical Emitter") or item_name.contains("Tectonic Fracker") or item_name.contains("Broadsword") or item_name.contains("Energy Saber"):
					card.visible = false
					card.process_mode = Node.PROCESS_MODE_DISABLED
