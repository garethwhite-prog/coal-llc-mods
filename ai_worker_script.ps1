# ==============================================================================
# Coal LLC - Master Fix: Mod Manager, Custom Maps, Sky Tile Guard & HUD Column
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
# 2. FIX MOD_REGISTRY.GD: UNTYPED MANIFEST COMPATIBILITY (OBJECT & DICT)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Updating mod_registry.gd with universal ModManifest handling..." -ForegroundColor Cyan
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
Write-Host "  Updated: mod_registry.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. FIX HARDWARE BOOSTER CHUNK HOOK (PREVENT SKY TILE GENERATION)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Protecting sky and surface coordinates (Y <= 0) in hardware_booster_mod..." -ForegroundColor Cyan
$hwHookPath = "$repo\mods-unpacked\gareth-hardware_booster_mod\mods-unpacked\gareth-hardware_booster_mod\extensions\scenes\tilemaps\tile_map_chunk.hooks.gd"
@'
extends Object

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	# Execute base game chunk generation first so surface rows and empty sky are respected
	chain.execute_next([noise])

	var chunk = chain.reference_object
	if not chunk or not ("tiles" in chunk) or not chunk.has_method("array_to_global_pos"):
		return

	# Only apply hardware worker acceleration to subterranean regions (Y > 0)
	for idx in range(chunk.tiles.size()):
		var global_pos: Vector2i = Vector2i(chunk.array_to_global_pos(idx))
		if global_pos.y <= 0:
			# Ensure sky and surface air remain completely open
			chunk.tiles[idx] = chunk.Tiles.EMPTY
			chunk.build_tile(idx)
'@ | Set-Content -Path $hwHookPath -Encoding UTF8
Write-Host "  Updated: hardware_booster_mod (sky tiles protected)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. FIX MAP 103 (THE LIVING CANVAS) HELPER & HOOK
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Registering Map 103 (The Living Canvas) with Difficulty.REGULAR..." -ForegroundColor Cyan
$lcHelperPath = "$repo\mods-unpacked\gareth-living_canvas_mod\mods-unpacked\gareth-living_canvas_mod\helpers\LivingCanvasHelper.gd"
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
	if not Gvars or not ("level_manager" in Gvars) or not Gvars.level_manager:
		return

	var lvl_mgr = Gvars.level_manager
	if "all_levels" in lvl_mgr and not lvl_mgr.all_levels.has(CANVAS_LEVEL_ID):
		var custom_level = GameLevel.new()
		custom_level.level_name = "The Living Canvas"
		custom_level.level = CANVAS_LEVEL_ID
		custom_level.mining_scene_path = "res://scenes/Stages/MineRegion.tscn"
		custom_level.level_description = "Subterranean strata sculpted directly from a real image or screenshot.\n\nDefault theme: 'Your Mum'. Mine through the beach mosaic or choose any custom image."
		custom_level.level_difficulty = GameLevel.Difficulty.REGULAR
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
'@ | Set-Content -Path $lcHelperPath -Encoding UTF8

$lcHookPath = "$repo\mods-unpacked\gareth-living_canvas_mod\mods-unpacked\gareth-living_canvas_mod\extensions\scenes\Interfaces\Menus\level_select.hooks.gd"
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
	if helper_script and helper_script.has_method("ensure_level_registered"):
		helper_script.ensure_level_registered()

	var ls = chain.reference_object
	if ls and ("LEVEL_ORDER" in ls):
		if not ls.LEVEL_ORDER.has(103):
			ls.LEVEL_ORDER.append(103)

	chain.execute_next([])
'@ | Set-Content -Path $lcHookPath -Encoding UTF8

# ------------------------------------------------------------------------------
# 5. FIX MAP 104 (ABYSSAL TRENCH) LEVEL SELECT HOOK
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Registering Map 104 (The Abyssal Trench) before execute_next..." -ForegroundColor Cyan
$atHookPath = "$repo\mods-unpacked\gareth-abyssal_trench_mod\mods-unpacked\gareth-abyssal_trench_mod\extensions\scenes\Interfaces\Menus\level_select.hooks.gd"
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-abyssal_trench_mod/helpers/AbyssalTrenchHelper.gd")
	if helper_script:
		var helper = helper_script.new()
		if helper.has_method("ensure_level_registered"):
			helper.ensure_level_registered()

	var ls = chain.reference_object
	if ls and ("LEVEL_ORDER" in ls):
		var tid: int = 104
		if not ls.LEVEL_ORDER.has(tid):
			ls.LEVEL_ORDER.append(tid)

	chain.execute_next([])
'@ | Set-Content -Path $atHookPath -Encoding UTF8

