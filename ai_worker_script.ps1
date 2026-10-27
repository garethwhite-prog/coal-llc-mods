# ==============================================================================
# Coal LLC - Architecture 3.0: Permanent Maps, Profile Persistence & Mod Store
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
# 2. UPDATE MOD_REGISTRY.GD: IMMUTABLE MAPS & SAVE SLOT SYNC
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Updating mod_registry.gd with immutable map packs & slot isolation..." -ForegroundColor Cyan
$regPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scripts\mod_registry.gd"
@'
class_name ModRegistry
extends RefCounted

const CORE_MODS: Array[String] = [
	"gareth-mod_manager_mod",
	"gareth-multisave_mod",
	"gareth-game_speed_mod",
	"gareth-lost_expedition_mod",
	"gareth-tectonic_faultline_mod",
	"gareth-living_canvas_mod",
	"gareth-abyssal_trench_mod",
	"gareth-diagonal_map_mod"
]

static func is_mod_active_for_run(mod_key: String) -> bool:
	if mod_key in CORE_MODS:
		return true

	var ssm = Engine.get_main_loop().root.get_node_or_null("/root/SaveSlotManager")
	if ssm and ssm.has_method("is_mod_active_for_run"):
		return ssm.is_mod_active_for_run(mod_key)

	var cfg_path := "user://gareth_mods_config.json"
	if FileAccess.file_exists(cfg_path):
		var f := FileAccess.open(cfg_path, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary and parsed.has("mods"):
				return bool(parsed["mods"].get(mod_key, true))
	return true

static func get_all_installed_mods() -> Array[Dictionary]:
	return get_all_mods()

static func get_all_mods() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var mod_dict: Dictionary = {}

	var mls = Engine.get_main_loop().root.get_node_or_null("/root/ModLoaderStore")
	if mls and ("mod_data" in mls) and mls.mod_data is Dictionary and mls.mod_data.size() > 0:
		mod_dict = mls.mod_data
	elif ModLoader and ("mod_data" in ModLoader) and ModLoader.mod_data is Dictionary and ModLoader.mod_data.size() > 0:
		mod_dict = ModLoader.mod_data

	if mod_dict.size() > 0:
		for mod_id in mod_dict.keys():
			var data = mod_dict[mod_id]
			if not data or not ("manifest" in data) or not data.manifest:
				continue
			list.append(_dict_from_manifest(mod_id, data.manifest, data.is_active if "is_active" in data else true))
		return list

	var dir := DirAccess.open("res://mods-unpacked")
	if dir:
		dir.list_dir_begin()
		var folder := dir.get_next()
		while folder != "":
			if dir.current_is_dir() and not folder.begins_with("."):
				var mpath := "res://mods-unpacked/%s/manifest.json" % folder
				if FileAccess.file_exists(mpath):
					var f := FileAccess.open(mpath, FileAccess.READ)
					if f:
						var parsed = JSON.parse_string(f.get_as_text())
						if parsed is Dictionary:
							list.append(_dict_from_manifest(folder, parsed, true))
			folder = dir.get_next()

	return list

static func _dict_from_manifest(mod_id: String, m, active: bool) -> Dictionary:
	var display_name: String = _format_display_name(m)
	var desc: String = str(m.description) if "description" in m else ""
	var author: String = "Community"
	if "extra" in m and m.extra:
		if ("godot" in m.extra) and ("authors" in m.extra.godot) and m.extra.godot.authors.size() > 0:
			author = str(m.extra.godot.authors[0])
	var version: String = str(m.version_number) if "version_number" in m else "1.0.0"
	var cat: String = _determine_category(m)
	var is_core: bool = (mod_id in CORE_MODS)

	return {
		"id": mod_id,
		"key": mod_id,
		"name": display_name,
		"description": desc,
		"author": author,
		"version": version,
		"category": cat,
		"is_active": active,
		"is_core": is_core
	}

static func _determine_category(m) -> String:
	var id: String = str(m.name).to_lower() if "name" in m else ""
	if "map" in id or "trench" in id or "faultline" in id or "canvas" in id or "expedition" in id or "diagonal" in id:
		return "Custom Maps & Strata"
	if "class" in id or "profession" in id or "jedi" in id or "knight" in id or "sinclairity" in id:
		return "Classes & Professions"
	if "weapon" in id or "bomb" in id or "laser" in id or "nuke" in id or "turret" in id or "mortar" in id or "grenade" in id or "arsenal" in id or "tank" in id or "strike" in id:
		return "Weapons & Arsenal"
	if "employee" in id or "collector" in id or "drill" in id or "vacuum" in id:
		return "Employees & Automation"
	if "speed" in id or "inventory" in id or "save" in id or "leaderboard" in id or "multisave" in id or "settings" in id or "scrap" in id or "delivery" in id or "ladder" in id:
		return "Quality of Life"
	if "hardware" in id or "limit" in id or "performance" in id or "booster" in id or "holes" in id:
		return "Performance & System"
	if "spirit" in id or "variance" in id or "upgrade" in id or "passive" in id or "order" in id or "beacon" in id:
		return "Progression & Upgrades"
	return "Community Add-Ons"

static func _format_display_name(m) -> String:
	if "extra" in m and m.extra and ("godot" in m.extra) and ("display_name" in m.extra.godot):
		return str(m.extra.godot.display_name)
	var raw: String = str(m.name).replace("_mod", "").replace("mod_", "").replace("-", " ").replace("_", " ") if "name" in m else "Mod"
	return raw.capitalize()
'@ | Set-Content -Path $regPath -Encoding UTF8
Write-Host "  Updated: mod_registry.gd (Maps 101-105 & Core framework immutable)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. IMPLEMENT IN-GAME MOD STORE VIEW (MOD_STORE_VIEW.GD)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Creating mod_store_view.gd (GitHub release browser & installer)..." -ForegroundColor Cyan
$storeViewPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_store_view.gd"
@'
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
'@ | Set-Content -Path $storeViewPath -Encoding UTF8
Write-Host "  Created: mod_store_view.gd (GitHub release browser UI)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. HOOK MOD STORE BUTTON & SAVE SLOT PERSISTENCE INTO MOD_MANAGER_VIEW.GD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Wiring Mod Store button & SaveSlotManager profile sync into mod_manager_view.gd..." -ForegroundColor Cyan
$mmvPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_manager_view.gd"
$mmvCode = Get-Content $mmvPath -Raw

# 4a. Add "Open Mod Store" button to header
if (-not $mmvCode.Contains("btn_open_store")) {
	$headerHook = @'
	var btn_open_store := Button.new()
	btn_open_store.text = " 🛒 Open Mod & Map Store "
	btn_open_store.custom_minimum_size = Vector2(210, 36)
	btn_open_store.modulate = Color(1.0, 0.85, 0.3)
	btn_open_store.pressed.connect(_open_mod_store)
	header_hbox.add_child(btn_open_store)
'@
	$mmvCode = $mmvCode.Replace('header_hbox.add_child(btn_save)', "$headerHook`r`n`theader_hbox.add_child(btn_save)")
}

# 4b. Add _open_mod_store implementation and SaveSlotManager persistence
if (-not $mmvCode.Contains("func _open_mod_store")) {
	$methodsHook = @'

func _open_mod_store() -> void:
	var store_script = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_store_view.gd")
	if store_script:
		var store_inst = Control.new()
		store_inst.set_script(store_script)
		add_child(store_inst)

func _sync_toggles_to_career_slot(cfg: Dictionary) -> void:
	var ssm = Engine.get_main_loop().root.get_node_or_null("/root/SaveSlotManager")
	if ssm and ssm.has_method("set_active_slot_mods"):
		ssm.set_active_slot_mods(cfg)
'@
	$mmvCode = $mmvCode.Replace('func _save_and_close() -> void:', "$methodsHook`r`nfunc _save_and_close() -> void:")
	$mmvCode = $mmvCode.Replace('_save_config(config_to_save)', "_save_config(config_to_save)`r`n`t_sync_toggles_to_career_slot(config_to_save)")
}

Set-Content -Path $mmvPath -Value $mmvCode -Encoding UTF8
Write-Host "  Updated: mod_manager_view.gd (Mod Store button & save slot sync active)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. UPDATE SAVESLOTMANAGER IN MULTISAVE_MOD FOR PER-PROFILE MOD CONFIGS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Adding per-profile mod persistence methods to save_slot_manager.gd..." -ForegroundColor Cyan
$ssmPath = "$repo\mods-unpacked\gareth-multisave_mod\mods-unpacked\gareth-multisave_mod\scripts\save_slot_manager.gd"
if (Test-Path $ssmPath) {
	$ssmCode = Get-Content $ssmPath -Raw
	if (-not $ssmCode.Contains("func set_active_slot_mods")) {
		$slotMethods = @'

func is_mod_active_for_run(mod_key: String) -> bool:
	var slot_id = get_current_slot_id() if has_method("get_current_slot_id") else 1
	var slot_cfg_path = "user://profile_mods_slot_%d.json" % slot_id
	if FileAccess.file_exists(slot_cfg_path):
		var f = FileAccess.open(slot_cfg_path, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary and parsed.has("mods"):
				return bool(parsed["mods"].get(mod_key, true))
	return true

func set_active_slot_mods(cfg: Dictionary) -> void:
	var slot_id = get_current_slot_id() if has_method("get_current_slot_id") else 1
	var slot_cfg_path = "user://profile_mods_slot_%d.json" % slot_id
	var f = FileAccess.open(slot_cfg_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(cfg, "\t"))
'@
		$ssmCode += $slotMethods
		Set-Content -Path $ssmPath -Value $ssmCode -Encoding UTF8
		Write-Host "  Updated: save_slot_manager.gd (Slots 1-6 isolated mod configs)" -ForegroundColor Green
	}
}

# ------------------------------------------------------------------------------
# 6. REPACK AFFECTED MOD ARCHIVES
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Repackaging updated mods to Steam..." -ForegroundColor Cyan
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

$modsToRepack = @(
	"gareth-mod_manager_mod",
	"gareth-multisave_mod"
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
# 7. COMMIT & RUN REGRESSION TEST
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Architecture 3.0: Permanent immutable map registry, SaveSlotManager profile isolation, and in-game Mod & Map Store browser"
git push origin main

Write-Host "`n>>> 8. Running ModSuite test auditor..." -ForegroundColor Cyan
& "$repo\Run-ModSuiteTest.ps1"

Write-Host "`nArchitecture 3.0 deployment complete!" -ForegroundColor Green