extends Object

func refreshDetails(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var card = chain.reference_object
	if not is_instance_valid(card) or not ("item" in card) or not card.item:
		return

	# Sanitize NaN cash
	if Gvars and is_nan(Gvars.CashCount):
		Gvars.CashCount = 0.0

	var cost: float = float(card.item.itemBuyPrice)
	if card.purchaseable and (cost <= 0.0 or Gvars.CashCount >= cost):
		if "purchase_button" in card and is_instance_valid(card.purchase_button):
			card.purchase_button.disabled = false

	if Gvars and ("show_only_affordable" in Gvars) and Gvars.show_only_affordable:
		if cost > Gvars.CashCount and cost > 0.0:
			card.visible = false

func _on_purchase_button_pressed(chain: ModLoaderHookChain) -> void:
	var card = chain.reference_object
	if not is_instance_valid(card) or not ("item" in card) or not card.item:
		chain.execute_next([])
		return

	if Gvars and is_nan(Gvars.CashCount):
		Gvars.CashCount = 0.0

	var cost: float = float(card.item.itemBuyPrice)
	if card.purchaseable and (cost <= 0.0 or Gvars.CashCount >= cost):
		if card.item.itemBuyEffect:
			card.item.itemBuyEffect.buy_effect(card.item, 1)
		else:
			var inv: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
			if inv:
				inv.addToInventory(card.item, 1)

		if cost > 0.0:
			Gvars.CashCount = max(0.0, Gvars.CashCount - cost)
		card.refreshDetails()
		card.shop_button_pressed.emit()
		return

	chain.execute_next([])

func _on_purchase_button_gui_input(chain: ModLoaderHookChain, event: InputEvent) -> void:
	var card = chain.reference_object
	if not is_instance_valid(card) or not ("item" in card) or not card.item:
		chain.execute_next([event])
		return

	if Gvars and is_nan(Gvars.CashCount):
		Gvars.CashCount = 0.0

	if event.is_action_released("rightMouseClick"):
		var cost: float = float(card.item.itemBuyPrice)
		if card.purchaseable and (cost <= 0.0 or Gvars.CashCount >= cost):
			card.purchase_custom_amount.global_position = card.global_position
			if cost <= 0.0:
				card.custom_amount.max_value = 1.0
			else:
				card.custom_amount.max_value = max(1.0, floor(Gvars.CashCount / cost))
			card.custom_amount.assign_value(card.last_custom_value)
			card.custom_amount.refresh_all()
			card.custom_amount.visible = true
			card.custom_amount.h_slider.grab_focus()
			return

	chain.execute_next([event])
