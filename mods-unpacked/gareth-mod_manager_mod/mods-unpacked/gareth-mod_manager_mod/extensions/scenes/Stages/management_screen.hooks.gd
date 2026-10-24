extends Object

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var screen = chain.reference_object
	if not is_instance_valid(screen):
		return

	# Heal NaN cash upon entering management screen
	if Gvars and is_nan(Gvars.CashCount):
		Gvars.CashCount = 0.0
	if "cash" in screen and is_instance_valid(screen.cash):
		screen.cash.text = "Cash: %s" % Gconsts.add_comma_to_int(Gvars.CashCount)

	var shop_root = screen.find_child("EquipmentShop", true, false)
	if not shop_root:
		shop_root = screen.find_child("PurchaseEquipment", true, false)
	if not shop_root:
		shop_root = screen

	var search_bar = shop_root.find_child("SearchContainer", true, false)
	if not search_bar:
		search_bar = shop_root.find_child("HBoxContainer", true, false)

	if search_bar and not search_bar.has_node("AffordableCheck"):
		var chk := CheckBox.new()
		chk.name = "AffordableCheck"
		chk.text = "Affordable Only"
		chk.tooltip_text = "Show only items you can afford with current cash."
		chk.toggled.connect(func(pressed: bool):
			Gvars.show_only_affordable = pressed
			for card in shop_root.find_children("*", "PanelContainer", true, false):
				if card.has_method("refreshDetails"):
					card.refreshDetails()
		)
		search_bar.add_child(chk)
