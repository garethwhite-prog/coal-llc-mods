extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var settings = chain.reference_object
	if not is_instance_valid(settings) or not ("tab_container" in settings):
		return

	var tc = settings.tab_container
	if tc.has_node("CollectorPriorityTab"):
		return

	var tab = PanelContainer.new()
	tab.name = "CollectorPriorityTab"

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	tab.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Collector UFO Retrieval Priority"
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(1.0, 0.85, 0.3)
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = "Choose how automated Collector UFOs prioritize dropped items on the mine floor."
	desc.modulate = Color(0.8, 0.8, 0.8)
	vbox.add_child(desc)

	var opt = OptionButton.new()
	opt.add_item("Closest Ore First (Vanilla Default)", 0)
	opt.add_item("Most Valuable First (Gems & High Tier > Coal)", 1)
	opt.add_item("Quota Priority (Coal First for Day Target)", 2)

	var cur_mode: int = 1
	if Gvars and ("collector_priority_mode" in Gvars):
		cur_mode = int(Gvars.collector_priority_mode)
	opt.selected = cur_mode

	opt.item_selected.connect(func(idx: int):
		if Gvars:
			Gvars.collector_priority_mode = idx
	)
	vbox.add_child(opt)

	tc.add_child(tab)
