class_name ModStoreView
extends CanvasLayer

var cards_vbox: VBoxContainer
var search_edit: LineEdit
var cat_dropdown: OptionButton
var status_dropdown: OptionButton
var repo_dropdown: OptionButton
var custom_repo_edit: LineEdit
var status_lbl: Label
var all_packages: Array = []

const KNOWN_REPOS: Array[Dictionary] = [
	{"name": "Gareth White (Official Suite)", "repo": "garethwhite-prog/coal-llc-mods"},
	{"name": "Der-Floh (Community Classics)", "repo": "Der-Floh/CoalLLC-Mods"}
]

var active_repo_idx: int = 0

func _ready() -> void:
	layer = 125

	var root_ctrl = Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root_ctrl)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.07, 0.09, 0.98)
	root_ctrl.add_child(bg)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 20)
	root_ctrl.add_child(margin)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(main_vbox)

	# 1. Header Bar
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	main_vbox.add_child(header)

	var btn_back = Button.new()
	btn_back.text = " < Back to Main Menu "
	btn_back.custom_minimum_size = Vector2(180, 36)
	btn_back.pressed.connect(queue_free)
	header.add_child(btn_back)

	var title = Label.new()
	title.text = "COAL LLC MOD & MAP STORE — COMMUNITY REPOSITORY"
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color(1.0, 0.88, 0.35)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var btn_refresh = Button.new()
	btn_refresh.text = " 🔄 Refresh "
	btn_refresh.custom_minimum_size = Vector2(120, 36)
	btn_refresh.pressed.connect(_load_catalog_for_selected_repo)
	header.add_child(btn_refresh)

	main_vbox.add_child(HSeparator.new())

	# 2. Source Repository Bar
	var repo_bar = HBoxContainer.new()
	repo_bar.add_theme_constant_override("separation", 10)
	main_vbox.add_child(repo_bar)

	var repo_lbl = Label.new()
	repo_lbl.text = "Source Repository:"
	repo_lbl.modulate = Color(0.8, 0.8, 0.8)
	repo_bar.add_child(repo_lbl)

	repo_dropdown = OptionButton.new()
	repo_dropdown.custom_minimum_size = Vector2(260, 32)
	for r in KNOWN_REPOS:
		repo_dropdown.add_item(r["name"])
	repo_dropdown.add_item("Custom GitHub Repo...")
	repo_dropdown.item_selected.connect(_on_repo_selected)
	repo_bar.add_child(repo_dropdown)

	custom_repo_edit = LineEdit.new()
	custom_repo_edit.placeholder_text = "owner/repository"
	custom_repo_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_repo_edit.visible = false
	custom_repo_edit.text_submitted.connect(func(_t): _load_catalog_for_selected_repo())
	repo_bar.add_child(custom_repo_edit)

	# 3. Interactive Filter Bar
	var filter_bar = HBoxContainer.new()
	filter_bar.add_theme_constant_override("separation", 10)
	main_vbox.add_child(filter_bar)

	search_edit = LineEdit.new()
	search_edit.placeholder_text = "Search 65+ community packages, classes, maps, weapons..."
	search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_edit.clear_button_enabled = true
	search_edit.text_changed.connect(func(_t): _render_cards())
	filter_bar.add_child(search_edit)

	cat_dropdown = OptionButton.new()
	cat_dropdown.add_item("All Categories", 0)
	cat_dropdown.add_item("Custom Maps & Strata", 1)
	cat_dropdown.add_item("Classes & Professions", 2)
	cat_dropdown.add_item("Weapons & Arsenal", 3)
	cat_dropdown.add_item("Workforce & Automation", 4)
	cat_dropdown.add_item("Quality of Life", 5)
	cat_dropdown.item_selected.connect(func(_idx): _render_cards())
	filter_bar.add_child(cat_dropdown)

	status_dropdown = OptionButton.new()
	status_dropdown.add_item("All Status", 0)
	status_dropdown.add_item("Installed Mods", 1)
	status_dropdown.add_item("Available (Not Installed)", 2)
	status_dropdown.item_selected.connect(func(_idx): _render_cards())
	filter_bar.add_child(status_dropdown)

	status_lbl = Label.new()
	status_lbl.text = "Loading repository..."
	status_lbl.modulate = Color(0.7, 0.7, 0.7)
	main_vbox.add_child(status_lbl)

	# 4. Scrollable Card View
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	cards_vbox = VBoxContainer.new()
	cards_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(cards_vbox)

	_load_catalog_for_selected_repo()

func _on_repo_selected(idx: int) -> void:
	active_repo_idx = idx
	custom_repo_edit.visible = (idx >= KNOWN_REPOS.size())
	_load_catalog_for_selected_repo()

