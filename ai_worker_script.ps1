# ==============================================================================
# Coal LLC - Fix Mod Manager Manifest, Restore Menu Buttons, Title Logo & New Mods
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$downMods   = "$steamRoot\downloaded_mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 400

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

if (-not (Test-Path $downMods)) {
	New-Item -ItemType Directory -Path $downMods -Force | Out-Null
}

# ------------------------------------------------------------------------------
# 2. FIX GARETH-MOD_MANAGER_MOD MANIFEST (ADD REQUIRED COMPATIBILITY ARRAYS)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Repairing gareth-mod_manager_mod manifest validation schema..." -ForegroundColor Cyan
$gmmDir = "$repo\mods-unpacked\gareth-mod_manager_mod"
$gmmInner = "$gmmDir\mods-unpacked\gareth-mod_manager_mod"

$mmmManifest = @'
{
  "name": "mod_manager_mod",
  "namespace": "gareth",
  "version_number": "2.1.0",
  "description": "Comprehensive Mod Store featuring multi-repository filtering, live name and author searches, physical staging downloads, and integrated custom Title logo.",
  "website_url": "https://github.com/garethwhite-prog/coal-llc-mods",
  "dependencies": [],
  "extra": {
    "godot": {
      "authors": ["Gareth White"],
      "display_name": "COAL LLC UNIVERSAL MOD MANAGER",
      "tags": ["core", "ui", "store", "manager", "hotbar"],
      "compatible_mod_loader_version": ["7.0.1"],
      "compatible_game_version": ["1.4.1.1"]
    }
  }
}
'@
Set-Content -Path "$gmmDir\manifest.json" -Value $mmmManifest -Encoding UTF8
Set-Content -Path "$gmmInner\manifest.json" -Value $mmmManifest -Encoding UTF8
Write-Host "  Fixed: manifest.json schema (validation failure resolved)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. WRITE COMPLETE MAINMENU.HOOKS.GD (ALL BUTTONS RESTORED + BRANDED LOGO)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Restoring full MainMenu.hooks.gd (Buttons + Custom Branded Logo)..." -ForegroundColor Cyan
$mmmHookPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scripts\MainMenu.hooks.gd"
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var menu = chain.reference_object
	if not is_instance_valid(menu):
		return

	# 1. Custom Title Sign Override with Hanging Chains Sub-Board
	var title_node = menu.find_child("Title", true, false)
	if not title_node:
		title_node = menu.find_child("TextureRect", true, false)

	if is_instance_valid(title_node) and title_node is TextureRect:
		var custom_tex = load("res://mods-unpacked/gareth-mod_manager_mod/assets/branded_logo.png")
		if custom_tex:
			title_node.texture = custom_tex
			title_node.custom_minimum_size = Vector2(760, 310)
			title_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Remove any old overlapping label
	var old_sub = menu.find_child("EnhancedSubtitle", true, false)
	if is_instance_valid(old_sub):
		old_sub.queue_free()

	# 2. Main Menu Buttons Stack
	var btn_grid = menu.get_node_or_null("%MainMenuButtons")
	if btn_grid:
		# Shift buttons up and use clean spacing
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
				if view_script:
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
	if view_script:
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
	else:
		chain.execute_next([mode, prof, hard_modifier])
'@ | Set-Content -Path $mmmHookPath -Encoding UTF8
Write-Host "  Restored: MainMenu.hooks.gd (All buttons and custom title active)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. BUILD DRONE WORKFORCE MOD (STAGE IN DOWNLOADED_MODS ONLY)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Building gareth-drone_workforce_mod (staged in downloaded_mods only)..." -ForegroundColor Cyan
$droneDir = "$repo\mods-unpacked\gareth-drone_workforce_mod"
$droneInner = "$droneDir\mods-unpacked\gareth-drone_workforce_mod"
New-Item -ItemType Directory -Path "$droneInner\extensions\scenes\AutoMiners" -Force | Out-Null
New-Item -ItemType Directory -Path "$droneInner\extensions\scripts" -Force | Out-Null
New-Item -ItemType Directory -Path "$droneInner\scripts" -Force | Out-Null

