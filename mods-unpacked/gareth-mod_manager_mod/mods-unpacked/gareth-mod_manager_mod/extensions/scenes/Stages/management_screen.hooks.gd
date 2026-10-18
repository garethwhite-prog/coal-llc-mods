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
	var prof_name: String = ""
	if prof:
		if "profession_name" in prof:
			prof_name = str(prof.profession_name)
		elif "title" in prof:
			prof_name = str(prof.title)
		elif "name" in prof:
			prof_name = str(prof.name)

	# When playing Internship or no custom class, hide all modded class weapons
	if prof_name == "Internship" or prof_name == "" or prof_name.begins_with("@"):
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

				# Use GDScript 'in' operator to avoid .contains() parse errors
				var is_mod_weapon: bool = (
					("Tectonic Fracker" in txt) or
					("Void Core" in txt) or
					("Optical Emitter" in txt) or
					("Broadsword" in txt) or
					("Energy Saber" in txt) or
					("Laser Beam" in txt)
				)

				if is_mod_weapon:
					card.visible = false
					card.process_mode = Node.PROCESS_MODE_DISABLED
