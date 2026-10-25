# ==============================================================================
# Coal LLC - Master Fix: Mod Manager is_core, Map Previews, HUD & DK Patrol
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
# 2. FIX MOD_REGISTRY.GD & MOD_MANAGER_VIEW.GD (IS_CORE RESOLUTION)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Adding is_core key to mod_registry.gd & hardening mod_manager_view.gd..." -ForegroundColor Cyan
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
	var is_core: bool = (mod_id == "gareth-mod_manager_mod")

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
	if "extra" in m and m.extra and ("godot" in m.extra) and ("display_name" in m.extra.godot):
		return str(m.extra.godot.display_name)
	var raw: String = str(m.name).replace("_mod", "").replace("mod_", "").replace("-", " ").replace("_", " ") if "name" in m else "Mod"
	return raw.capitalize()
'@ | Set-Content -Path $regPath -Encoding UTF8

$mmvPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_manager_view.gd"
$mmvCode = Get-Content $mmvPath -Raw
$mmvCode = $mmvCode.Replace('cb.disabled = m["is_core"]', 'cb.disabled = bool(m.get("is_core", false))')
Set-Content -Path $mmvPath -Value $mmvCode -Encoding UTF8
Write-Host "  Updated: mod_registry.gd and mod_manager_view.gd (is_core guarded)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. FIX MAP PREVIEW TEXTURES (LIVING CANVAS & DIAGONAL SEAMS)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Correcting map preview textures for Map 103 and Map 105..." -ForegroundColor Cyan

# 3a. Living Canvas: point to default_canvas.png
$lcHelperPath = "$repo\mods-unpacked\gareth-living_canvas_mod\mods-unpacked\gareth-living_canvas_mod\helpers\LivingCanvasHelper.gd"
$lcHelperCode = Get-Content $lcHelperPath -Raw
$lcHelperCode = $lcHelperCode.Replace('canvas_preview.png', 'default_canvas.png')
Set-Content -Path $lcHelperPath -Value $lcHelperCode -Encoding UTF8

# 3b. Diagonal Seams: Generate diagonal preview texture
$dmAssetDir = "$repo\mods-unpacked\gareth-diagonal_map_mod\mods-unpacked\gareth-diagonal_map_mod\assets"
New-Item -ItemType Directory -Path $dmAssetDir -Force | Out-Null

$dmHelperPath = "$repo\mods-unpacked\gareth-diagonal_map_mod\mods-unpacked\gareth-diagonal_map_mod\helpers\DiagonalMapHelper.gd"
@'
class_name DiagonalMapHelper
extends RefCounted

const DIAGONAL_LEVEL_ID: int = 105
const PREVIEW_PATH: String = "res://mods-unpacked/gareth-diagonal_map_mod/assets/diagonal_preview.png"

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
		custom_level.level_difficulty = GameLevel.Difficulty.REGULAR
		custom_level.unlock_description = ""
		custom_level.level_image = _get_or_create_preview()

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

static func _get_or_create_preview() -> ImageTexture:
	if FileAccess.file_exists(PREVIEW_PATH):
		var bytes = FileAccess.get_file_as_bytes(PREVIEW_PATH)
		if bytes.size() > 0:
			var img = Image.new()
			if img.load_png_from_buffer(bytes) == OK:
				return ImageTexture.create_from_image(img)

	# Generate procedural diagonal preview card
	var img = Image.create(96, 64, false, Image.FORMAT_RGBA8)
	var col1 = Color(0.18, 0.22, 0.30, 1.0)
	var col2 = Color(0.85, 0.55, 0.20, 1.0)
	var col3 = Color(0.30, 0.65, 0.85, 1.0)
	for x in range(96):
		for y in range(64):
			var diag = (x + y) % 24
			if diag < 10:
				img.set_pixel(x, y, col1)
			elif diag < 16:
				img.set_pixel(x, y, col2)
			else:
				img.set_pixel(x, y, col3)
	return ImageTexture.create_from_image(img)
