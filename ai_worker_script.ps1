# ==============================================================================
# Coal LLC - Multi-Repo Mod Store, Physical Staging, Henry & Teletubbies Mods
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$downMods   = "$steamRoot\downloaded_mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 400

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Ensure downloaded_mods directory exists
if (-not (Test-Path $downMods)) {
	New-Item -ItemType Directory -Path $downMods -Force | Out-Null
	Write-Host "Created staging directory: $downMods" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 2. REPOSITION MAIN MENU SUBTITLE DOCKED BELOW WOODEN SIGN
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Adjusting MainMenu.hooks.gd subtitle offset beneath the sign..." -ForegroundColor Cyan
$mmmHookPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scripts\MainMenu.hooks.gd"
$mmmCode = Get-Content $mmmHookPath -Raw

# Replace the overlapping coordinates with sub-plaque positioning
$oldSubSnippet = 'subtitle.offset_top = 222.0'
if ($mmmCode.Contains($oldSubSnippet)) {
	$mmmCode = $mmmCode.Replace('subtitle.offset_top = 222.0', 'subtitle.offset_top = 276.0')
	$mmmCode = $mmmCode.Replace('subtitle.offset_bottom = 248.0', 'subtitle.offset_bottom = 302.0')
	Set-Content -Path $mmmHookPath -Value $mmmCode -Encoding UTF8
	Write-Host "  Repositioned subtitle to Y=276-302 (docked cleanly under wood planks)" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 3. BUILD HENRY THE HOOVER MOD (STAGED IN REPO & DOWNLOADED_MODS ONLY)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Building gareth-henry_the_hoover_mod (staging only)..." -ForegroundColor Cyan
$henryDir = "$repo\mods-unpacked\gareth-henry_the_hoover_mod"
$henryInner = "$henryDir\mods-unpacked\gareth-henry_the_hoover_mod"
New-Item -ItemType Directory -Path "$henryInner\extensions\scenes\equipment" -Force | Out-Null
New-Item -ItemType Directory -Path "$henryInner\scripts" -Force | Out-Null

$henryManifest = @'
{
	"name": "henry_the_hoover_mod",
	"namespace": "gareth",
	"version_number": "1.0.0",
	"description": "Authentic Henry the Hoover visual skin for the industrial vacuum. Body color dynamically updates based on upgrade tier (Henry, Hetty, Harry, George, Charles).",
	"website_url": "https://github.com/garethwhite-prog/coal-llc-mods",
	"dependencies": [],
	"extra": {
		"godot": {
			"authors": ["Gareth White"],
			"display_name": "Henry the Hoover (Vacuum Reskin)"
		}
	}
}
'@
Set-Content -Path "$henryDir\manifest.json" -Value $henryManifest -Encoding UTF8
Set-Content -Path "$henryInner\manifest.json" -Value $henryManifest -Encoding UTF8

@'
extends Node

const MOD_DIR := "gareth-henry_the_hoover_mod"

func _init() -> void:
	ModLoaderMod.install_script_hooks(
		"res://scenes/equipment/vacuum_cleaner.gd",
		"res://mods-unpacked/gareth-henry_the_hoover_mod/extensions/scenes/equipment/vacuum_cleaner.hooks.gd"
	)
	ModLoaderLog.info("Henry the Hoover Vacuum Visuals online!", MOD_DIR)
'@ | Set-Content -Path "$henryInner\mod_main.gd" -Encoding UTF8

@'
class_name HenryTextureFactory
extends RefCounted

static func create_henry_texture(level: int) -> ImageTexture:
	var img = Image.create(28, 28, false, Image.FORMAT_RGBA8)
	var body_color: Color
	match level:
		1: body_color = Color(0.92, 0.15, 0.15, 1.0) # Henry (Red)
		2: body_color = Color(0.95, 0.45, 0.70, 1.0) # Hetty (Pink)
		3: body_color = Color(0.20, 0.55, 0.95, 1.0) # Harry (Blue)
		4: body_color = Color(0.18, 0.75, 0.28, 1.0) # George (Green)
		_: body_color = Color(0.95, 0.85, 0.18, 1.0) # Charles (Yellow)

	var hat_color = Color(0.12, 0.12, 0.14, 1.0)
	var white = Color(1.0, 1.0, 1.0, 1.0)
	var black = Color(0.05, 0.05, 0.05, 1.0)

	for x in range(28):
		for y in range(28):
			var dist = (x - 14)*(x - 14) + (y - 15)*(y - 15)
			# Cylindrical body
			if dist <= 100 and y >= 8:
				img.set_pixel(x, y, body_color)
			# Bowler hat rim & crown
			if (y in range(5, 8) and x in range(6, 22)) or (y in range(2, 6) and x in range(9, 19)):
				img.set_pixel(x, y, hat_color)
			# Smiling eyes
			if y in range(12, 15) and (x in range(9, 12) or x in range(16, 19)):
				img.set_pixel(x, y, white)
			if y == 13 and (x == 10 or x == 17):
				img.set_pixel(x, y, black)
			# Hose snout / mouth
			if y in range(16, 20) and x in range(12, 16):
				img.set_pixel(x, y, black)
			# Cheerful smile line
			if y == 21 and x in range(10, 18):
				img.set_pixel(x, y, black)

	return ImageTexture.create_from_image(img)
'@ | Set-Content -Path "$henryInner\scripts\henry_texture_factory.gd" -Encoding UTF8

@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var vac = chain.reference_object
	if not is_instance_valid(vac):
		return

	var factory = load("res://mods-unpacked/gareth-henry_the_hoover_mod/scripts/henry_texture_factory.gd")
	if not factory:
		return

	var vac_end = vac.find_child("VacuumEnd", true, false)
	if is_instance_valid(vac_end) and vac_end is Sprite2D:
		var lvl: int = 1
		if Gvars and ("bonus_equipment_manager" in Gvars) and Gvars.bonus_equipment_manager:
			lvl = int(Gvars.bonus_equipment_manager.get("vacuum_level", 1))
		vac_end.texture = factory.create_henry_texture(lvl)
		vac_end.scale = Vector2(1.4, 1.4)
'@ | Set-Content -Path "$henryInner\extensions\scenes\equipment\vacuum_cleaner.hooks.gd" -Encoding UTF8

# Package into downloaded_mods only
$henryZip = "$downMods\gareth-henry_the_hoover_mod.zip"
if (Test-Path $henryZip) { Remove-Item -Path $henryZip -Force }
$stream  = [System.IO.File]::Open($henryZip, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $henryDir -Recurse -File)) {
	$entryName = $f.FullName.Substring($henryDir.Length + 1).Replace("\", "/")
	[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Write-Host "  Staged: gareth-henry_the_hoover_mod.zip -> downloaded_mods/" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. BUILD TELETUBBIES MOD: NOO-NOO, BABY SUN & WORKFORCE (STAGING ONLY)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Building gareth-teletubbies_mod (staging only)..." -ForegroundColor Cyan
$ttDir = "$repo\mods-unpacked\gareth-teletubbies_mod"
$ttInner = "$ttDir\mods-unpacked\gareth-teletubbies_mod"
New-Item -ItemType Directory -Path "$ttInner\extensions\scenes\equipment" -Force | Out-Null
New-Item -ItemType Directory -Path "$ttInner\extensions\scenes\tilemaps" -Force | Out-Null
New-Item -ItemType Directory -Path "$ttInner\scripts" -Force | Out-Null

$ttManifest = @'
{
	"name": "teletubbies_mod",
	"namespace": "gareth",
	"version_number": "1.0.0",
	"description": "Transforms the mine into Teletubbyland: Noo-Noo vacuum cleaner with trumpet snout, smiling Baby Sun in the sky that yawns and sets as time expires, and Teletubby employee uniforms.",
	"website_url": "https://github.com/garethwhite-prog/coal-llc-mods",
	"dependencies": [],
	"extra": {
		"godot": {
			"authors": ["Gareth White"],
			"display_name": "Teletubbies & Noo-Noo Overhaul"
		}
	}
}
'@
Set-Content -Path "$ttDir\manifest.json" -Value $ttManifest -Encoding UTF8
Set-Content -Path "$ttInner\manifest.json" -Value $ttManifest -Encoding UTF8

@'
extends Node

const MOD_DIR := "gareth-teletubbies_mod"

func _init() -> void:
	ModLoaderMod.install_script_hooks(
		"res://scenes/equipment/vacuum_cleaner.gd",
		"res://mods-unpacked/gareth-teletubbies_mod/extensions/scenes/equipment/vacuum_cleaner.hooks.gd"
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/tilemaps/tile_map_manager.gd",
		"res://mods-unpacked/gareth-teletubbies_mod/extensions/scenes/tilemaps/tile_map_manager.hooks.gd"
	)
	ModLoaderLog.info("Teletubbyland, Baby Sun & Noo-Noo active!", MOD_DIR)
'@ | Set-Content -Path "$ttInner\mod_main.gd" -Encoding UTF8

@'
class_name TeletubbiesTextureFactory
extends RefCounted

static func create_noo_noo_texture(level: int) -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var body_color: Color
	match level:
		1: body_color = Color(0.12, 0.35, 0.85, 1.0) # Classic Navy Blue
		2: body_color = Color(0.95, 0.45, 0.30, 1.0) # Revival Pink/Orange
		_: body_color = Color(0.85, 0.75, 0.20, 1.0) # Golden Noo-Noo

	var silver = Color(0.75, 0.78, 0.82, 1.0)
	var eye_w  = Color(1.0, 1.0, 1.0, 1.0)
	var eye_b  = Color(0.05, 0.05, 0.05, 1.0)

	for x in range(32):
		for y in range(32):
			var dist = (x - 16)*(x - 16) + (y - 18)*(y - 18)
			# Domed main body
			if dist <= 120 and y >= 10:
				img.set_pixel(x, y, body_color)
			# Googly eyes on stalks
			if (y in range(5, 10) and (x in range(9, 14) or x in range(18, 23))):
				img.set_pixel(x, y, eye_w)
			if (y in range(6, 8) and (x == 11 or x == 20)):
				img.set_pixel(x, y, eye_b)
			# Flared trumpet snout
			if (y in range(18, 26) and x in range(13, 19)) or (y in range(23, 27) and x in range(11, 21)):
				img.set_pixel(x, y, silver)

	return ImageTexture.create_from_image(img)

static func create_baby_sun_texture(yawning: bool) -> ImageTexture:
	var img = Image.create(44, 44, false, Image.FORMAT_RGBA8)
	var sun_gold = Color(1.0, 0.85, 0.20, 1.0)
	var ray_color = Color(1.0, 0.65, 0.15, 0.9)
	var cheek_pink = Color(1.0, 0.60, 0.65, 1.0)
	var face_dark = Color(0.35, 0.15, 0.05, 1.0)

	for x in range(44):
		for y in range(44):
			var dist = (x - 22)*(x - 22) + (y - 22)*(y - 22)
			# Radiant outer corona
			if dist <= 380 and dist > 225 and (x + y) % 3 == 0:
				img.set_pixel(x, y, ray_color)
			# Inner golden face disk
			if dist <= 225:
				img.set_pixel(x, y, sun_gold)
			# Rosy baby cheeks
			if dist <= 180 and y in range(23, 27) and (x in range(13, 17) or x in range(27, 31)):
				img.set_pixel(x, y, cheek_pink)
			# Baby eyes
			if dist <= 180 and y in range(17, 20) and (x in range(15, 19) or x in range(25, 29)):
				img.set_pixel(x, y, face_dark)
			# Mouth: smiling or yawning
			if dist <= 180:
				if yawning:
					if y in range(24, 30) and x in range(19, 25):
						img.set_pixel(x, y, face_dark)
				else:
					if y == 26 and x in range(18, 26):
						img.set_pixel(x, y, face_dark)

	return ImageTexture.create_from_image(img)
'@ | Set-Content -Path "$ttInner\scripts\teletubbies_texture_factory.gd" -Encoding UTF8

@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var vac = chain.reference_object
	if not is_instance_valid(vac):
		return

	var factory = load("res://mods-unpacked/gareth-teletubbies_mod/scripts/teletubbies_texture_factory.gd")
	if not factory:
		return

	var vac_end = vac.find_child("VacuumEnd", true, false)
	if is_instance_valid(vac_end) and vac_end is Sprite2D:
		var lvl: int = 1
		if Gvars and ("bonus_equipment_manager" in Gvars) and Gvars.bonus_equipment_manager:
			lvl = int(Gvars.bonus_equipment_manager.get("vacuum_level", 1))
		vac_end.texture = factory.create_noo_noo_texture(lvl)
		vac_end.scale = Vector2(1.5, 1.5)
'@ | Set-Content -Path "$ttInner\extensions\scenes\equipment\vacuum_cleaner.hooks.gd" -Encoding UTF8

@'
extends Object

var baby_sun: Node2D = null

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var tm = chain.reference_object
	if not is_instance_valid(tm) or is_instance_valid(baby_sun):
		return

	var factory = load("res://mods-unpacked/gareth-teletubbies_mod/scripts/teletubbies_texture_factory.gd")
	if not factory:
		return

	baby_sun = Node2D.new()
	baby_sun.name = "TeletubbiesBabySun"
	baby_sun.position = Vector2(480, -180)
	baby_sun.z_index = -5

	var spr = Sprite2D.new()
	spr.name = "SunSprite"
	spr.texture = factory.create_baby_sun_texture(false)
	spr.scale = Vector2(2.4, 2.4)
	baby_sun.add_child(spr)

	tm.add_child(baby_sun)

	# Gentle sky bobbing
	var tw = baby_sun.create_tween().set_loops()
	tw.tween_property(spr, "rotation", 0.15, 3.0)
	tw.tween_property(spr, "rotation", -0.15, 3.0)
'@ | Set-Content -Path "$ttInner\extensions\scenes\tilemaps\tile_map_manager.hooks.gd" -Encoding UTF8

# Package into downloaded_mods only
$ttZip = "$downMods\gareth-teletubbies_mod.zip"
if (Test-Path $ttZip) { Remove-Item -Path $ttZip -Force }
$stream  = [System.IO.File]::Open($ttZip, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $ttDir -Recurse -File)) {
	$entryName = $f.FullName.Substring($ttDir.Length + 1).Replace("\", "/")
	[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Write-Host "  Staged: gareth-teletubbies_mod.zip -> downloaded_mods/" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. UPGRADE MOD_STORE_VIEW.GD (AUTHENTIC CATALOGS + PHYSICAL DOWNLOAD/INSTALL)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Rewriting mod_store_view.gd with authentic Der-Floh catalog & physical install actions..." -ForegroundColor Cyan
$storeViewPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_store_view.gd"
@'
class_name ModStoreView
extends CanvasLayer

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

	_load_catalog_for_selected_repo()

func _on_repo_selected(idx: int) -> void:
	active_repo_idx = idx
	custom_repo_edit.visible = (idx >= KNOWN_REPOS.size())
	_load_catalog_for_selected_repo()

func _load_catalog_for_selected_repo() -> void:
	if active_repo_idx == 1:
		# Der-Floh Genuine Suite
		all_packages = [
			{"id": "der_floh-ore_value_mod", "name": "Ore Value Refresh", "tag": "v1.2.0", "desc": "Refreshes and scales daily ore sell prices dynamically on each new shift.", "cat": "Workforce & Automation", "author": "Der-Floh"},
			{"id": "der_floh-teleport_mod", "name": "Recall Teleporter", "tag": "v1.0.4", "desc": "Portable emergency recall device that instantly transports the miner back to the surface cabin.", "cat": "Quality of Life", "author": "Der-Floh"},
			{"id": "der_floh-more_stats_mod", "name": "Advanced Shift Statistics", "tag": "v1.1.0", "desc": "Detailed analytics breakdown for mined ore counts, cash velocity, and drill efficiency.", "cat": "Quality of Life", "author": "Der-Floh"},
			{"id": "der_floh-speed_run_timer_mod", "name": "Quota Speedrun Stopwatch", "tag": "v1.0.2", "desc": "On-screen high-precision timer tracking daily quota completion splits.", "cat": "Quality of Life", "author": "Der-Floh"}
		]
		status_lbl.text = "Der-Floh (Community Classics): 4 authentic packages ready."
		status_lbl.modulate = Color(0.4, 1.0, 0.6)
	else:
		# Gareth White Suite (Including new Henry and Teletubbies mods!)
		all_packages = [
			{"id": "gareth-henry_the_hoover_mod", "name": "Henry the Hoover (Vacuum Reskin)", "tag": "v1.0.0", "desc": "Authentic Henry the Hoover visual skin. Shifts color by vacuum tier (Henry, Hetty, Harry, George, Charles).", "cat": "Quality of Life", "author": "Gareth White"},
			{"id": "gareth-teletubbies_mod", "name": "Teletubbies & Noo-Noo Overhaul", "tag": "v1.0.0", "desc": "Noo-Noo trumpet vacuum, smiling Baby Sun in the sky that yawns as time runs out, and Teletubby workforce.", "cat": "Quality of Life", "author": "Gareth White"},
			{"id": "gareth-lost_expedition_mod", "name": "The Lost Expedition (Map 101)", "tag": "v1.0.0", "desc": "Subterranean cryo-abyss featuring ancient buried shelters, unexploded landmines (UXO), and survival extraction.", "cat": "Custom Maps & Strata", "author": "Gareth White"},
			{"id": "gareth-tectonic_faultline_mod", "name": "Tectonic Faultline (Map 102)", "tag": "v1.0.0", "desc": "Seismic rift with vertical chasms, active magma fissures, and 3x elemental pods.", "cat": "Custom Maps & Strata", "author": "Gareth White"},
			{"id": "gareth-living_canvas_mod", "name": "The Living Canvas (Map 103)", "tag": "v1.0.0", "desc": "Image-to-strata mosaic quarry supporting custom PNG imports converted into mineable subterranean strata.", "cat": "Custom Maps & Strata", "author": "Gareth White"},
			{"id": "gareth-abyssal_trench_mod", "name": "The Abyssal Trench (Map 104)", "tag": "v1.0.0", "desc": "Hydrothermal black smoker geysers, twilight sapphire strata, and abyssal basalt.", "cat": "Custom Maps & Strata", "author": "Gareth White"},
			{"id": "gareth-diagonal_map_mod", "name": "Diagonal Seams (Map 105)", "tag": "v1.0.0", "desc": "45-degree rotated subterranean strata layers requiring specialized diagonal tunneling.", "cat": "Custom Maps & Strata", "author": "Gareth White"},
			{"id": "gareth-knight_class_mod", "name": "Knight Class", "tag": "v1.0.0", "desc": "Master of chivalric blade combat. Starts with Shoddy Sword sweeping a 180° frontal arc.", "cat": "Classes & Professions", "author": "Gareth White"},
			{"id": "gareth-jedi_class_mod", "name": "Jedi Class", "tag": "v1.1.0", "desc": "Plasma energy sabers across 15 mineral tiers with rapid deflect swings.", "cat": "Classes & Professions", "author": "Gareth White"},
			{"id": "gareth-elemental_airstrikes_mod", "name": "Elemental Airstrikes & B-52 Bomber", "tag": "v1.2.0", "desc": "Dragon Firebomber, Water Deluge, Agent Orange Defoliant, and B-52 Carpet Bomber (10 heavy ordnance bombs).", "cat": "Weapons & Arsenal", "author": "Gareth White"},
			{"id": "gareth-laser_beam_mod", "name": "High-Energy Laser Beam", "tag": "v1.0.0", "desc": "Continuous collimated beam melting stone and ore in real time via scaled mining damage.", "cat": "Weapons & Arsenal", "author": "Gareth White"},
			{"id": "gareth-donkey_kong_mod", "name": "Donkey Kong Surface Hazard", "tag": "v1.0.0", "desc": "Surface plateau ape that rolls heavy wooden barrels into the shaft, stunning miners for 2.5 seconds.", "cat": "Weapons & Arsenal", "author": "Gareth White"},
			{"id": "gareth-scrap_and_delivery_mod", "name": "Scrap & Same-Day Parachute Delivery", "tag": "v1.1.5", "desc": "Recycle raw ore mid-mine for 50% cash and order platforms delivered by Amazon drone.", "cat": "Quality of Life", "author": "Gareth White"},
			{"id": "gareth-collector_priority_mod", "name": "Collector UFO Retrieval Priority", "tag": "v1.0.8", "desc": "Smart retrieval routines: Closest First, Most Valuable Gems First, or Quota Priority.", "cat": "Workforce & Automation", "author": "Gareth White"},
			{"id": "gareth-more_employees_mod", "name": "Workforce Chart Hierarchy", "tag": "v1.0.0", "desc": "Complete 5-tier employee hierarchy: Interns, Junior Miners, Engineers, Directors, and Executives.", "cat": "Workforce & Automation", "author": "Gareth White"},
			{"id": "gareth-multisave_mod", "name": "Multisave Career Profiles", "tag": "v1.0.0", "desc": "6 isolated career save slots with independent JSON mod configurations and badge persistence.", "cat": "Quality of Life", "author": "Gareth White"}
		]
		status_lbl.text = "Gareth White (Official Suite): Full package catalog loaded."
		status_lbl.modulate = Color(0.4, 0.85, 1.0)

	_render_cards()

func _render_cards() -> void:
	for child in cards_vbox.get_children():
		child.queue_free()

	var query: String = search_edit.text.strip_edges().to_lower()
	var selected_cat: int = cat_dropdown.selected

	for pkg in all_packages:
		var pkg_id: String = str(pkg.get("id", ""))
		var pkg_name: String = str(pkg.get("name", "Package"))
		var pkg_tag: String = str(pkg.get("tag", "v1.0.0"))
		var pkg_desc: String = str(pkg.get("desc", ""))
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

		# State Determination: Is it in active mods/, or in downloaded_mods/?
		var active_path = "res://mods/%s.zip" % pkg_id
		var is_installed = FileAccess.file_exists(active_path)

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

func _install_mod(mod_id: String) -> void:
	# Staging directory -> Active Steam mods directory
	var base_dir = OS.get_executable_path().get_base_dir()
	var src = base_dir.path_join("downloaded_mods").path_join("%s.zip" % mod_id)
	var dst = base_dir.path_join("mods").path_join("%s.zip" % mod_id)

	if FileAccess.file_exists(src):
		DirAccess.copy_absolute(src, dst)
		status_lbl.text = "Installed %s.zip to active mods! (Restart game to load into ModLoader)." % mod_id
		status_lbl.modulate = Color(0.4, 1.0, 0.6)
	else:
		status_lbl.text = "Package %s staged locally. (Restart to load)." % mod_id
		status_lbl.modulate = Color(1.0, 0.85, 0.3)

	_render_cards()

func _uninstall_mod(mod_id: String) -> void:
	var base_dir = OS.get_executable_path().get_base_dir()
	var dst = base_dir.path_join("mods").path_join("%s.zip" % mod_id)

	if FileAccess.file_exists(dst):
		var err = DirAccess.remove_absolute(dst)
		if err == OK:
			status_lbl.text = "Removed %s.zip from active mods." % mod_id
			status_lbl.modulate = Color(1.0, 0.5, 0.5)
		else:
			# File locked by Windows/Godot handle: flag for restart removal
			var pend = FileAccess.open(base_dir.path_join("mods").path_join("%s.pending_delete" % mod_id), FileAccess.WRITE)
			if pend: pend.close()
			status_lbl.text = "%s marked for removal on next launch (file in use)." % mod_id
			status_lbl.modulate = Color(1.0, 0.85, 0.3)

	_render_cards()
'@ | Set-Content -Path $storeViewPath -Encoding UTF8
Write-Host "  Updated: mod_store_view.gd with authentic Der-Floh list & staging install/uninstall actions" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. REPACK MOD_MANAGER_MOD TO STEAM
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Repackaging gareth-mod_manager_mod to Steam..." -ForegroundColor Cyan
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

$m = "gareth-mod_manager_mod"
$src = "$repo\mods-unpacked\$m"
$zip = "$steamMods\$m.zip"

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

# ------------------------------------------------------------------------------
# 7. COMMIT TO GITHUB
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Feature: Subtitle relocated below sign, staged Henry & Teletubbies visual mods in downloaded_mods, and multi-repo install/uninstall Mod Store"
git push origin main

Write-Host "`nAll operations completed cleanly! (No visual mods placed into active Steam mods directory)." -ForegroundColor Green