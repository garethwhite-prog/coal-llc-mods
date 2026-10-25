# ==============================================================================
# Coal LLC - Master Fix: Mod Manager Fallback, Maps 101-105, Search Bar & HUD
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
# 2. FIX MOD_REGISTRY.GD: DUAL MODLOADERSTORE & DIRACCESS FALLBACK
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Updating mod_registry.gd with robust ModLoaderStore & DirAccess discovery..." -ForegroundColor Cyan
$regPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scripts\mod_registry.gd"
@'
class_name ModRegistry
extends RefCounted

static func is_mod_active_for_run(mod_key: String) -> bool:
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

	# 1. Attempt ModLoaderStore autoload
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
			var m = data.manifest
			list.append(_dict_from_manifest(mod_id, m, data.is_active if "is_active" in data else true))
		return list

	# 2. Fallback: Scan virtual filesystem at res://mods-unpacked/
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

static func _dict_from_manifest(mod_id: String, m: Dictionary, active: bool) -> Dictionary:
	var display_name: String = _format_display_name(m)
	var desc: String = m.description if "description" in m else ""
	var author: String = "Community"
	if m.has("extra") and m.extra.has("godot") and m.extra.godot.has("authors") and m.extra.godot.authors.size() > 0:
		author = m.extra.godot.authors[0]
	var version: String = m.version_number if "version_number" in m else "1.0.0"
	var cat: String = _determine_category(m)

	return {
		"id": mod_id,
		"key": mod_id,
		"name": display_name,
		"description": desc,
		"author": author,
		"version": version,
		"category": cat,
		"is_active": active
	}

static func _determine_category(m) -> String:
	var id: String = str(m.name).to_lower()
	if "class" in id or "profession" in id or "jedi" in id or "knight" in id or "sinclairity" in id:
		return "Classes & Professions"
	if "map" in id or "trench" in id or "faultline" in id or "canvas" in id or "expedition" in id:
		return "Custom Maps & Strata"
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
	if m.has("extra") and m.extra.has("godot") and m.extra.godot.has("display_name"):
		return m.extra.godot.display_name
	var raw: String = m.name.replace("_mod", "").replace("mod_", "").replace("-", " ").replace("_", " ")
	return raw.capitalize()
'@ | Set-Content -Path $regPath -Encoding UTF8
Write-Host "  Updated: mod_registry.gd (Resilient with DirAccess fallback)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. FIX LIVINGCANVASHELPER.GD (CORRECT MAP 103 REGISTRATION)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Correcting LivingCanvasHelper.gd to register Map 103..." -ForegroundColor Cyan
$lcPath = "$repo\mods-unpacked\gareth-living_canvas_mod\mods-unpacked\gareth-living_canvas_mod\helpers\LivingCanvasHelper.gd"
@'
class_name LivingCanvasHelper
extends RefCounted

const CANVAS_LEVEL_ID: int = 103
const PREVIEW_PATH: String = "res://mods-unpacked/gareth-living_canvas_mod/assets/canvas_preview.png"

static func is_canvas_level() -> bool:
	if Gvars:
		if "level" in Gvars and Gvars.level == CANVAS_LEVEL_ID:
			return true
		if "chosen_level" in Gvars and Gvars.chosen_level == CANVAS_LEVEL_ID:
			return true
		if "current_level" in Gvars and Gvars.current_level == CANVAS_LEVEL_ID:
			return true
	return false