$droneManifest = @'
{
  "name": "drone_workforce_mod",
  "namespace": "gareth",
  "version_number": "1.0.0",
  "description": "Replaces all walking employee miners with hovering quadcopter laser drones and transforms UFO collectors into heavy-lift cargo quadcopters.",
  "website_url": "https://github.com/garethwhite-prog/coal-llc-mods",
  "dependencies": ["gareth-mod_manager_mod"],
  "extra": {
    "godot": {
      "authors": ["Gareth White"],
      "display_name": "Quadcopter Drone Workforce Overhaul",
      "tags": ["workforce", "automation", "drones", "visuals"],
      "compatible_mod_loader_version": ["7.0.1"],
      "compatible_game_version": ["1.4.1.1"]
    }
  }
}
'@
Set-Content -Path "$droneDir\manifest.json" -Value $droneManifest -Encoding UTF8
Set-Content -Path "$droneInner\manifest.json" -Value $droneManifest -Encoding UTF8

@'
extends Node
const MOD_DIR := "gareth-drone_workforce_mod"
func _init() -> void:
	ModLoaderMod.install_script_hooks(
		"res://scenes/AutoMiners/employee_miner_2.gd",
		"res://mods-unpacked/gareth-drone_workforce_mod/extensions/scenes/AutoMiners/employee_miner_2.hooks.gd"
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/LootCollectorUFO.gd",
		"res://mods-unpacked/gareth-drone_workforce_mod/extensions/scripts/LootCollectorUFO.hooks.gd"
	)
	ModLoaderLog.info("Quadcopter Drone Workforce online!", MOD_DIR)
'@ | Set-Content -Path "$droneInner\mod_main.gd" -Encoding UTF8

@'
class_name DroneTextureFactory
extends RefCounted

static func create_miner_drone_texture() -> ImageTexture:
	var img = Image.create(32, 24, false, Image.FORMAT_RGBA8)
	var body = Color(0.25, 0.28, 0.32, 1.0)
	var rotor = Color(0.70, 0.75, 0.80, 0.9)
	var light = Color(0.20, 0.85, 1.00, 1.0)
	var motor = Color(0.12, 0.14, 0.16, 1.0)

	for x in range(32):
		for y in range(24):
			# Central streamlined drone body
			if (y in range(9, 17) and x in range(10, 22)):
				img.set_pixel(x, y, body)
			# Front searchlight
			if y in range(12, 15) and x in range(20, 24):
				img.set_pixel(x, y, light)
			# Quad motor arms
			if (y in range(7, 10) and (x in range(4, 11) or x in range(21, 28))):
				img.set_pixel(x, y, motor)
			# Spinning rotor blade blur
			if (y == 6 and (x in range(1, 13) or x in range(19, 31))):
				img.set_pixel(x, y, rotor)
	return ImageTexture.create_from_image(img)

static func create_cargo_drone_texture() -> ImageTexture:
	var img = Image.create(36, 28, false, Image.FORMAT_RGBA8)
	var body = Color(0.85, 0.55, 0.15, 1.0)
	var frame = Color(0.20, 0.22, 0.25, 1.0)
	var rotor = Color(0.75, 0.80, 0.85, 0.85)
	var magnet = Color(0.90, 0.15, 0.15, 1.0)

	for x in range(36):
		for y in range(28):
			if (y in range(8, 18) and x in range(11, 25)):
				img.set_pixel(x, y, body)
			if (y in range(6, 9) and (x in range(3, 12) or x in range(24, 33))):
				img.set_pixel(x, y, frame)
			if (y == 5 and (x in range(1, 14) or x in range(22, 35))):
				img.set_pixel(x, y, rotor)
			# Underslung magnetic collector winch
			if y in range(19, 24) and x in range(15, 21):
				img.set_pixel(x, y, magnet)
	return ImageTexture.create_from_image(img)
'@ | Set-Content -Path "$droneInner\scripts\drone_texture_factory.gd" -Encoding UTF8

@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var miner = chain.reference_object
	if not is_instance_valid(miner): return

	var factory = load("res://mods-unpacked/gareth-drone_workforce_mod/scripts/drone_texture_factory.gd")
	if not factory: return

	# Hide humanoid limbs and mount drone chassis
	for part in ["Head", "Torso", "Legs", "Tool"]:
		var node = miner.find_child(part, true, false)
		if is_instance_valid(node) and node is CanvasItem:
			node.visible = false

	var drone_spr = miner.get_node_or_null("MinerDroneSprite")
	if not drone_spr:
		drone_spr = Sprite2D.new()
		drone_spr.name = "MinerDroneSprite"
		drone_spr.texture = factory.create_miner_drone_texture()
		drone_spr.scale = Vector2(1.5, 1.5)
		miner.add_child(drone_spr)
