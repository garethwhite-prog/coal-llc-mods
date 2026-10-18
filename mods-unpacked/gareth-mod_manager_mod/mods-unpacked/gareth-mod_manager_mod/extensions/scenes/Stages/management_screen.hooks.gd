extends Object

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var screen = chain.reference_object
	if screen:
		Callable(self, "_filter_cards").call_deferred(screen)

func _filter_cards(screen: Node) -> void:
	if not is_instance_valid(screen):
		return

	var prof = Gvars.profession if ("profession" in Gvars and Gvars.profession) else null
	var prof_name: String = prof.name if (prof and "name" in prof) else ""

	if prof_name == "Internship" or prof_name == "":
		var container = null
		if "equipment_items" in screen and screen.equipment_items:
			container = screen.equipment_items
		else:
			for c in screen.find_children("*", "GridContainer", true, false):
				container = c
				break

		if container:
			for card in container.get_children():
				var txt: String = ""
				for lbl in card.find_children("*", "Label", true, false):
					txt += " " + lbl.text
				if "item" in card and card.item and "itemName" in card.item:
					txt += " " + str(card.item.itemName)

				if txt.contains("Optical Emitter") or txt.contains("Tectonic Fracker") or txt.contains("Broadsword") or txt.contains("Energy Saber"):
					card.visible = false
					card.process_mode = Node.PROCESS_MODE_DISABLED