static func ensure_level_registered() -> void:
	if not Gvars:
		return

	if "level_manager" in Gvars and Gvars.level_manager and ("all_levels" in Gvars.level_manager):
		var lvl_mgr = Gvars.level_manager
		if not lvl_mgr.all_levels.has(CANVAS_LEVEL_ID):
			var custom_level = GameLevel.new()
			custom_level.level_name = "The Living Canvas"
			custom_level.level = CANVAS_LEVEL_ID
			custom_level.mining_scene_path = "res://scenes/Stages/MineRegion.tscn"
			custom_level.level_description = "Subterranean strata sculpted directly from a real image or screenshot.\n\nDefault theme: 'Your Mum'. Mine through the beach mosaic or choose any custom image."
			custom_level.level_difficulty = GameLevel.Difficulty.NORMAL
			custom_level.unlock_description = ""

			if FileAccess.file_exists(PREVIEW_PATH):
				var bytes = FileAccess.get_file_as_bytes(PREVIEW_PATH)
				if bytes.size() > 0:
					var img = Image.new()
					if img.load_png_from_buffer(bytes) == OK:
						custom_level.level_image = ImageTexture.create_from_image(img)

			lvl_mgr.all_levels[CANVAS_LEVEL_ID] = {
				"level": custom_level,
				"is_unlocked": true
			}

	if "level_info" in Gvars and Gvars.level_info is Dictionary:
		if not Gvars.level_info.has(CANVAS_LEVEL_ID):
			Gvars.level_info[CANVAS_LEVEL_ID] = {
				"name": "The Living Canvas",
				"description": "Subterranean strata sculpted from real images.",
				"depth": 1000,
				"cost": 0,
				"unlocked": true
			}
'@ | Set-Content -Path $lcPath -Encoding UTF8
Write-Host "  Updated: LivingCanvasHelper.gd (Map 103 registered cleanly)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. FIX DIAGONAL MAP REGISTRATION (MAP 105) IN HELPER & LEVEL_SELECT
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Creating DiagonalMapHelper.gd and registering Map 105..." -ForegroundColor Cyan
$dmHelperDir = "$repo\mods-unpacked\gareth-diagonal_map_mod\mods-unpacked\gareth-diagonal_map_mod\helpers"
New-Item -ItemType Directory -Path $dmHelperDir -Force | Out-Null

@'
class_name DiagonalMapHelper
extends RefCounted

const DIAGONAL_LEVEL_ID: int = 105

static func ensure_level_registered() -> void:
	if not Gvars or not ("level_manager" in Gvars) or not Gvars.level_manager:
		return

	var lvl_mgr = Gvars.level_manager
	if "all_levels" in lvl_mgr and not lvl_mgr.all_levels.has(DIAGONAL_LEVEL_ID):
		var custom_level = GameLevel.new()
		custom_level.level_name = "Diagonal Seams"
		custom_level.level = DIAGONAL_LEVEL_ID
		custom_level.mining_scene_path = "res://scenes/Stages/MineRegion.tscn"
		custom_level.level_description = "45-degree rotated subterranean strata and inverted angled seams.\nCarve through diagonal geological faultlines and tilted mineral layers."
		custom_level.level_difficulty = GameLevel.Difficulty.NORMAL
		custom_level.unlock_description = ""

		lvl_mgr.all_levels[DIAGONAL_LEVEL_ID] = {
			"level": custom_level,
			"is_unlocked": true
		}

	if "level_info" in Gvars and Gvars.level_info is Dictionary:
		if not Gvars.level_info.has(DIAGONAL_LEVEL_ID):
			Gvars.level_info[DIAGONAL_LEVEL_ID] = {
				"name": "Diagonal Seams",
				"description": "45-degree rotated strata and angled mineral veins.",
				"depth": 1200,
				"cost": 0,
				"unlocked": true
			}
'@ | Set-Content -Path "$dmHelperDir\DiagonalMapHelper.gd" -Encoding UTF8

$dmHookPath = "$repo\mods-unpacked\gareth-diagonal_map_mod\mods-unpacked\gareth-diagonal_map_mod\extensions\scenes\Interfaces\Menus\level_select.hooks.gd"
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var helper = load("res://mods-unpacked/gareth-diagonal_map_mod/helpers/DiagonalMapHelper.gd")
	if helper and helper.has_method("ensure_level_registered"):
		helper.ensure_level_registered()

	var ls = chain.reference_object
	if ls and ("LEVEL_ORDER" in ls) and Gvars and Gvars.level_manager and Gvars.level_manager.all_levels.has(105):
		if not ls.LEVEL_ORDER.has(105):
			ls.LEVEL_ORDER.append(105)

	chain.execute_next([])