'@ | Set-Content -Path $dmHelperPath -Encoding UTF8
Write-Host "  Updated: Map 103 & 105 preview textures" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. FIX ELEMENTAL AIRSTRIKE TEXTURE FACTORY IMPORTS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Preloading texture factory in dragon_strike.gd & water_bomber_strike.gd..." -ForegroundColor Cyan
$dsPath = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\dragon_strike.gd"
if (Test-Path $dsPath) {
	$dsCode = Get-Content $dsPath -Raw
	if (-not $dsCode.Contains("const Textures = preload")) {
		$dsCode = "const Textures = preload(`"res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/texture_factory.gd`")`r`n" + $dsCode
		$dsCode = $dsCode.Replace("ElementalAirstrikeTextures.", "Textures.")
		Set-Content -Path $dsPath -Value $dsCode -Encoding UTF8
	}
}

$wbPath = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\water_bomber_strike.gd"
if (Test-Path $wbPath) {
	$wbCode = Get-Content $wbPath -Raw
	if (-not $wbCode.Contains("const Textures = preload")) {
		$wbCode = "const Textures = preload(`"res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/texture_factory.gd`")`r`n" + $wbCode
		$wbCode = $wbCode.Replace("ElementalAirstrikeTextures.", "Textures.")
		Set-Content -Path $wbPath -Value $wbCode -Encoding UTF8
	}
}
Write-Host "  Updated: Elemental airstrike script imports" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. FIX DONKEY KONG GORILLA (RELOCATE OFF PIT & IMPROVE APE SPRITE)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Relocating Donkey Kong to right surface plateau (X = 420) & building ape sprite..." -ForegroundColor Cyan
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
		# Patrol on right plateau (X = 360 to 620), safely away from surface pit
		gorilla.position.x += 50.0 * delta * gorilla.get_meta("dir", 1.0)
		if gorilla.position.x > 620.0:
			gorilla.set_meta("dir", -1.0)
			gorilla.scale.x = abs(gorilla.scale.x)
		elif gorilla.position.x < 360.0:
			gorilla.set_meta("dir", 1.0)
			gorilla.scale.x = -abs(gorilla.scale.x)

		barrel_timer += delta
		if barrel_timer >= 6.0:
			barrel_timer = 0.0
			_toss_barrel(tree.current_scene, gorilla.global_position)

func _spawn_gorilla(scene: Node) -> void:
	gorilla = Node2D.new()
	gorilla.name = "DonkeyKongGorilla"
	# Spawn on far-right surface plateau, leaving mine entrance wide open
	gorilla.global_position = Vector2(420, -32)
	gorilla.set_meta("dir", 1.0)

	var spr = Sprite2D.new()
	spr.texture = _create_gorilla_texture()
	spr.scale = Vector2(1.8, 1.8)
	gorilla.add_child(spr)
	scene.add_child(gorilla)

func _create_gorilla_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var fur = Color(0.28, 0.14, 0.06, 1.0)
	var chest = Color(0.70, 0.50, 0.32, 1.0)
	var tie = Color(0.95, 0.15, 0.15, 1.0)
	var eye = Color(1.0, 1.0, 1.0, 1.0)
	var pupil = Color(0.05, 0.05, 0.05, 1.0)

	for x in range(32):
		for y in range(32):
			# Head
			if y in range(4, 12) and x in range(10, 22):
				img.set_pixel(x, y, fur)
			# Broad ape torso
			elif y in range(12, 28) and x in range(7, 25):
				img.set_pixel(x, y, fur)
			# Arms
			elif y in range(13, 29) and (x in range(3, 8) or x in range(24, 29)):
				img.set_pixel(x, y, fur)
			# Chest plate & muzzle
			if (y in range(8, 12) and x in range(12, 20)) or (y in range(14, 22) and x in range(11, 21)):
				img.set_pixel(x, y, chest)
			# Red tie
			if (y in range(13, 24) and x in range(15, 17)) or (y in range(22, 26) and x in range(14, 18)):
				img.set_pixel(x, y, tie)
			# Eyes
			if y in range(6, 8) and (x == 13 or x == 18):
				img.set_pixel(x, y, eye)
			if y == 7 and (x == 14 or x == 19):
				img.set_pixel(x, y, pupil)

	return ImageTexture.create_from_image(img)

func _create_barrel_texture() -> ImageTexture:
	var img = Image.create(20, 20, false, Image.FORMAT_RGBA8)
	var wood_dark = Color(0.42, 0.24, 0.10, 1.0)
	var wood_light = Color(0.58, 0.36, 0.18, 1.0)
	var metal_band = Color(0.24, 0.24, 0.26, 1.0)

	for x in range(20):
		for y in range(20):
			var dx = float(x - 10)
			var dy = float(y - 10)
			if dx*dx + dy*dy <= 85.0:
				if y in range(4, 7) or y in range(13, 16):
					img.set_pixel(x, y, metal_band)
				elif x % 3 == 0:
					img.set_pixel(x, y, wood_dark)
				else:
					img.set_pixel(x, y, wood_light)

	return ImageTexture.create_from_image(img)

