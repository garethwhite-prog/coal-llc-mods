extends Object

func load_inventory(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var grid = chain.reference_object
	if is_instance_valid(grid):
		_inject_scrap_bar(grid)

func _inject_scrap_bar(grid: GridContainer) -> void:
	# Hide buttons if we are in the between-day store (ManagementScreen / TabContainer)
	var scene = grid.get_tree().current_scene
	if scene and (scene.name == "ManagementScreen" or scene.name == "management_screen"):
		return
	if grid.find_parent("ManagementScreen") or grid.find_parent("TabContainer"):
		return

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
	var inv: Inventory = grid.inventory
	var ore_rates = {
		"Coal": 1.0,
		"Copper": 2.5,
		"Iron": 5.0,
		"Silver": 12.0,
		"Gold": 25.0,
		"Amethyst": 45.0,
		"Sapphire": 80.0,
		"Emerald": 130.0,
		"Ruby": 200.0,
		"Diamond": 350.0
	}

	for slot in inv.items:
		if slot and slot.item and slot.count > 0:
			var iname = str(slot.item.itemName)
			if ore_rates.has(iname):
				var cash_gain = float(slot.count) * ore_rates[iname] * 0.5
				total_scrapped_cash += cash_gain
				slot.count = 0.0
				var empty_res = load("res://resources/Items/Empty.tres")
				if empty_res:
					slot.set("item", empty_res)

	if total_scrapped_cash > 0.0:
		Gvars.CashCount += total_scrapped_cash
		Bus.inventory_changed.emit()