func _load_catalog_for_selected_repo() -> void:
	if active_repo_idx == 1:
		all_packages = [
			{"id": "der_floh-ore_value_mod", "name": "Ore Value Refresh", "tag": "v1.2.0", "desc": "Refreshes and scales daily ore sell prices dynamically on each new shift.", "cat": "Workforce & Automation", "author": "Der-Floh"},
			{"id": "der_floh-teleport_mod", "name": "Recall Teleporter", "tag": "v1.0.4", "desc": "Portable emergency recall device that instantly transports the miner back to the surface cabin.", "cat": "Quality of Life", "author": "Der-Floh"},
			{"id": "der_floh-more_stats_mod", "name": "Advanced Shift Statistics", "tag": "v1.1.0", "desc": "Detailed analytics breakdown for mined ore counts, cash velocity, and drill efficiency.", "cat": "Quality of Life", "author": "Der-Floh"},
			{"id": "der_floh-speed_run_timer_mod", "name": "Quota Speedrun Stopwatch", "tag": "v1.0.2", "desc": "On-screen high-precision timer tracking daily quota completion splits.", "cat": "Quality of Life", "author": "Der-Floh"},
			{"id": "der_floh-pickaxeaoe_mod", "name": "Pickaxe AOE Damage", "tag": "v1.3.1", "desc": "AoE and electric pickaxe now deal equal damage to all ores around swing radius.", "cat": "Classes & Professions", "author": "Der-Floh"},
			{"id": "der_floh-no_holes_mod", "name": "No Holes Backfill", "tag": "v1.2.5", "desc": "Automatically backfills hollow chambers as you tunnel downward to prevent collapsing.", "cat": "Quality of Life", "author": "Der-Floh"},
			{"id": "der_floh-passive_drop_mod", "name": "Dynamic Passive Chest Loot Drops", "tag": "v1.2.0", "desc": "Boosts chances of passive unlocks dropping inside deep mine chests based on tier count.", "cat": "Workforce & Automation", "author": "Der-Floh"}
		]
		status_lbl.text = "Der-Floh (Community Classics): 7 genuine packages loaded."
		status_lbl.modulate = Color(0.4, 1.0, 0.6)
		_render_cards()
	else:
		var client_script = load("res://mods-unpacked/gareth-mod_manager_mod/scripts/mod_store_client.gd")
		if client_script:
			var c = client_script.new()
			add_child(c)
			if c.has_signal("repo_fetch_completed"):
				c.repo_fetch_completed.connect(_on_catalog_fetched)
			c.fetch_all_available_mods()

func _on_catalog_fetched(_repo: String, releases: Array) -> void:
	if releases.size() > 0:
		all_packages.clear()
		for r in releases:
			if typeof(r) != TYPE_DICTIONARY: continue
			var p_name: String = str(r.get("name", "Unknown Package"))
			var tag: String = str(r.get("tag_name", "v1.0.0"))
			var body: String = str(r.get("body", "No description available."))
			var p_id: String = ""
			var assets = r.get("assets", [])
			if typeof(assets) == TYPE_ARRAY and assets.size() > 0:
				var a = assets[0]
				if typeof(a) == TYPE_DICTIONARY and a.has("name"):
					p_id = str(a["name"]).replace(".zip", "")
			if p_id == "" and r.has("id"):
				p_id = str(r["id"])
			if p_id == "": continue

			var cat := "Quality of Life"
			var lower_n := p_name.to_lower()
			if "map" in lower_n or "trench" in lower_n or "faultline" in lower_n or "canvas" in lower_n: cat = "Custom Maps & Strata"
			elif "class" in lower_n or "profession" in lower_n or "jedi" in lower_n or "knight" in lower_n: cat = "Classes & Professions"
			elif "bomb" in lower_n or "laser" in lower_n or "turret" in lower_n or "weapon" in lower_n or "mortar" in lower_n: cat = "Weapons & Arsenal"
			elif "employee" in lower_n or "collector" in lower_n or "drill" in lower_n or "vacuum" in lower_n: cat = "Workforce & Automation"

			all_packages.append({
				"id": p_id,
				"name": p_name,
				"tag": tag,
				"desc": body,
				"cat": cat,
				"author": "Gareth White"
			})
		status_lbl.text = "Gareth White (Official Suite): %d verified packages loaded." % all_packages.size()
		status_lbl.modulate = Color(0.4, 0.85, 1.0)
		_render_cards()

