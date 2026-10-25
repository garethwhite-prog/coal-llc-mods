extends Object

var bonus_search: LineEdit = null
var bonus_sort: OptionButton = null
var bonus_chk_afford: CheckBox = null
var is_bonus_affordable_only: bool = false

func refresh(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var panel = chain.reference_object
	if not is_instance_valid(panel):
		return

	_ensure_filter_bar(panel)
	_apply_bonus_filter(panel)

func _ensure_filter_bar(panel: Control) -> void:
	var scroll = panel.get_parent()
	var v_box = scroll.get_parent() if scroll else null
	if not v_box:
		return

	if v_box.has_node("BonusFilterBar"):
		var existing = v_box.get_node("BonusFilterBar")
		bonus_search = existing.get_node_or_null("BonusSearch")
		bonus_sort = existing.get_node_or_null("BonusSort")
		bonus_chk_afford = existing.get_node_or_null("BonusAfford")
		return

	var bar = HBoxContainer.new()
	bar.name = "BonusFilterBar"
	bar.add_theme_constant_override("separation", 10)

	var search = LineEdit.new()
	search.name = "BonusSearch"
	search.placeholder_text = "Search bonus upgrades..."
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.clear_button_enabled = true
	search.text_changed.connect(func(_t): _apply_bonus_filter(panel))
	bar.add_child(search)
	bonus_search = search

	var sort_btn = OptionButton.new()
	sort_btn.name = "BonusSort"
	sort_btn.add_item("Sort: Default", 0)
	sort_btn.add_item("Name: A-Z", 1)
	sort_btn.item_selected.connect(func(_idx): _apply_bonus_filter(panel))
	bar.add_child(sort_btn)
	bonus_sort = sort_btn

	var chk = CheckBox.new()
	chk.name = "BonusAfford"
	chk.text = "Affordable Only"
	chk.tooltip_text = "Show only upgrades you can purchase right now."
	chk.toggled.connect(func(pressed: bool):
		is_bonus_affordable_only = pressed
		_apply_bonus_filter(panel)
	)
	bar.add_child(chk)
	bonus_chk_afford = chk

	v_box.add_child(bar)
	v_box.move_child(bar, scroll.get_index())

func _apply_bonus_filter(panel: Control) -> void:
	if not is_instance_valid(panel) or not is_instance_valid(bonus_search):
		return
	var q: String = bonus_search.text.strip_edges().to_lower()
	var cur_cash: float = Gvars.CashCount if Gvars else 0.0

	for item in panel.get_children():
		if not is_instance_valid(item):
			continue
		var label = item.find_child("*Label*", true, false)
		var text: String = label.text.to_lower() if (label and "text" in label) else ""
		var match_q: bool = q.is_empty() or q in text

		var cost: float = 0.0
		if "cost" in item:
			cost = float(item.cost)
		elif "price" in item:
			cost = float(item.price)

		var match_afford: bool = not is_bonus_affordable_only or (cost <= cur_cash or cost <= 0.0)
		item.visible = match_q and match_afford