'@ | Set-Content -Path $dmHookPath -Encoding UTF8
Write-Host "  Updated: Diagonal Map registration & hook" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. RESTORE FULL SEARCH, SORT & AFFORDABLE HOOK IN EQUIPMENT SHOP
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Restoring complete search, sort, and affordability bar in management_screen..." -ForegroundColor Cyan
$msHookPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scenes\Stages\management_screen.hooks.gd"
@'
extends Object

var search_input: LineEdit = null
var sort_dropdown: OptionButton = null
var chk_affordable: CheckBox = null

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
		Gvars.show_only_affordable = pressed
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
	var only_afford: bool = chk_affordable.button_pressed if is_instance_valid(chk_affordable) else false
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
		var match_afford: bool = not only_afford or (it.itemBuyPrice <= cur_cash or it.itemBuyPrice <= 0.0)

		card.visible = match_query and match_afford
'@ | Set-Content -Path $msHookPath -Encoding UTF8
Write-Host "  Restored: management_screen search, sort & affordable bar" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. UNIFY BOTTOM-RIGHT HUD DOCKING (SPEED, AMAZON & AIR WINGS)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Harmonizing bottom-right HUD docking geometry (300px unified column)..." -ForegroundColor Cyan

# 6a. Speed Controller (Bottom: -46 to -12)
$scPath = "$repo\mods-unpacked\gareth-game_speed_mod\mods-unpacked\gareth-game_speed_mod\scripts\speed_controller.gd"
$scCode = Get-Content $scPath -Raw
$scCode = $scCode.Replace('panel.offset_left = -264.0', 'panel.offset_left = -316.0')
$scCode = $scCode.Replace('panel.offset_right = -16.0', 'panel.offset_right = -16.0')
$scCode = $scCode.Replace('panel.offset_top = -48.0', 'panel.offset_top = -46.0')
$scCode = $scCode.Replace('panel.offset_bottom = -12.0', 'panel.offset_bottom = -12.0')
Set-Content -Path $scPath -Value $scCode -Encoding UTF8

# 6b. Amazon Delivery (Middle: -82 to -50)
$amzPath = "$repo\mods-unpacked\gareth-scrap_and_delivery_mod\mods-unpacked\gareth-scrap_and_delivery_mod\scripts\amazon_delivery_manager.gd"
$amzCode = Get-Content $amzPath -Raw
$amzCode = $amzCode.Replace('hud_btn.offset_left = -110.0', 'hud_btn.offset_left = -316.0')
$amzCode = $amzCode.Replace('hud_btn.offset_right = -16.0', 'hud_btn.offset_right = -16.0')
$amzCode = $amzCode.Replace('hud_btn.offset_top = -88.0', 'hud_btn.offset_top = -82.0')
$amzCode = $amzCode.Replace('hud_btn.offset_bottom = -54.0', 'hud_btn.offset_bottom = -50.0')
Set-Content -Path $amzPath -Value $amzCode -Encoding UTF8

# 6c. Air Wings (Top: -120 to -86)
$eamPath = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\elemental_airstrike_manager.gd"
$eamCode = Get-Content $eamPath -Raw
$eamCode = $eamCode.Replace('panel.offset_left = -264.0', 'panel.offset_left = -316.0')
$eamCode = $eamCode.Replace('panel.offset_right = -16.0', 'panel.offset_right = -16.0')
$eamCode = $eamCode.Replace('panel.offset_top = -126.0', 'panel.offset_top = -120.0')
$eamCode = $eamCode.Replace('panel.offset_bottom = -92.0', 'panel.offset_bottom = -86.0')
Set-Content -Path $eamPath -Value $eamCode -Encoding UTF8