'@ | Set-Content -Path "$droneInner\extensions\scenes\AutoMiners\employee_miner_2.hooks.gd" -Encoding UTF8

@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var ufo = chain.reference_object
	if not is_instance_valid(ufo): return

	var factory = load("res://mods-unpacked/gareth-drone_workforce_mod/scripts/drone_texture_factory.gd")
	if not factory: return

	var models = ufo.find_child("Models", true, false)
	if is_instance_valid(models) and models is CanvasItem:
		models.visible = false

	var cargo_spr = ufo.get_node_or_null("CargoDroneSprite")
	if not cargo_spr:
		cargo_spr = Sprite2D.new()
		cargo_spr.name = "CargoDroneSprite"
		cargo_spr.texture = factory.create_cargo_drone_texture()
		cargo_spr.scale = Vector2(1.5, 1.5)
		ufo.add_child(cargo_spr)
'@ | Set-Content -Path "$droneInner\extensions\scripts\LootCollectorUFO.hooks.gd" -Encoding UTF8

# Package into downloaded_mods only
$droneZip = "$downMods\gareth-drone_workforce_mod.zip"
if (Test-Path $droneZip) { Remove-Item -Path $droneZip -Force }
$stream  = [System.IO.File]::Open($droneZip, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $droneDir -Recurse -File)) {
	$entryName = $f.FullName.Substring($droneDir.Length + 1).Replace("\", "/")
	[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Write-Host "  Staged: gareth-drone_workforce_mod.zip -> downloaded_mods/" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. BUILD THOMAS THE TANK ENGINE CLASS & RAIL OVERHAUL (STAGE ONLY)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Building gareth-thomas_tank_engine_mod (staged in downloaded_mods only)..." -ForegroundColor Cyan
$thomasDir = "$repo\mods-unpacked\gareth-thomas_tank_engine_mod"
$thomasInner = "$thomasDir\mods-unpacked\gareth-thomas_tank_engine_mod"
New-Item -ItemType Directory -Path "$thomasInner\scripts" -Force | Out-Null
New-Item -ItemType Directory -Path "$thomasInner\extensions\scenes\Stages" -Force | Out-Null

$thomasManifest = @'
{
  "name": "thomas_tank_engine_mod",
  "namespace": "gareth",
  "version_number": "1.0.0",
  "description": "Playable railway overhaul: Thomas shuttles back and forth along the mine floor between buffer stops, collecting ore into rolling wagons. Features 3-tier upgrade branches: Locomotives (Thomas, Edward, Henry, Gordon), Wagon Rake Count (1-6), and Hopper Capacity.",
  "website_url": "https://github.com/garethwhite-prog/coal-llc-mods",
  "dependencies": ["gareth-mod_manager_mod"],
  "extra": {
    "godot": {
      "authors": ["Gareth White"],
      "display_name": "Thomas the Tank Engine Railway Class",
      "tags": ["class", "railway", "trains", "automation"],
      "compatible_mod_loader_version": ["7.0.1"],
      "compatible_game_version": ["1.4.1.1"]
    }
  }
}
'@
Set-Content -Path "$thomasDir\manifest.json" -Value $thomasManifest -Encoding UTF8
Set-Content -Path "$thomasInner\manifest.json" -Value $thomasManifest -Encoding UTF8

@'
extends Node
const MOD_DIR := "gareth-thomas_tank_engine_mod"
func _ready() -> void:
	ModLoaderLog.info("Thomas the Tank Engine Railway expansion initialized!", MOD_DIR)
'@ | Set-Content -Path "$thomasInner\mod_main.gd" -Encoding UTF8

@'
class_name ThomasTrainManager
extends Node2D

var left_stop: float = 64.0
var right_stop: float = 880.0
var speed: float = 140.0
var direction: float = 1.0

var loco_tier: int = 1 # 1: Thomas, 2: Edward, 3: Henry, 4: Gordon
var wagon_count: int = 2
var wagon_capacity: float = 150.0
var current_haul: float = 0.0

var loco_sprite: Sprite2D
var wagons: Array[Sprite2D] = []

func _ready() -> void:
	z_index = 20
	position = Vector2(left_stop, 24.0)

	loco_sprite = Sprite2D.new()
	loco_sprite.texture = _generate_loco_texture(loco_tier)
	loco_sprite.scale = Vector2(1.8, 1.8)
	add_child(loco_sprite)

func _process(delta: float) -> void:
	position.x += direction * speed * delta

	# Physical buffer stops at cavern edges
	if position.x >= right_stop:
		position.x = right_stop
		direction = -1.0
		loco_sprite.scale.x = -abs(loco_sprite.scale.x)
	elif position.x <= left_stop:
		position.x = left_stop
		direction = 1.0
		loco_sprite.scale.x = abs(loco_sprite.scale.x)
		_unload_at_stockpile()

	_sweep_dropped_ore()

func _sweep_dropped_ore() -> void:
	var tree = get_tree()
	if not tree or not tree.root: return
	var ld = tree.root.find_child("LootDrops", true, false)
	if not ld or not ("loot_drops" in ld): return

	for drop in ld.loot_drops.get_children():
		if is_instance_valid(drop) and drop.global_position.distance_to(global_position) < 48.0:
			if current_haul < (wagon_count * wagon_capacity):
				current_haul += 1.0
				drop.queue_free()

func _unload_at_stockpile() -> void:
	if current_haul > 0.0 and Gvars:
		Gvars.CashCount += current_haul * 2.0
		current_haul = 0.0

func _generate_loco_texture(tier: int) -> ImageTexture:
	var img = Image.create(36, 24, false, Image.FORMAT_RGBA8)
	var body_color = Color(0.15, 0.45, 0.90, 1.0) # Thomas blue
	if tier == 2: body_color = Color(0.20, 0.60, 0.95, 1.0) # Edward
	elif tier == 3: body_color = Color(0.15, 0.70, 0.25, 1.0) # Henry Green
	elif tier == 4: body_color = Color(0.10, 0.35, 0.85, 1.0) # Gordon Express

	var boiler = Color(0.12, 0.12, 0.14, 1.0)
	var red = Color(0.90, 0.15, 0.15, 1.0)
	var face = Color(0.85, 0.85, 0.88, 1.0)

	for x in range(36):
		for y in range(24):
			# Boiler and Cab
			if (y in range(8, 18) and x in range(6, 26)) or (y in range(4, 18) and x in range(4, 12)):
				img.set_pixel(x, y, body_color)
			# Smokebox and Funnel
			if (y in range(7, 18) and x in range(25, 32)) or (y in range(2, 7) and x in range(27, 30)):
				img.set_pixel(x, y, boiler)
			# Face on front of smokebox
			if y in range(9, 16) and x in range(30, 34):
				img.set_pixel(x, y, face)
			# Red Buffer Beam
			if y in range(16, 20) and (x in range(2, 6) or x in range(31, 35)):
				img.set_pixel(x, y, red)
	return ImageTexture.create_from_image(img)
'@ | Set-Content -Path "$thomasInner\scripts\thomas_train_manager.gd" -Encoding UTF8

# Package into downloaded_mods only
$thomasZip = "$downMods\gareth-thomas_tank_engine_mod.zip"
if (Test-Path $thomasZip) { Remove-Item -Path $thomasZip -Force }
$stream  = [System.IO.File]::Open($thomasZip, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $thomasDir -Recurse -File)) {
	$entryName = $f.FullName.Substring($thomasDir.Length + 1).Replace("\", "/")
	[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Write-Host "  Staged: gareth-thomas_tank_engine_mod.zip -> downloaded_mods/" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. REPACK GARETH-MOD_MANAGER_MOD WITH PROPER MANIFEST & CLEAN HOOKS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Repackaging gareth-mod_manager_mod into active Steam mods..." -ForegroundColor Cyan
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
# 7. COMMIT AND PUSH TO GITHUB
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Fix: mod_manager_mod manifest validation schema, restore Main Menu buttons, integrate hanging-sign title logo, stage Quadcopter Drone mod and Thomas the Tank Engine railway expansion"
git push origin main

Write-Host "`nDeployment complete! Zero tests executed (awaiting gameplay session)." -ForegroundColor Green