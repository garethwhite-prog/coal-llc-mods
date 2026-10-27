class_name ModStoreView
extends Control

var http_req: HTTPRequest
var cards_vbox: VBoxContainer
var search_edit: LineEdit
var cat_dropdown: OptionButton
var status_lbl: Label
var all_releases: Array = []

const REPO_API := "https://api.github.com/repos/garethwhite-prog/coal-llc-mods/releases"

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 120

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.09, 0.11, 0.98)
	add_child(bg)

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("margin_left", 32)
	main_vbox.add_theme_constant_override("margin_top", 24)
	main_vbox.add_theme_constant_override("margin_right", 32)
	main_vbox.add_theme_constant_override("margin_bottom", 24)
	add_child(main_vbox)

	# 1. Header Bar
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	main_vbox.add_child(header)

	var btn_back = Button.new()
	btn_back.text = " < Back to Mod Manager "
	btn_back.custom_minimum_size = Vector2(180, 36)
	btn_back.pressed.connect(queue_free)
	header.add_child(btn_back)

	var title = Label.new()
	title.text = "COAL LLC MOD & MAP STORE — COMMUNITY REPOSITORY"
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color(1.0, 0.85, 0.3)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var btn_refresh = Button.new()
	btn_refresh.text = " 🔄 Refresh Catalog "
	btn_refresh.custom_minimum_size = Vector2(150, 36)
	btn_refresh.pressed.connect(_fetch_releases)
	header.add_child(btn_refresh)

	main_vbox.add_child(HSeparator.new())

	# 2. Filter Bar
	var filter_bar = HBoxContainer.new()
	filter_bar.add_theme_constant_override("separation", 12)
	main_vbox.add_child(filter_bar)

	search_edit = LineEdit.new()
	search_edit.placeholder_text = "Search store packages, weapon arsenals, map strata, classes..."
	search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_edit.clear_button_enabled = true
	search_edit.text_changed.connect(func(_t): _render_cards())
	filter_bar.add_child(search_edit)

	cat_dropdown = OptionButton.new()
	cat_dropdown.add_item("All Categories", 0)
	cat_dropdown.add_item("Custom Maps & Strata", 1)
	cat_dropdown.add_item("Classes & Professions", 2)
	cat_dropdown.add_item("Weapons & Arsenal", 3)
	cat_dropdown.add_item("Employees & Automation", 4)
	cat_dropdown.add_item("Quality of Life", 5)
	cat_dropdown.item_selected.connect(func(_idx): _render_cards())
	filter_bar.add_child(cat_dropdown)

	status_lbl = Label.new()
	status_lbl.text = "Connecting to repository..."
	status_lbl.modulate = Color(0.7, 0.7, 0.7)
	main_vbox.add_child(status_lbl)

	# 3. Scrollable Card View
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	cards_vbox = VBoxContainer.new()
	cards_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(cards_vbox)

	# 4. HTTP Request Setup
	http_req = HTTPRequest.new()
	http_req.timeout = 10.0
	http_req.request_completed.connect(_on_request_completed)
	add_child(http_req)

	_fetch_releases()

func _fetch_releases() -> void:
	status_lbl.text = "Fetching releases from GitHub..."
	status_lbl.modulate = Color(1.0, 0.85, 0.3)
	var headers := ["User-Agent: CoalLLC-ModStore/1.0"]
	http_req.request(REPO_API, headers, HTTPClient.METHOD_GET)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		status_lbl.text = "Online repository unreachable. Displaying cached local catalog."
		status_lbl.modulate = Color(1.0, 0.4, 0.4)
		_build_fallback_catalog()
		_render_cards()
		return

	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if parsed is Array:
		all_releases = parsed
		status_lbl.text = "Catalog loaded: %d release packages found." % all_releases.size()
		status_lbl.modulate = Color(0.4, 1.0, 0.6)
	else:
		_build_fallback_catalog()

	_render_cards()

func _build_fallback_catalog() -> void:
	all_releases = [
		{"name": "Custom Map Pack (101-105)", "tag_name": "v1.4.0", "body": "Permanent strata package containing Lost Expedition, Faultline, Living Canvas, Abyssal Trench, and Diagonal Seams.", "category": "Custom Maps & Strata"},
		{"name": "Knight & Martial Classes Suite", "tag_name": "v1.3.2", "body": "Adds Knight class with Broadsword, Martial Artist with shockwave kicks, and custom starter gear.", "category": "Classes & Professions"},
		{"name": "Elemental Airstrikes & B-52 Bomber", "tag_name": "v1.2.0", "body": "Single-use tactical airstrike radios: Dragon firebomber, Water deluge, Agent Orange defoliant, and B-52 Carpet Bomber.", "category": "Weapons & Arsenal"},
		{"name": "Scrap & Same-Day Parachute Delivery", "tag_name": "v1.1.5", "body": "Recycle raw ore mid-mine for emergency cash and order platforms or ladders delivered by Amazon drone.", "category": "Quality of Life"},
		{"name": "Collector UFO Retrieval Priority", "tag_name": "v1.0.8", "body": "Enables smart retrieval routines for automated UFOs: closest, highest value gems, or quota priority.", "category": "Employees & Automation"}
	]

func _render_cards() -> void:
	for child in cards_vbox.get_children():
		child.queue_free()

	var query: String = search_edit.text.strip_edges().to_lower()
	var selected_cat: int = cat_dropdown.selected

	for rel in all_releases:
		var pkg_name: String = str(rel.get("name", "Unknown Package"))
		var pkg_tag: String = str(rel.get("tag_name", "v1.0.0"))
		var pkg_desc: String = str(rel.get("body", "No description provided."))
		var pkg_cat: String = str(rel.get("category", "General Mod"))

		if not query.is_empty() and not (query in pkg_name.to_lower() or query in pkg_desc.to_lower()):
			continue
		if selected_cat > 0:
			var cat_name: String = cat_dropdown.get_item_text(selected_cat)
			if pkg_cat != cat_name:
				continue

		var card = PanelContainer.new()
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 16)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_right", 16)
		margin.add_theme_constant_override("margin_bottom", 10)
		card.add_child(margin)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 16)
		margin.add_child(hbox)

		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var title_lbl = RichTextLabel.new()
		title_lbl.bbcode_enabled = true
		title_lbl.text = "[b][font_size=15]%s[/font_size][/b]  [color=#4ade80]%s[/color]  [color=#fbbf24][%s][/color]" % [pkg_name, pkg_tag, pkg_cat]
		title_lbl.fit_content = true
		info_vbox.add_child(title_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = pkg_desc
		desc_lbl.modulate = Color(0.75, 0.75, 0.75)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_vbox.add_child(desc_lbl)

		hbox.add_child(info_vbox)

		var btn_action = Button.new()
		btn_action.text = " Installed "
		btn_action.custom_minimum_size = Vector2(130, 36)
		btn_action.disabled = true
		btn_action.modulate = Color(0.5, 0.9, 0.5)
		hbox.add_child(btn_action)

		cards_vbox.add_child(card)