func _toss_barrel(scene: Node, pos: Vector2) -> void:
	var barrel = Area2D.new()
	barrel.name = "RollingBarrel"
	barrel.global_position = pos

	var spr = Sprite2D.new()
	spr.texture = _create_barrel_texture()
	spr.scale = Vector2(1.7, 1.7)
	barrel.add_child(spr)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 15.0
	col.shape = shape
	barrel.add_child(col)

	barrel.body_entered.connect(func(body):
		if body.is_in_group("player") or body.name == "Player":
			if "velocity" in body:
				body.velocity = Vector2.ZERO
			body.set_physics_process(false)

			var toast = Label.new()
			toast.text = "★ BONK! STUNNED! ★"
			toast.modulate = Color(1.0, 0.85, 0.2)
			toast.position = Vector2(-60, -40)
			body.add_child(toast)

			var tw = body.create_tween()
			tw.tween_interval(3.0)
			tw.tween_callback(func():
				body.set_physics_process(true)
				toast.queue_free()
			)
			barrel.queue_free()
	)

	scene.add_child(barrel)
	var b_tween = barrel.create_tween()
	b_tween.parallel().tween_property(barrel, "global_position:x", 180.0, 4.0)
	b_tween.parallel().tween_property(barrel, "global_position:y", 650.0, 6.0)
	b_tween.parallel().tween_property(barrel, "rotation", 14.0, 6.0)
	b_tween.tween_callback(barrel.queue_free)
'@ | Set-Content -Path $dkSpawner -Encoding UTF8
Write-Host "  Updated: Donkey Kong gorilla patrol & barrel trajectory" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. RESOLVE BOTTOM-RIGHT HUD OVERLAP (CLEAN VERTICAL STACK)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Harmonizing bottom-right HUD docking geometry (360px width, staggered offsets)..." -ForegroundColor Cyan

# 6a. Speed Controller (Bottom Slot: -44 to -14)
$scPath = "$repo\mods-unpacked\gareth-game_speed_mod\mods-unpacked\gareth-game_speed_mod\scripts\speed_controller.gd"
$scCode = Get-Content $scPath -Raw
$scCode = $scCode.Replace('panel.offset_left = -324.0', 'panel.offset_left = -356.0')
$scCode = $scCode.Replace('panel.offset_left = -316.0', 'panel.offset_left = -356.0')
$scCode = $scCode.Replace('panel.offset_left = -264.0', 'panel.offset_left = -356.0')
$scCode = $scCode.Replace('panel.offset_right = -16.0', 'panel.offset_right = -20.0')
$scCode = $scCode.Replace('panel.offset_right = -24.0', 'panel.offset_right = -20.0')
$scCode = $scCode.Replace('panel.offset_top = -48.0', 'panel.offset_top = -44.0')
$scCode = $scCode.Replace('panel.offset_top = -46.0', 'panel.offset_top = -44.0')
$scCode = $scCode.Replace('panel.offset_bottom = -12.0', 'panel.offset_bottom = -14.0')
$scCode = $scCode.Replace('panel.offset_bottom = -16.0', 'panel.offset_bottom = -14.0')
Set-Content -Path $scPath -Value $scCode -Encoding UTF8

# 6b. Amazon Button (Middle Slot: -80 to -48)
$amzPath = "$repo\mods-unpacked\gareth-scrap_and_delivery_mod\mods-unpacked\gareth-scrap_and_delivery_mod\scripts\amazon_delivery_manager.gd"
$amzCode = Get-Content $amzPath -Raw
$amzCode = $amzCode.Replace('hud_btn.offset_left = -324.0', 'hud_btn.offset_left = -356.0')
$amzCode = $amzCode.Replace('hud_btn.offset_left = -316.0', 'hud_btn.offset_left = -356.0')
$amzCode = $amzCode.Replace('hud_btn.offset_left = -110.0', 'hud_btn.offset_left = -356.0')
$amzCode = $amzCode.Replace('hud_btn.offset_right = -16.0', 'hud_btn.offset_right = -20.0')
$amzCode = $amzCode.Replace('hud_btn.offset_right = -24.0', 'hud_btn.offset_right = -20.0')
$amzCode = $amzCode.Replace('hud_btn.offset_top = -86.0', 'hud_btn.offset_top = -80.0')
$amzCode = $amzCode.Replace('hud_btn.offset_top = -82.0', 'hud_btn.offset_top = -80.0')
$amzCode = $amzCode.Replace('hud_btn.offset_bottom = -50.0', 'hud_btn.offset_bottom = -48.0')
$amzCode = $amzCode.Replace('hud_btn.offset_bottom = -54.0', 'hud_btn.offset_bottom = -48.0')
Set-Content -Path $amzPath -Value $amzCode -Encoding UTF8

