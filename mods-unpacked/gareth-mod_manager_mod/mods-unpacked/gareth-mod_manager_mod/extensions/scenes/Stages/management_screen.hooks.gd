extends Object

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var screen = chain.reference_object
	if screen:
		Callable(self, "_filter_cards").call_deferred(screen)

func _filter_cards(screen: Node) -> void:
	if not is_instance_valid(screen):
		return

	var all_labels = screen.find_children("*", "Label", true, false)
	for lbl in all_labels:
		var txt = lbl.text
		if ("Tectonic Fracker" in txt) or ("Void Core" in txt) or ("Optical Emitter" in txt) or ("Broadsword" in txt) or ("Energy Saber" in txt) or ("Laser Beam" in txt):
			# Climb to the root card container and disable it
			var card = lbl.get_parent()
			while card and card != screen and card.get_parent() != screen:
				if card.get_parent().name == "EquipmentItems" or card.get_parent() is GridContainer or card.get_parent() is BoxContainer:
					break
				card = card.get_parent()
			
			if card and card != screen:
				card.visible = false
				card.process_mode = Node.PROCESS_MODE_DISABLED
