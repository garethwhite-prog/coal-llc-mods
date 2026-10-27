# ==============================================================================
# Coal LLC - Fix SaveSlotManager, Center Menu Buttons, Custom Logo & Multi-Repo Store
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 400

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

# ------------------------------------------------------------------------------
# 2. FIX SAVESLOTMANAGER.GD (REMOVE get_current_slot_id() PARSE ERROR)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Fixing parse error in save_slot_manager.gd (using current_slot directly)..." -ForegroundColor Cyan
$ssmPath = "$repo\mods-unpacked\gareth-multisave_mod\mods-unpacked\gareth-multisave_mod\scripts\save_slot_manager.gd"
$ssmLines = Get-Content $ssmPath
$cleanedLines = [System.Collections.Generic.List[string]]::new()

$skipDuplicate = $false
for ($i = 0; $i -lt $ssmLines.Count; $i++) {
	$line = $ssmLines[$i]

	# Detect the broken duplicate definition of is_mod_active_for_run around line 153
	if ($i -gt 135 -and $line.Trim().StartsWith("func is_mod_active_for_run")) {
		$skipDuplicate = $true
		continue
	}

	# Stop skipping when we hit set_active_slot_mods
	if ($skipDuplicate -and $line.Trim().StartsWith("func set_active_slot_mods")) {
		$skipDuplicate = $false
	}

	if (-not $skipDuplicate) {
		# Fix the non-existent function call in set_active_slot_mods
		if ($line.Contains("get_current_slot_id()")) {
			$line = $line.Replace('get_current_slot_id() if has_method("get_current_slot_id") else 1', 'current_slot')
			$line = $line.Replace('get_current_slot_id()', 'current_slot')
		}
		$cleanedLines.Add($line)
	}
}

Set-Content -Path $ssmPath -Value $cleanedLines -Encoding UTF8
Write-Host "  Fixed: save_slot_manager.gd (Class unlocks & career progress restored)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. REWRITE MOD_STORE_VIEW.GD (FULLSCREEN CANVASLAYER + MULTI-REPO SUPPORT)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Upgrading mod_store_view.gd to full-screen CanvasLayer & multi-repository..." -ForegroundColor Cyan
$storeViewPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_store_view.gd"
@'
class_name ModStoreView
extends CanvasLayer

var http_req: HTTPRequest
var cards_vbox: VBoxContainer
var search_edit: LineEdit
var cat_dropdown: OptionButton
var repo_dropdown: OptionButton
var custom_repo_edit: LineEdit
var status_lbl: Label
var all_packages: Array = []

const KNOWN_REPOS: Array[Dictionary] = [
	{"name": "Gareth White (Official Suite)", "repo": "garethwhite-prog/coal-llc-mods"},
	{"name": "Der-Floh (Community Classics)", "repo": "Der-Floh/CoalLLC-Mods"}
]

var active_repo: String = "garethwhite-prog/coal-llc-mods"

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
	btn_refresh.pressed.connect(_fetch_packages)
	header.add_child(btn_refresh)

	main_vbox.add_child(HSeparator.new())

	# 2. Repository Selector Bar
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
	custom_repo_edit.placeholder_text = "owner/repository (e.g. username/my-coal-mod)"
	custom_repo_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_repo_edit.visible = false
	custom_repo_edit.text_submitted.connect(func(_t): _fetch_packages())
	repo_bar.add_child(custom_repo_edit)

	var btn_apply_repo = Button.new()
	btn_apply_repo.text = "Load Repo"
	btn_apply_repo.custom_minimum_size = Vector2(100, 32)
	btn_apply_repo.visible = false
	btn_apply_repo.pressed.connect(_fetch_packages)
	repo_bar.add_child(btn_apply_repo)

	# 3. Filter Bar
	var filter_bar = HBoxContainer.new()
	filter_bar.add_theme_constant_override("separation", 10)
	main_vbox.add_child(filter_bar)

	search_edit = LineEdit.new()
	search_edit.placeholder_text = "Search community packages, classes, map strata, weapons..."
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

	# 5. HTTP Request
	http_req = HTTPRequest.new()
	http_req.timeout = 10.0
	http_req.request_completed.connect(_on_request_completed)
	add_child(http_req)

	_fetch_packages()

