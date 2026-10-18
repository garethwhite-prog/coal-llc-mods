extends Object

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	
	# After loading shop, filter out weapons that do not belong to current profession
	var screen = chain.reference_object
	if screen and "equipment_items" in screen and screen.equipment_items:
		var prof = Gvars.profession if ("profession" in Gvars and Gvars.profession) else null
		var prof_name = prof.name if (prof and "name" in prof) else ""
		
		# For Internship, hide custom class weapons like Optical Emitter and Tectonic Fracker
		if prof_name == "Internship" or prof_name == "":
			for item_card in screen.equipment_items.get_children():
				if "item" in item_card and item_card.item:
					var i_name = item_card.item.itemName if "itemName" in item_card.item else ""
					if i_name.contains("Optical Emitter") or i_name.contains("Tectonic Fracker") or i_name.contains("Broadsword"):
						item_card.visible = false