# ------------------------------------------------------------------------------
# 6. FIX MAP 105 (DIAGONAL SEAMS) HELPER & HOOK
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Registering Map 105 (Diagonal Seams) with Difficulty.REGULAR..." -ForegroundColor Cyan
$dmHelperPath = "$repo\mods-unpacked\gareth-diagonal_map_mod\mods-unpacked\gareth-diagonal_map_mod\helpers\DiagonalMapHelper.gd"
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
		custom_level.level_difficulty = GameLevel.Difficulty.REGULAR
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
'@ | Set-Content -Path $dmHelperPath -Encoding UTF8

$dmHookPath = "$repo\mods-unpacked\gareth-diagonal_map_mod\mods-unpacked\gareth-diagonal_map_mod\extensions\scenes\Interfaces\Menus\level_select.hooks.gd"
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var helper = load("res://mods-unpacked/gareth-diagonal_map_mod/helpers/DiagonalMapHelper.gd")
	if helper and helper.has_method("ensure_level_registered"):
		helper.ensure_level_registered()

	var ls = chain.reference_object
	if ls and ("LEVEL_ORDER" in ls):
		if not ls.LEVEL_ORDER.has(105):
			ls.LEVEL_ORDER.append(105)

	chain.execute_next([])
'@ | Set-Content -Path $dmHookPath -Encoding UTF8

# ------------------------------------------------------------------------------
# 7. FIX EQUIPMENT SHOP SEARCH, SORT & LOCAL AFFORDABLE FILTER
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Hardening search, sort & Affordable Only filter (local state)..." -ForegroundColor Cyan
$msHookPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scenes\Stages\management_screen.hooks.gd"
@'
extends Object

var search_input: LineEdit = null
var sort_dropdown: OptionButton = null
var chk_affordable: CheckBox = null
var is_affordable_only: bool = false

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
		is_affordable_only = pressed
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
		var match_afford: bool = not is_affordable_only or (it.itemBuyPrice <= cur_cash or it.itemBuyPrice <= 0.0)

		card.visible = match_query and match_afford
'@ | Set-Content -Path $msHookPath -Encoding UTF8
Write-Host "  Updated: management_screen.hooks.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 8. UPGRADE DONKEY KONG: GORILLA SPRITE & ROLLING WOODEN BARREL
# ------------------------------------------------------------------------------
Write-Host "`n>>> 8. Upgrading Donkey Kong with authentic ape silhouette & wooden rolling barrels..." -ForegroundColor Cyan
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

	var spr = Sprite2D.new()
	spr.texture = _create_gorilla_texture()
	spr.scale = Vector2(2.5, 2.5)
	gorilla.add_child(spr)
	scene.add_child(gorilla)

func _create_gorilla_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var fur = Color(0.35, 0.18, 0.08, 1.0)
	var tan_skin = Color(0.72, 0.52, 0.35, 1.0)
	var tie_red = Color(0.9, 0.15, 0.15, 1.0)
	var eye = Color(1.0, 1.0, 1.0, 1.0)

	for x in range(32):
		for y in range(32):
			# Broad gorilla torso and massive ape arms
			if (y in range(12, 28) and x in range(6, 26)) or (y in range(14, 30) and (x in range(2, 8) or x in range(24, 30))):
				img.set_pixel(x, y, fur)
			# Gorilla head and brow ridge
			elif (y in range(4, 13) and x in range(10, 22)):
				img.set_pixel(x, y, fur)
			# Tan muzzle and chest plate
			elif (y in range(9, 13) and x in range(12, 20)) or (y in range(15, 24) and x in range(11, 21)):
				img.set_pixel(x, y, tan_skin)
			# Classic DK Red Tie
			elif (y in range(15, 25) and (x in range(15, 17) or (y in range(22, 25) and x in range(14, 18)))):
				img.set_pixel(x, y, tie_red)
			# Eyes
			elif (y in range(7, 9) and (x == 13 or x == 18)):
				img.set_pixel(x, y, eye)

	return ImageTexture.create_from_image(img)

func _create_barrel_texture() -> ImageTexture:
	var img = Image.create(20, 20, false, Image.FORMAT_RGBA8)
	var wood_dark = Color(0.45, 0.26, 0.12, 1.0)
	var wood_light = Color(0.60, 0.38, 0.20, 1.0)
	var hoop_metal = Color(0.25, 0.25, 0.28, 1.0)

	for x in range(20):
		for y in range(20):
			var dx = float(x - 10)
			var dy = float(y - 10)
			if dx*dx + dy*dy <= 90.0:
				if y in range(4, 7) or y in range(13, 16):
					img.set_pixel(x, y, hoop_metal)
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

			# Bonk Sound and Dizzy Notification
			var bonk = AudioStreamPlayer2D.new()
			bonk.stream = load("res://assets/sound/sound effects/box_1.wav")
			bonk.pitch_scale = 1.3
			bonk.global_position = body.global_position
			body.add_child(bonk)
			bonk.play()

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
				bonk.queue_free()
			)
			barrel.queue_free()
	)

	scene.add_child(barrel)

	# Roll barrel down and rotate
	var b_tween = barrel.create_tween()
	b_tween.parallel().tween_property(barrel, "global_position:y", 650.0, 7.0)
	b_tween.parallel().tween_property(barrel, "rotation", 14.0, 7.0)
	b_tween.tween_callback(barrel.queue_free)