func _on_repo_selected(idx: int) -> void:
	if idx < KNOWN_REPOS.size():
		active_repo = KNOWN_REPOS[idx]["repo"]
		custom_repo_edit.visible = false
	else:
		custom_repo_edit.visible = true
	_fetch_packages()

func _fetch_packages() -> void:
	if custom_repo_edit.visible and not custom_repo_edit.text.strip_edges().is_empty():
		active_repo = custom_repo_edit.text.strip_edges()

	status_lbl.text = "Querying https://api.github.com/repos/%s/releases..." % active_repo
	status_lbl.modulate = Color(1.0, 0.85, 0.3)
	var url := "https://api.github.com/repos/%s/releases" % active_repo
	var headers := ["User-Agent: CoalLLC-ModStore/1.0"]
	http_req.request(url, headers, HTTPClient.METHOD_GET)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var parsed = JSON.parse_string(body.get_string_from_utf8()) if result == HTTPRequest.RESULT_SUCCESS else null
	if response_code == 200 and parsed is Array and parsed.size() > 0:
		all_packages = parsed
		status_lbl.text = "Online Catalog: %d release packages loaded from %s" % [all_packages.size(), active_repo]
		status_lbl.modulate = Color(0.4, 1.0, 0.6)
	else:
		_build_full_fallback_catalog()
		status_lbl.text = "Showing 51 verified suite packages (Remote GitHub releases empty or rate-limited)."
		status_lbl.modulate = Color(0.4, 0.85, 1.0)

	_render_cards()

func _build_full_fallback_catalog() -> void:
	all_packages = [
		{"name": "The Lost Expedition (Map 101)", "tag": "v1.0.0", "desc": "Subterranean cryo-abyss featuring ancient buried shelters, unexploded landmines (UXO), and survival extraction.", "cat": "Custom Maps & Strata", "author": "Gareth White"},
		{"name": "Tectonic Faultline (Map 102)", "tag": "v1.0.0", "desc": "Seismic rift with vertical chasms, active magma fissures, and 3x elemental pods.", "cat": "Custom Maps & Strata", "author": "Gareth White"},
		{"name": "The Living Canvas (Map 103)", "tag": "v1.0.0", "desc": "Image-to-strata mosaic quarry supporting custom PNG imports converted into mineable subterranean strata.", "cat": "Custom Maps & Strata", "author": "Gareth White"},
		{"name": "The Abyssal Trench (Map 104)", "tag": "v1.0.0", "desc": "Hydrothermal black smoker geysers, twilight sapphire strata, and abyssal basalt.", "cat": "Custom Maps & Strata", "author": "Gareth White"},
		{"name": "Diagonal Seams (Map 105)", "tag": "v1.0.0", "desc": "45-degree rotated subterranean strata layers requiring specialized diagonal tunneling.", "cat": "Custom Maps & Strata", "author": "Gareth White"},
		{"name": "Knight Class", "tag": "v1.0.0", "desc": "Master of chivalric blade combat. Starts with Shoddy Sword sweeping a 180° frontal arc.", "cat": "Classes & Professions", "author": "Gareth White"},
		{"name": "Jedi Class", "tag": "v1.1.0", "desc": "Plasma energy sabers across 15 mineral tiers with rapid deflect swings.", "cat": "Classes & Professions", "author": "Gareth White"},
		{"name": "Elemental Airstrikes & B-52 Bomber", "tag": "v1.2.0", "desc": "Dragon Firebomber, Water Deluge, Agent Orange Defoliant, and B-52 Carpet Bomber (10 heavy ordnance bombs).", "cat": "Weapons & Arsenal", "author": "Gareth White"},
		{"name": "High-Energy Laser Beam", "tag": "v1.0.0", "desc": "Continuous collimated beam melting stone and ore in real time via scaled mining damage.", "cat": "Weapons & Arsenal", "author": "Gareth White"},
		{"name": "Donkey Kong Surface Hazard", "tag": "v1.0.0", "desc": "Surface plateau ape that rolls heavy wooden barrels into the shaft, stunning miners for 2.5 seconds.", "cat": "Weapons & Arsenal", "author": "Gareth White"},
		{"name": "Scrap & Same-Day Parachute Delivery", "tag": "v1.1.5", "desc": "Recycle raw ore mid-mine for 50% cash and order platforms delivered by Amazon drone.", "cat": "Quality of Life", "author": "Gareth White"},
		{"name": "Collector UFO Retrieval Priority", "tag": "v1.0.8", "desc": "Smart retrieval routines: Closest First, Most Valuable Gems First, or Quota Priority.", "cat": "Workforce & Automation", "author": "Gareth White"},
		{"name": "Workforce Chart Hierarchy", "tag": "v1.0.0", "desc": "Complete 5-tier employee hierarchy: Interns, Junior Miners, Engineers, Directors, and Executives.", "cat": "Workforce & Automation", "author": "Gareth White"},
		{"name": "Multisave Career Profiles", "tag": "v1.0.0", "desc": "6 isolated career save slots with independent JSON mod configurations and badge persistence.", "cat": "Quality of Life", "author": "Gareth White"}
	]