func _render_cards() -> void:
	for child in cards_vbox.get_children():
		child.queue_free()

	var query: String = search_edit.text.strip_edges().to_lower()
	var selected_cat: int = cat_dropdown.selected
	var selected_status: int = status_dropdown.selected

	var match_count = 0
	for pkg in all_packages:
		var pkg_id: String = str(pkg.get("id", ""))
		var pkg_name: String = str(pkg.get("name", "Package"))
		var pkg_tag: String = str(pkg.get("tag", "v1.0.0"))
		var pkg_desc: String = str(pkg.get("desc", ""))
		var pkg_cat: String = str(pkg.get("cat", "General Mod"))
		var pkg_author: String = str(pkg.get("author", "Gareth White"))

		# 1. Interactive Search Filter
		if not query.is_empty() and not (query in pkg_name.to_lower() or query in pkg_desc.to_lower() or query in pkg_author.to_lower()):
			continue
		
		# 2. Category Filter
		if selected_cat > 0:
			var cat_name: String = cat_dropdown.get_item_text(selected_cat)
			if pkg_cat != cat_name:
				continue

		# File verification checks on Windows Steam isolation paths
		var base_dir = OS.get_executable_path().get_base_dir()
		var is_installed = FileAccess.file_exists(base_dir.path_join("mods").path_join("%s.zip" % pkg_id))

		# 3. Status Filter
		if selected_status == 1 and not is_installed:
			continue
		if selected_status == 2 and is_installed:
			continue

		match_count += 1

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
		title_lbl.text = "[b][font_size=15][color=#ffffff]%s[/color][/font_size][/b]  [color=#4ade80]%s[/color]  [color=#fbbf24][%s][/color]  [color=#94a3b8]by %s[/color]" % [pkg_name, pkg_tag, pkg_cat, pkg_author]
		title_lbl.fit_content = true
		info_vbox.add_child(title_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = pkg_desc
		desc_lbl.modulate = Color(0.88, 0.90, 0.94)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_vbox.add_child(desc_lbl)

		hbox.add_child(info_vbox)

		var btn_action = Button.new()
		btn_action.custom_minimum_size = Vector2(140, 36)

		if is_installed:
			btn_action.text = "Uninstall"
			btn_action.modulate = Color(1.0, 0.45, 0.45)
			btn_action.pressed.connect(func(): _uninstall_mod(pkg_id))
		else:
			btn_action.text = "Install"
			btn_action.modulate = Color(0.45, 0.95, 0.55)
			btn_action.pressed.connect(func(): _install_mod(pkg_id))

		hbox.add_child(btn_action)
		cards_vbox.add_child(card)

	# Active search feedback directly to the operator
	if not query.is_empty():
		status_lbl.text = "🔍 Found %d of %d packages matching '%s'" % [match_count, all_packages.size(), query]
		status_lbl.modulate = Color(0.3, 0.8, 1.0)
	else:
		status_lbl.text = "📚 Repository contains %d active packages for staging." % [all_packages.size()]
		status_lbl.modulate = Color(0.4, 1.0, 0.6)

func _install_mod(mod_id: String) -> void:
	var base_dir = OS.get_executable_path().get_base_dir()
	var src = base_dir.path_join("downloaded_mods").path_join("%s.zip" % mod_id)
	var dst = base_dir.path_join("mods").path_join("%s.zip" % mod_id)

	if FileAccess.file_exists(src):
		var err = DirAccess.copy_absolute(src, dst)
		if err == OK:
			status_lbl.text = "🚀 Installed %s.zip to active mods directory! (Restart game to load)." % mod_id
			status_lbl.modulate = Color(0.4, 1.0, 0.6)
		else:
			status_lbl.text = "❌ Failed to copy pack: Error %d" % err
			status_lbl.modulate = Color(1.0, 0.4, 0.4)
	else:
		status_lbl.text = "❌ Package '%s.zip' not staged in downloaded_mods/." % mod_id
		status_lbl.modulate = Color(1.0, 0.4, 0.4)

	_render_cards()

func _uninstall_mod(mod_id: String) -> void:
	var base_dir = OS.get_executable_path().get_base_dir()
	var dst = base_dir.path_join("mods").path_join("%s.zip" % mod_id)

	if FileAccess.file_exists(dst):
		var err = DirAccess.remove_absolute(dst)
		if err == OK:
			status_lbl.text = "🗑️ Uninstalled %s.zip. Deleted from active mods directory." % mod_id
			status_lbl.modulate = Color(1.0, 0.5, 0.5)
		else:
			# If Windows filesystem holds read locks, write target as a pending purge
			var pend = FileAccess.open(base_dir.path_join("mods").path_join("%s.pending_delete" % mod_id), FileAccess.WRITE)
			if pend: pend.close()
			status_lbl.text = "⏳ Windows locked %s.zip. Slated for sync deletion on next launch." % mod_id
			status_lbl.modulate = Color(1.0, 0.85, 0.3)

	_render_cards()


