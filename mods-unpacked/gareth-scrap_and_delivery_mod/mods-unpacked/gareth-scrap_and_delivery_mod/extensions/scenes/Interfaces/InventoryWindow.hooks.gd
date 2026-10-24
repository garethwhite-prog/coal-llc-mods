extends Object

func load_inventory(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var grid = chain.reference_object
	if is_instance_valid(grid):
		_inject_scrap_bar(grid)

func _inject_scrap_bar(grid: GridContainer) -> void:
	var parent = grid.get_parent()
	if not parent or parent.has_node("DaytimeScrapBar"):
		return

	var bar = HBoxContainer.new()
	bar.name = "DaytimeScrapBar"
	bar.add_theme_constant_override("separation", 10)

	var btn_scrap_ores = Button.new()
	btn_scrap_ores.text = "♻️ Scrap All Ores (50% Cash)"
	btn_scrap_ores.tooltip_text = "Sell all raw ores from your inventory immediately for 50% value straight to your wallet."
	btn_scrap_ores.modulate = Color(0.4, 1.0, 0.6, 1.0)
	btn_scrap_ores.pressed.connect(func(): _scrap_all_ores(grid))
	bar.add_child(btn_scrap_ores)

	var btn_open_amazon = Button.new()
	btn_open_amazon.text = "📦 Open Amazon Store (B)"
	btn_open_amazon.tooltip_text = "Order emergency platforms, ladders, and tools delivered by parachute in 10 seconds."
	btn_open_amazon.modulate = Color(1.0, 0.85, 0.3, 1.0)
	btn_open_amazon.pressed.connect(func():
		var tree = grid.get_tree()
		if tree and tree.root:
			var mgr = tree.root.find_child("AmazonDeliveryManager", true, false)
			if mgr and mgr.has_method("open_store"):
				mgr.open_store()
	)
	bar.add_child(btn_open_amazon)

	parent.add_child(bar)
	parent.move_child(bar, grid.get_index())

func _scrap_all_ores(grid: GridContainer) -> void:
	if not Gvars or not ("inventory" in grid) or not grid.inventory:
		return

	var total_scrapped_cash: float = 0.0
	var total_items_cleared: int = 0
	var empty_res = load("res://resources/Items/Empty.tres")

	for i in range(grid.inventory.items.size()):
		var slot_item = grid.inventory.items[i]
		if not is_instance_valid(slot_item) or not is_instance_valid(slot_item.item) or slot_item.count <= 0:
			continue

		var it = slot_item.item
		var id_str = str(it.itemID).to_lower()
		var type_str = str(it.itemType).to_lower()
		var name_str = str(it.itemName).to_lower()

		var is_ore = (type_str in ["ore", "resource", "mineral", "material"] or 
			"coal" in id_str or "copper" in id_str or "iron" in id_str or "sapphire" in id_str or 
			"emerald" in id_str or "silver" in id_str or "amethyst" in id_str or "gold" in id_str or 
			"ruby" in id_str or "diamond" in id_str or "spinel" in id_str or "uranium" in id_str or 
			"moonstone" in id_str or "onyx" in id_str)

		if is_ore and type_str != "equipment" and type_str != "weapon":
			var unit_val: float = 0.0
			if it.itemSellPrice > 0.0:
				unit_val = it.itemSellPrice * 0.5
			elif it.itemBuyPrice > 0.0:
				unit_val = it.itemBuyPrice * 0.25
			else:
				unit_val = 5.0

			var stack_cash = unit_val * slot_item.count
			total_scrapped_cash += stack_cash
			total_items_cleared += int(slot_item.count)

			slot_item.count = 0
			if empty_res:
				slot_item.item = empty_res

	if total_scrapped_cash > 0.0:
		Gvars.CashCount += total_scrapped_cash
		grid.save_inventory()
		grid.load_inventory()

		var tree = grid.get_tree()
		if tree and tree.root:
			var mgr = tree.root.find_child("AmazonDeliveryManager", true, false)
			if mgr and mgr.has_method("show_toast"):
				mgr.show_toast("♻️ Scrapped %d ores for +$%.2f cash!" % [total_items_cleared, total_scrapped_cash / 100.0])