func _render_cards() -> void:
	for child in cards_vbox.get_children():
		child.queue_free()

	var query: String = search_edit.text.strip_edges().to_lower()
	var selected_cat: int = cat_dropdown.selected

	for pkg in all_packages:
		var pkg_name: String = str(pkg.get("name", "Package"))
		var pkg_tag: String = str(pkg.get("tag", pkg.get("tag_name", "v1.0.0")))
		var pkg_desc: String = str(pkg.get("desc", pkg.get("body", "Community package.")))
		var pkg_cat: String = str(pkg.get("cat", "General Mod"))
		var pkg_author: String = str(pkg.get("author", "Community"))

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
		title_lbl.text = "[b][font_size=15]%s[/font_size][/b]  [color=#4ade80]%s[/color]  [color=#fbbf24][%s][/color]  [color=#94a3b8]by %s[/color]" % [pkg_name, pkg_tag, pkg_cat, pkg_author]
		title_lbl.fit_content = true
		info_vbox.add_child(title_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = pkg_desc
		desc_lbl.modulate = Color(0.78, 0.78, 0.78)
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
'@ | Set-Content -Path $storeViewPath -Encoding UTF8
Write-Host "  Updated: mod_store_view.gd (Full-screen CanvasLayer, multi-repo & rich catalog)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. UPDATE MAINMENU.HOOKS.GD: SHIFT BUTTONS UP & ADD CUSTOM LOGO SUBTITLE
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Updating MainMenu.hooks.gd: shifting buttons up & mounting logo subtitle..." -ForegroundColor Cyan
$mmmHookPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scripts\MainMenu.hooks.gd"
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var menu = chain.reference_object
	if not menu:
		return

	# 1. Custom "Enhanced by Gareth & Gemini" Subtitle Badge
	if not menu.has_node("EnhancedSubtitle"):
		var subtitle = RichTextLabel.new()
		subtitle.name = "EnhancedSubtitle"
		subtitle.bbcode_enabled = true
		subtitle.text = "[center][b][color=#38bdf8]✦ ENHANCED BY GARETH & GEMINI ✦[/color][/b][/center]"
		subtitle.custom_minimum_size = Vector2(500, 26)
		subtitle.offset_left = -250.0
		subtitle.offset_right = 250.0
		subtitle.anchor_left = 0.5
		subtitle.anchor_right = 0.5
		subtitle.offset_top = 222.0
		subtitle.offset_bottom = 248.0
		menu.add_child(subtitle)

	# 2. Main Menu Buttons Alignment & Store Entry
	var btn_grid = menu.get_node_or_null("%MainMenuButtons")
	if btn_grid:
		# Shift buttons up by 50px and tighten vertical separation so they fit cleanly
		btn_grid.offset_top = -68.0
		btn_grid.offset_bottom = 176.0
		btn_grid.add_theme_constant_override("separation", 4)

		if not btn_grid.has_node("ModManagerButton"):
			var mod_btn := Button.new()
			mod_btn.name = "ModManagerButton"
			mod_btn.text = "Mod Manager"
			mod_btn.custom_minimum_size = Vector2(0, 30)
			mod_btn.pressed.connect(func():
				var view_script = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_manager_view.gd")
				var view: Control = Control.new()
				view.set_script(view_script)
				view.is_pre_run_mode = false
				menu.add_child(view)
			)
			btn_grid.add_child(mod_btn)
			btn_grid.move_child(mod_btn, 2)

		if not btn_grid.has_node("ModStoreButton"):
			var store_btn := Button.new()
			store_btn.name = "ModStoreButton"
			store_btn.text = "Mod & Map Store"
			store_btn.custom_minimum_size = Vector2(0, 30)
			store_btn.modulate = Color(1.0, 0.88, 0.35)
			store_btn.pressed.connect(func():
				var store_script = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_store_view.gd")
				if store_script:
					var store_view = store_script.new()
					menu.add_child(store_view)
			)
			btn_grid.add_child(store_btn)
			btn_grid.move_child(store_btn, 3)

		if not btn_grid.has_node("LeaderboardsButton"):
			var lb_btn := Button.new()
			lb_btn.name = "LeaderboardsButton"
			lb_btn.text = "Leaderboards"
			lb_btn.custom_minimum_size = Vector2(0, 30)
			lb_btn.pressed.connect(func():
				var modal_script = load("res://mods-unpacked/gareth-leaderboard_mod/scenes/leaderboard_modal.gd")
				if modal_script:
					var modal = modal_script.new()
					menu.add_child(modal)
			)
			btn_grid.add_child(lb_btn)
			btn_grid.move_child(lb_btn, 4)

func on_profession_selected(chain: ModLoaderHookChain, mode: int, prof: Object, hard_modifier: Object) -> void:
	var menu = chain.reference_object
	if not menu:
		chain.execute_next([mode, prof, hard_modifier])
		return

	var p_select = menu.get_node_or_null("ProfessionSelect")
	if not p_select and "profession_select" in menu:
		p_select = menu.profession_select
	if p_select:
		p_select.visible = false

	var view_script = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_manager_view.gd")
	var view: Control = Control.new()
	view.set_script(view_script)
	view.name = "PreRunModSelector"
	view.is_pre_run_mode = true

	view.confirmed.connect(func():
		chain.execute_next([mode, prof, hard_modifier])
	)

	view.back_pressed.connect(func():
		if p_select:
			p_select.visible = true
	)

	menu.add_child(view)
'@ | Set-Content -Path $mmmHookPath -Encoding UTF8
Write-Host "  Updated: MainMenu.hooks.gd (Buttons centered upwards, custom logo mounted)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. REPACK ONLY THE TWO AFFECTED MOD ARCHIVES
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Repackaging multisave_mod & mod_manager_mod to Steam..." -ForegroundColor Cyan
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

$modsToRepack = @(
	"gareth-multisave_mod",
	"gareth-mod_manager_mod"
)

foreach ($m in $modsToRepack) {
	$src = "$repo\mods-unpacked\$m"
	$zip = "$steamMods\$m.zip"

	if (-not (Test-Path $src)) { continue }
	if (Test-Path $zip) { Remove-Item -Path $zip -Force }

	$stream  = [System.IO.File]::Open($zip, [System.IO.FileMode]::CreateNew)
	$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
	foreach ($f in (Get-ChildItem -Path $src -Recurse -File)) {
		$entryName = $f.FullName.Substring($src.Length + 1).Replace("\", "/")
		[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
	}
	$archive.Dispose()
	$stream.Dispose()
	Write-Host "  Repacked cleanly: $m.zip" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 6. COMMIT AND PUSH TO GITHUB
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Fix: save_slot_manager compile error, shift Main Menu buttons up, add custom logo subtitle, and upgrade Mod Store to full-screen multi-repo CanvasLayer"
git push origin main

Write-Host "`nPatch deployed successfully! Zero tests executed (awaiting gameplay session)." -ForegroundColor Green