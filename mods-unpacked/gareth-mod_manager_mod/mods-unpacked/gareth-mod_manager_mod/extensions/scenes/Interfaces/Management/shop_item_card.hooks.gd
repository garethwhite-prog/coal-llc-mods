extends Object

func refreshDetails(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var card = chain.reference_object
	if not is_instance_valid(card) or not ("item" in card) or not card.item:
		return

	if Gvars and is_nan(Gvars.CashCount):
		Gvars.CashCount = 0.0

	var cost: float = float(card.item.itemBuyPrice)
	if card.purchaseable and (cost <= 0.0 or Gvars.CashCount >= cost):
		if "purchase_button" in card and is_instance_valid(card.purchase_button):
			card.purchase_button.disabled = false

func _on_purchase_button_pressed(chain: ModLoaderHookChain) -> void:
	var card = chain.reference_object
	if not is_instance_valid(card) or not ("item" in card) or not card.item:
		chain.execute_next([])
		return

	if Gvars and is_nan(Gvars.CashCount):
		Gvars.CashCount = 0.0

	var cost: float = float(card.item.itemBuyPrice)
	# For free 0g items, trigger buy effect directly
	if cost <= 0.0:
		if card.item.itemBuyEffect:
			card.item.itemBuyEffect.buy_effect(card.item, 1)
		card.refreshDetails()
		card.shop_button_pressed.emit()
		return

	# For regular items, let vanilla buy_effect perform the single deduction
	chain.execute_next([])