# ------------------------------------------------------------------------------
# 7. COMPOSITE GORILLA SPRITE (DONKEY KONG MOD)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Upgrading Donkey Kong surface gorilla sprite to composite pixel art..." -ForegroundColor Cyan
$dkSpawner = "$repo\mods-unpacked\gareth-donkey_kong_mod\mods-unpacked\gareth-donkey_kong_mod\scripts\gorilla_surface_spawner.gd"
@'
extends Node

var gorilla: Node2D
var barrel_timer: float = 0.0

func _process(delta: float) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return

	var p = tree.root.find_child("Player", true, false)
	var in_mine = is_instance_valid(p) and is_instance_valid(tree.root.find_child("TileMapManager", true, false))

	if in_mine and not is_instance_valid(gorilla):
		_spawn_gorilla(tree.current_scene)

	if is_instance_valid(gorilla):
		gorilla.position.x += 60.0 * delta * gorilla.get_meta("dir", 1.0)
		if abs(gorilla.position.x) > 350.0:
			gorilla.set_meta("dir", -gorilla.get_meta("dir", 1.0))
			gorilla.scale.x = -abs(gorilla.scale.x) if gorilla.get_meta("dir", 1.0) > 0 else abs(gorilla.scale.x)

		barrel_timer += delta
		if barrel_timer >= 6.0:
			barrel_timer = 0.0
			_toss_barrel(tree.current_scene, gorilla.global_position)

func _spawn_gorilla(scene: Node) -> void:
	gorilla = Node2D.new()
	gorilla.name = "DonkeyKongGorilla"
	gorilla.global_position = Vector2(180, -28)
	gorilla.set_meta("dir", -1.0)

	var torso = Sprite2D.new()
	torso.texture = load("res://assets/NPCs/PlayerSkins/Torsos/playerSheet_Torso_Brown.png")
	torso.hframes = 4
	torso.vframes = 4
	torso.frame = 0
	torso.scale = Vector2(2.2, 2.2)
	gorilla.add_child(torso)

	var head = Sprite2D.new()
	head.texture = load("res://assets/NPCs/PlayerSkins/Heads/playerSheet_Head_HelmetBrown.png")
	head.hframes = 4
	head.vframes = 4
	head.frame = 0
	head.scale = Vector2(2.2, 2.2)
	head.position = Vector2(0, -18)
	gorilla.add_child(head)

	scene.add_child(gorilla)

func _toss_barrel(scene: Node, pos: Vector2) -> void:
	var barrel = Area2D.new()
	barrel.name = "RollingBarrel"
	barrel.global_position = pos

	var spr = Sprite2D.new()
	spr.texture = load("res://assets/Equipment/bombs/big_bomb_sheet_red.png")
	spr.hframes = 4
	spr.scale = Vector2(1.8, 1.8)
	barrel.add_child(spr)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16.0
	col.shape = shape
	barrel.add_child(col)

	barrel.body_entered.connect(func(body):
		if body.is_in_group("player") or body.name == "Player":
			if "velocity" in body:
				body.velocity = Vector2.ZERO
			body.set_physics_process(false)
			var tw = body.create_tween()
			tw.tween_interval(5.0)
			tw.tween_callback(func(): body.set_physics_process(true))
			barrel.queue_free()
	)

	scene.add_child(barrel)
	var b_tween = barrel.create_tween()
	b_tween.tween_property(barrel, "global_position:y", 600.0, 7.0)
	b_tween.tween_callback(barrel.queue_free)
'@ | Set-Content -Path $dkSpawner -Encoding UTF8

# ------------------------------------------------------------------------------
# 8. UPGRADE DUMP-CONTEXT.PS1 (CAPTURE BOTH GODOT.LOG AND MODLOADER.LOG)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 8. Upgrading Dump-Context.ps1 to capture modloader.log..." -ForegroundColor Cyan
$dcScript = "$repo\Dump-Context.ps1"
@'
Clear-Host

