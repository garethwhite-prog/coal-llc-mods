extends Object

func _on_purchase_button_gui_input(chain: ModLoaderHookChain, event: InputEvent) -> void:
	var card = chain.reference_object
	if not is_instance_valid(card) or not ("item" in card) or not card.item:
		chain.execute_next([event])
		return

	# Prevent division-by-zero when itemBuyPrice is 0g
	if event.is_action_released("rightMouseClick"):
		if card.purchaseable and (Gvars.CashCount >= card.item.itemBuyPrice):
			card.purchase_custom_amount.global_position = card.global_position
			var cost: float = float(card.item.itemBuyPrice)
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