'@ | Set-Content -Path $dkSpawner -Encoding UTF8
Write-Host "  Updated: Donkey Kong gorilla & barrel projectile" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 9. HARMONIZE BOTTOM-RIGHT HUD DOCKING (SPEED, AMAZON & AIR WINGS)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 9. Establishing clean 300px right-docked column geometry..." -ForegroundColor Cyan

# 9a. Speed Controller (Bottom Slot: -48 to -16, width: 300px)
$scPath = "$repo\mods-unpacked\gareth-game_speed_mod\mods-unpacked\gareth-game_speed_mod\scripts\speed_controller.gd"
$scCode = Get-Content $scPath -Raw
$scCode = $scCode.Replace('panel.offset_left = -316.0', 'panel.offset_left = -324.0')
$scCode = $scCode.Replace('panel.offset_left = -264.0', 'panel.offset_left = -324.0')
$scCode = $scCode.Replace('panel.offset_right = -16.0', 'panel.offset_right = -24.0')
$scCode = $scCode.Replace('panel.offset_top = -46.0', 'panel.offset_top = -48.0')
$scCode = $scCode.Replace('panel.offset_bottom = -12.0', 'panel.offset_bottom = -16.0')
Set-Content -Path $scPath -Value $scCode -Encoding UTF8

# 9b. Amazon Button (Middle Slot: -86 to -54, width: 300px)
$amzPath = "$repo\mods-unpacked\gareth-scrap_and_delivery_mod\mods-unpacked\gareth-scrap_and_delivery_mod\scripts\amazon_delivery_manager.gd"
$amzCode = Get-Content $amzPath -Raw
$amzCode = $amzCode.Replace('hud_btn.offset_left = -316.0', 'hud_btn.offset_left = -324.0')
$amzCode = $amzCode.Replace('hud_btn.offset_left = -110.0', 'hud_btn.offset_left = -324.0')
$amzCode = $amzCode.Replace('hud_btn.offset_right = -16.0', 'hud_btn.offset_right = -24.0')
$amzCode = $amzCode.Replace('hud_btn.offset_top = -82.0', 'hud_btn.offset_top = -86.0')
$amzCode = $amzCode.Replace('hud_btn.offset_bottom = -50.0', 'hud_btn.offset_bottom = -54.0')
Set-Content -Path $amzPath -Value $amzCode -Encoding UTF8

# 9c. Air Wings Panel (Top Slot: -126 to -92, width: 300px)
$eamPath = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\elemental_airstrike_manager.gd"
$eamCode = Get-Content $eamPath -Raw
$eamCode = $eamCode.Replace('panel.offset_left = -316.0', 'panel.offset_left = -324.0')
$eamCode = $eamCode.Replace('panel.offset_left = -264.0', 'panel.offset_left = -324.0')
$eamCode = $eamCode.Replace('panel.offset_right = -16.0', 'panel.offset_right = -24.0')
$eamCode = $eamCode.Replace('panel.offset_top = -120.0', 'panel.offset_top = -126.0')
$eamCode = $eamCode.Replace('panel.offset_bottom = -86.0', 'panel.offset_bottom = -92.0')
Set-Content -Path $eamPath -Value $eamCode -Encoding UTF8
Write-Host "  Updated: HUD coordinates aligned cleanly with 24px right breathing room" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 10. REPACK ALL AFFECTED MODS TO STEAM
# ------------------------------------------------------------------------------
Write-Host "`n>>> 10. Purging hook cache and repacking mod suite..." -ForegroundColor Cyan
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

$modsToRepack = @(
	"gareth-mod_manager_mod",
	"gareth-hardware_booster_mod",
	"gareth-living_canvas_mod",
	"gareth-abyssal_trench_mod",
	"gareth-diagonal_map_mod",
	"gareth-donkey_kong_mod",
	"gareth-game_speed_mod",
	"gareth-scrap_and_delivery_mod",
	"gareth-elemental_airstrikes_mod"
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
# 11. COMMIT AND PUSH
# ------------------------------------------------------------------------------
Write-Host "`n>>> 11. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Fix: ModManifest object handling in registry, Difficulty.REGULAR across maps 103-105, sky tile guard in hardware booster, and non-overlapping HUD column"
git push origin main

Write-Host "`nAll fixes deployed and committed cleanly!" -ForegroundColor Green