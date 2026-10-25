extends Object

func get_max_count(chain: ModLoaderHookChain, price: float, count: float) -> float:
	if price <= 0.0:
		return count
	if Gvars and is_nan(Gvars.CashCount):
		Gvars.CashCount = 0.0
	if Gvars and Gvars.CashCount <= 0.0:
		return 0.0
	var _max = floor(Gvars.CashCount / price)
	return min(_max, count)

func buy_effect(chain: ModLoaderHookChain, shop_item: Item, count: int) -> void:
	if not shop_item:
		chain.execute_next([shop_item, count])
		return

	if Gvars and is_nan(Gvars.CashCount):
		Gvars.CashCount = 0.0

	var price: float = float(shop_item.itemBuyPrice)
	# 0g starter items bypass wallet deduction cleanly
	if price <= 0.0:
		var inventory: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
		if inventory:
			inventory.addToInventory(shop_item, count)
			inventory.emit_signal("inventory_changed")
			Bus.inventory_changed.emit()
		return

	# Pass exact vanilla signature: [Item, int]
	chain.execute_next([shop_item, count])
