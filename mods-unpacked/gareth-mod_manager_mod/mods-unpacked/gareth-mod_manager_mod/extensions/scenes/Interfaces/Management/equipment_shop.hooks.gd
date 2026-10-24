extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var shop = chain.reference_object
	if not is_instance_valid(shop):
		return

	var bar = shop.find_child("HBoxContainer", true, false)
	if not bar:
		bar = shop.find_child("SortContainer", true, false)

	if bar and not bar.has_node("CheckAffordable"):
		var chk = CheckBox.new()
		chk.name = "CheckAffordable"
		chk.text = "Affordable Only"
		chk.tooltip_text = "Hide items that exceed your current wallet balance."
		chk.toggled.connect(func(pressed: bool):
			Gvars.show_only_affordable = pressed
			if shop.has_method("refresh_shop"):
				shop.refresh_shop()
			else:
				for card in shop.find_children("*", "PanelContainer", true, false):
					if card.has_method("refreshDetails"):
						card.refreshDetails()
		)
		bar.add_child(chk)