# 6c. Air Wings Panel (Top Slot: -128 to -84)
$eamPath = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\elemental_airstrike_manager.gd"
$eamCode = Get-Content $eamPath -Raw
$eamCode = $eamCode.Replace('panel.offset_left = -324.0', 'panel.offset_left = -356.0')
$eamCode = $eamCode.Replace('panel.offset_left = -316.0', 'panel.offset_left = -356.0')
$eamCode = $eamCode.Replace('panel.offset_left = -264.0', 'panel.offset_left = -356.0')
$eamCode = $eamCode.Replace('panel.offset_right = -16.0', 'panel.offset_right = -20.0')
$eamCode = $eamCode.Replace('panel.offset_right = -24.0', 'panel.offset_right = -20.0')
$eamCode = $eamCode.Replace('panel.offset_top = -126.0', 'panel.offset_top = -128.0')
$eamCode = $eamCode.Replace('panel.offset_top = -120.0', 'panel.offset_top = -128.0')
$eamCode = $eamCode.Replace('panel.offset_bottom = -86.0', 'panel.offset_bottom = -84.0')
$eamCode = $eamCode.Replace('panel.offset_bottom = -92.0', 'panel.offset_bottom = -84.0')
Set-Content -Path $eamPath -Value $eamCode -Encoding UTF8
Write-Host "  Updated: HUD column alignment (Speed: -44:-14, Amazon: -80:-48, AirWings: -128:-84)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 7. ADD SEARCH, SORT & AFFORDABLE FILTERS TO BONUS UPGRADES PANEL
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Creating passive_bonuses.hooks.gd (Search, Sort & Affordable on Bonus Upgrades)..." -ForegroundColor Cyan
$pbHookDir = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scenes\Interfaces\Management"
@'
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
'@ | Set-Content -Path "$pbHookDir\passive_bonuses.hooks.gd" -Encoding UTF8

# Register hook in mod_manager_mod mod_main.gd
$mmmPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\mod_main.gd"
$mmmCode = Get-Content $mmmPath -Raw
if (-not $mmmCode.Contains("passive_bonuses.hooks.gd")) {
	$mmmCode = $mmmCode.Replace(
		'func _init() -> void:',
		"func _init() -> void:`r`n`tModLoaderMod.install_script_hooks(`"res://scenes/Interfaces/Management/passive_bonuses.gd`", `"res://mods-unpacked/gareth-mod_manager_mod/extensions/scenes/Interfaces/Management/passive_bonuses.hooks.gd`")"
	)
	Set-Content -Path $mmmPath -Value $mmmCode -Encoding UTF8
}
Write-Host "  Installed: passive_bonuses search and sort hooks" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 8. REPACK ALL MOD ARCHIVES TO STEAM
# ------------------------------------------------------------------------------
Write-Host "`n>>> 8. Repackaging updated mods to Steam..." -ForegroundColor Cyan
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

$modsToRepack = @(
	"gareth-mod_manager_mod",
	"gareth-living_canvas_mod",
	"gareth-diagonal_map_mod",
	"gareth-elemental_airstrikes_mod",
	"gareth-donkey_kong_mod",
	"gareth-game_speed_mod",
	"gareth-scrap_and_delivery_mod"
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
# 9. RUN AUDIT & COMMIT
# ------------------------------------------------------------------------------
Write-Host "`n>>> 9. Running static CI/CD regression check..." -ForegroundColor Cyan
& "$repo\tests\test_runner.ps1" -RepoPath $repo

Write-Host "`n>>> 10. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Fix: Add is_core to ModRegistry, restore Map 103/105 previews, fix airstrike imports, relocate DK off pit, align HUD, and add Bonus filters"
git push origin main

Write-Host "`nAll fixes deployed cleanly!" -ForegroundColor Green