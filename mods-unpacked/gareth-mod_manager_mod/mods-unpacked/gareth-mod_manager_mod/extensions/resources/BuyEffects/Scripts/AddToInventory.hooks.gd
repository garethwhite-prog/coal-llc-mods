extends Object

func buy_effect(chain: ModLoaderHookChain, shop_item: Item, count: int) -> void:
	if not shop_item:
		chain.execute_next([shop_item, count])
		return

	if Gvars and is_nan(Gvars.CashCount):
		Gvars.CashCount = 0.0

	var price: float = float(shop_item.itemBuyPrice)
	if price <= 0.0:
		var inventory: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
		if inventory:
			inventory.addToInventory(shop_item, count)
			inventory.emit_signal("inventory_changed")
			Bus.inventory_changed.emit()
		return

	chain.execute_next([shop_item, count])

func get_max_count(chain: ModLoaderHookChain, price: float, count: float) -> float:
	if price <= 0.0:
		return count
	if Gvars and is_nan(Gvars.CashCount):
		Gvars.CashCount = 0.0
	return chain.execute_next([price, count])