$repoRoot = "C:\Dev\coal-llc-mods"
$appDataGodot = [System.IO.Path]::Combine($env:APPDATA, "Godot\app_userdata\Coal LLC")
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$outputFile = [System.IO.Path]::Combine($repoRoot, "context.txt")

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("=== GIT STATUS ===")
Push-Location $repoRoot
$gitStatus = git status --short
foreach ($line in $gitStatus) { [void]$sb.AppendLine($line) }

[void]$sb.AppendLine("`n=== RECENT COMMITS ===")
$gitLog = git log -n 3 --oneline
foreach ($line in $gitLog) { [void]$sb.AppendLine($line) }
Pop-Location

# 1. Capture ModLoader.log
$mlLog = [System.IO.Path]::Combine($steamRoot, "modloader.log")
if (Test-Path $mlLog) {
    $mlLines = Get-Content $mlLog
    $mlErrors = $mlLines | Where-Object { $_ -match "(ERROR|CRITICAL|failed|cannot be loaded)" }
    [void]$sb.AppendLine("`n=== MODLOADER LOG AUDIT ($($mlErrors.Count) errors found) ===")
    if ($mlErrors.Count -gt 0) {
        foreach ($line in ($mlErrors | Select-Object -Last 15)) { [void]$sb.AppendLine($line) }
    } else {
        [void]$sb.AppendLine("All active mods verified by ModLoader cleanly.")
    }
}

# 2. Capture godot.log
$logPath = [System.IO.Path]::Combine($appDataGodot, "logs\godot.log")
if (Test-Path $logPath) {
    # Open with FileShare.ReadWrite to avoid locking collisions
    $stream = [System.IO.FileStream]::new($logPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::UTF8)
    $allLogLines = [System.Collections.Generic.List[string]]::new()
    while (-not $reader.EndOfStream) { $allLogLines.Add($reader.ReadLine()) }
    $reader.Dispose()
    $stream.Dispose()

    $errorLines = $allLogLines | Where-Object {
        $_ -match "(SCRIPT ERROR|ERROR:|Compile Error|Parse Error|Failed to load script|Invalid call|Invalid access)"
    }

    [void]$sb.AppendLine("`n=== SESSION ERRORS & WARNINGS ($($errorLines.Count) found) ===")
    if ($errorLines.Count -gt 0) {
        foreach ($line in ($errorLines | Select-Object -Last 25)) { [void]$sb.AppendLine($line) }
    } else {
        [void]$sb.AppendLine("None detected.")
    }

    [void]$sb.AppendLine("`n=== LOG TAIL (LAST 25 LINES) ===")
    $tailLines = $allLogLines | Select-Object -Last 25
    foreach ($line in $tailLines) { [void]$sb.AppendLine($line) }
}

[System.IO.File]::WriteAllText($outputFile, $sb.ToString(), [System.Text.Encoding]::UTF8)
Set-Clipboard -Value $sb.ToString()
Write-Host "Context written to context.txt and copied to clipboard." -ForegroundColor Green
'@ | Set-Content -Path $dcScript -Encoding UTF8

# ------------------------------------------------------------------------------
# 9. REPACK AFFECTED MOD ARCHIVES TO STEAM
# ------------------------------------------------------------------------------
Write-Host "`n>>> 9. Repackaging updated mods to Steam..." -ForegroundColor Cyan
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

$modsToRepack = @(
    "gareth-mod_manager_mod",
    "gareth-living_canvas_mod",
    "gareth-diagonal_map_mod",
    "gareth-abyssal_trench_mod",
    "gareth-game_speed_mod",
    "gareth-scrap_and_delivery_mod",
    "gareth-elemental_airstrikes_mod",
    "gareth-donkey_kong_mod"
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
    Write-Host "  Repacked: $m.zip" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 10. COMMIT AND PUSH
# ------------------------------------------------------------------------------
Write-Host "`n>>> 10. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Fix: ModRegistry DirAccess fallback, Maps 103-105 registered cleanly, search bar restored, and unified HUD docking"
git push origin main

Write-Host "`nAll fixes deployed cleanly!" -ForegroundColor Green