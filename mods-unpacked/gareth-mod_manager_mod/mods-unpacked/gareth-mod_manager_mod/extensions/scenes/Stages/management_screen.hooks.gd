extends Object

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	
	var screen = chain.reference_object
	if screen:
		# Run deferred so all weapon mods have finished adding their buttons
		screen.call_deferred("_filter_class_weapons_living_canvas")

func _filter_class_weapons_living_canvas() -> void:
	var prof = Gvars.profession if ("profession" in Gvars and Gvars.profession) else null
	var prof_name: String = prof.name if (prof and "name" in prof) else ""
	
	if prof_name == "Internship" or prof_name == "":
		var tree = Engine.get_main_loop()
		if not tree:
			return
		var root = tree.root
		var shop_items = root.find_children("*", "EmployeeShopTooltip", true, false)
		
		for card in shop_items:
			if "item" in card and card.item:
				var item_name: String = card.item.itemName if ("itemName" in card.item) else ""
				if item_name.contains("Optical Emitter") or item_name.contains("Tectonic Fracker") or item_name.contains("Broadsword") or item_name.contains("Energy Saber"):
					card.visible = false
					card.process_mode = Node.PROCESS_MODE_DISABLED
