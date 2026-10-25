extends Object

var search_input: LineEdit = null
var sort_dropdown: OptionButton = null
var chk_affordable: CheckBox = null
var is_affordable_only: bool = false

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	var screen = chain.reference_object
	if is_instance_valid(screen):
		if Gvars and is_nan(Gvars.CashCount):
			Gvars.CashCount = 0.0
		_ensure_search_and_sort_bar(screen)
		_sort_equipment_catalog()

	chain.execute_next([])

	if is_instance_valid(screen):
		Callable(self, "_apply_filter").call_deferred(screen)

func _ensure_search_and_sort_bar(screen: Node) -> void:
	if not is_instance_valid(screen):
		return
	var shop = screen.find_child("EquipmentShop", true, false)
	if not shop:
		return

	var scroll = shop.get_parent()
	var v_box = scroll.get_parent() if scroll else null
	if not v_box:
		return

	if v_box.has_node("EquipmentFilterBar"):
		var existing_bar = v_box.get_node("EquipmentFilterBar")
		search_input = existing_bar.get_node_or_null("SearchInput")
		sort_dropdown = existing_bar.get_node_or_null("SortOption")
		chk_affordable = existing_bar.get_node_or_null("AffordableOnly")
		return

	var bar = HBoxContainer.new()
	bar.name = "EquipmentFilterBar"
	bar.add_theme_constant_override("separation", 12)

	var search = LineEdit.new()
	search.name = "SearchInput"
	search.placeholder_text = "Search equipment by name or type..."
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.clear_button_enabled = true
	search.text_changed.connect(func(_new_text): _apply_filter(screen))
	bar.add_child(search)
	search_input = search

	var sort_btn = OptionButton.new()
	sort_btn.name = "SortOption"
	sort_btn.add_item("Sort: Tier (Default)", 0)
	sort_btn.add_item("Sort: Price (Low to High)", 1)
	sort_btn.add_item("Sort: Price (High to Low)", 2)
	sort_btn.add_item("Sort: Alphabetical (A-Z)", 3)
	sort_btn.item_selected.connect(func(_idx):
		_sort_equipment_catalog()
		if screen.has_method("load_equipment_shop"):
			screen.load_equipment_shop()
	)
	bar.add_child(sort_btn)
	sort_dropdown = sort_btn

	var chk = CheckBox.new()
	chk.name = "AffordableOnly"
	chk.text = "Affordable Only"
	chk.tooltip_text = "Show only items you can afford with your current cash."
	chk.toggled.connect(func(pressed: bool):
		is_affordable_only = pressed
		_apply_filter(screen)
	)
	bar.add_child(chk)
	chk_affordable = chk

	v_box.add_child(bar)
	v_box.move_child(bar, scroll.get_index())

func _sort_equipment_catalog() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks or not ("all_equipment_items" in item_unlocks):
		return

	var mode: int = sort_dropdown.selected if is_instance_valid(sort_dropdown) else 0
	if mode == 1:
		item_unlocks.all_equipment_items.sort_custom(func(a, b): return a.itemBuyPrice < b.itemBuyPrice)
	elif mode == 2:
		item_unlocks.all_equipment_items.sort_custom(func(a, b): return a.itemBuyPrice > b.itemBuyPrice)
	elif mode == 3:
		item_unlocks.all_equipment_items.sort_custom(func(a, b): return str(a.itemName).nocasecmp_to(str(b.itemName)) < 0)

func _apply_filter(screen: Node) -> void:
	if not is_instance_valid(screen) or not is_instance_valid(search_input):
		return
	var query: String = search_input.text.strip_edges().to_lower()
	var cur_cash: float = Gvars.CashCount if Gvars else 0.0

	var shop = screen.find_child("EquipmentShop", true, false)
	if not shop:
		return

	for card in shop.find_children("*", "PanelContainer", true, false):
		if not is_instance_valid(card) or not ("item" in card) or not card.item:
			continue
		var it = card.item
		var it_name: String = str(it.itemName).to_lower()
		var it_id: String = str(it.itemID).to_lower()
		var it_type: String = str(it.itemType).to_lower()

		var match_query: bool = query.is_empty() or query in it_name or query in it_id or query in it_type
		var match_afford: bool = not is_affordable_only or (it.itemBuyPrice <= cur_cash or it.itemBuyPrice <= 0.0)

		card.visible = match_query and match_afford
