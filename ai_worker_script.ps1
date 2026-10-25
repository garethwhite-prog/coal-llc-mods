# ==============================================================================
# Coal LLC - Master Targeted Fix: Inventory Slots, Airstrike Headers, DK & HUD
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
# 2. TARGET 1: INVENTORY HOOK REGISTRATION & ALL 10 SLOTS RESTORATION
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Target 1: Registering Inventory.hooks.gd & restoring all 10 slots..." -ForegroundColor Cyan
$invHookDir1 = "$repo\mods-unpacked\gareth-mod_manager_mod\extensions\resources\Inventories\Scripts"
$invHookDir2 = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\resources\Inventories\Scripts"
New-Item -ItemType Directory -Path $invHookDir1 -Force | Out-Null
New-Item -ItemType Directory -Path $invHookDir2 -Force | Out-Null

$invHookCode = @'
extends Object

func initialise_slots(chain: ModLoaderHookChain) -> void:
	var inv = chain.reference_object
	if not is_instance_valid(inv):
		chain.execute_next([])
		return

	var target_slots: int = 10
	if "maxSlots" in inv and inv.maxSlots > 0:
		target_slots = int(inv.maxSlots)

	var empty_res = load("res://resources/Items/Empty.tres")
	var current_size: int = inv.items.size()

	for n in range(current_size, target_slots):
		var empty_slot = InventoryItem.new()
		if empty_res:
			empty_slot.set("item", empty_res)
		empty_slot.count = 0.0
		inv.items.append(empty_slot)
'@
Set-Content -Path "$invHookDir1\Inventory.hooks.gd" -Value $invHookCode -Encoding UTF8
Set-Content -Path "$invHookDir2\Inventory.hooks.gd" -Value $invHookCode -Encoding UTF8

# Update mod_manager_mod mod_main.gd to explicitly register Inventory.gd
$mmmPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\mod_main.gd"
@'
extends Node

const MOD_ID := "gareth-mod_manager_mod"
const LOG_NAME := "gareth-mod_manager_mod"

func _init() -> void:
	var unpacked_dir = ModLoaderMod.get_unpacked_dir().path_join(MOD_ID)
	var ext_dir = unpacked_dir.path_join("extensions")

	ModLoaderMod.install_script_hooks("res://resources/Inventories/Scripts/Inventory.gd", ext_dir.path_join("resources/Inventories/Scripts/Inventory.hooks.gd"))
	ModLoaderMod.install_script_hooks("res://resources/BuyEffects/Scripts/AddToInventory.gd", ext_dir.path_join("resources/BuyEffects/Scripts/AddToInventory.hooks.gd"))
	ModLoaderMod.install_script_hooks("res://scenes/Interfaces/Management/shop_item_card.gd", ext_dir.path_join("scenes/Interfaces/Management/shop_item_card.hooks.gd"))
	ModLoaderMod.install_script_hooks("res://scripts/Stockpile.gd", ext_dir.path_join("scripts/Stockpile.hooks.gd"))
	ModLoaderMod.install_script_hooks("res://scenes/Interfaces/in_game/choose_passive.gd", ext_dir.path_join("scenes/Interfaces/in_game/choose_passive.hooks.gd"))
	ModLoaderMod.install_script_hooks("res://scenes/Interfaces/Management/passive_bonuses.gd", ext_dir.path_join("scenes/Interfaces/Management/passive_bonuses.hooks.gd"))
	ModLoaderMod.install_script_hooks("res://scripts/MainMenu.gd", ext_dir.path_join("scripts/MainMenu.hooks.gd"))
	ModLoaderMod.install_script_hooks("res://scripts/Gvars.gd", ext_dir.path_join("scripts/Gvars.hooks.gd"))
	ModLoaderMod.install_script_hooks("res://scenes/Stages/management_screen.gd", ext_dir.path_join("scenes/Stages/management_screen.hooks.gd"))
	ModLoaderMod.install_script_hooks("res://scripts/Camera.gd", ext_dir.path_join("scripts/Camera.hooks.gd"))
	ModLoaderLog.info("Universal Mod Manager initializing with Inventory hooks...", LOG_NAME)

func _ready() -> void:
	ModLoaderLog.info("Universal Mod Manager active with full Class, Shop & Input gating.", LOG_NAME)
'@ | Set-Content -Path $mmmPath -Encoding UTF8
Write-Host "  Updated: mod_manager_mod with registered Inventory.hooks.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. TARGET 2: HIDE SCRAP & AMAZON BUTTONS IN BETWEEN-DAY STORE
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Target 2: Restricting DaytimeScrapBar to active mining runs only..." -ForegroundColor Cyan
$iwHookPath = "$repo\mods-unpacked\gareth-scrap_and_delivery_mod\mods-unpacked\gareth-scrap_and_delivery_mod\extensions\scenes\Interfaces\InventoryWindow.hooks.gd"
@'
extends Object

func load_inventory(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var grid = chain.reference_object
	if is_instance_valid(grid):
		_inject_scrap_bar(grid)

func _inject_scrap_bar(grid: GridContainer) -> void:
	# Hide buttons if we are in the between-day store (ManagementScreen / TabContainer)
	var scene = grid.get_tree().current_scene
	if scene and (scene.name == "ManagementScreen" or scene.name == "management_screen"):
		return
	if grid.find_parent("ManagementScreen") or grid.find_parent("TabContainer"):
		return

	var parent = grid.get_parent()
	if not parent or parent.has_node("DaytimeScrapBar"):
		return

	var bar = HBoxContainer.new()
	bar.name = "DaytimeScrapBar"
	bar.add_theme_constant_override("separation", 10)

	var btn_scrap_ores = Button.new()
	btn_scrap_ores.text = "♻️ Scrap All Ores (50% Cash)"
	btn_scrap_ores.tooltip_text = "Sell all raw ores from your inventory immediately for 50% value straight to your wallet."
	btn_scrap_ores.modulate = Color(0.4, 1.0, 0.6, 1.0)
	btn_scrap_ores.pressed.connect(func(): _scrap_all_ores(grid))
	bar.add_child(btn_scrap_ores)

	var btn_open_amazon = Button.new()
	btn_open_amazon.text = "📦 Open Amazon Store (B)"
	btn_open_amazon.tooltip_text = "Order emergency platforms, ladders, and tools delivered by parachute in 10 seconds."
	btn_open_amazon.modulate = Color(1.0, 0.85, 0.3, 1.0)
	btn_open_amazon.pressed.connect(func():
		var tree = grid.get_tree()
		if tree and tree.root:
			var mgr = tree.root.find_child("AmazonDeliveryManager", true, false)
			if mgr and mgr.has_method("open_store"):
				mgr.open_store()
	)
	bar.add_child(btn_open_amazon)

	parent.add_child(bar)
	parent.move_child(bar, grid.get_index())

func _scrap_all_ores(grid: GridContainer) -> void:
	if not Gvars or not ("inventory" in grid) or not grid.inventory:
		return

	var total_scrapped_cash: float = 0.0
	var inv: Inventory = grid.inventory
	var ore_rates = {
		"Coal": 1.0,
		"Copper": 2.5,
		"Iron": 5.0,
		"Silver": 12.0,
		"Gold": 25.0,
		"Amethyst": 45.0,
		"Sapphire": 80.0,
		"Emerald": 130.0,
		"Ruby": 200.0,
		"Diamond": 350.0
	}

	for slot in inv.items:
		if slot and slot.item and slot.count > 0:
			var iname = str(slot.item.itemName)
			if ore_rates.has(iname):
				var cash_gain = float(slot.count) * ore_rates[iname] * 0.5
				total_scrapped_cash += cash_gain
				slot.count = 0.0
				var empty_res = load("res://resources/Items/Empty.tres")
				if empty_res:
					slot.set("item", empty_res)

	if total_scrapped_cash > 0.0:
		Gvars.CashCount += total_scrapped_cash
		Bus.inventory_changed.emit()
'@ | Set-Content -Path $iwHookPath -Encoding UTF8
Write-Host "  Updated: InventoryWindow.hooks.gd (Store screen kept clean)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. TARGET 3: FIX AIRSTRIKE GDSCRIPT HEADERS (CLASS_NAME FIRST)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Target 3: Fixing class_name statement order in dragon & water bomber strikes..." -ForegroundColor Cyan
$dsPath = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\dragon_strike.gd"
@'
class_name DragonStrike
extends Node2D

const Textures = preload("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/texture_factory.gd")

var damage: float = 180.0
var bomb_rate: float = 0.05
var speed: float = 280.0
var t: float = 0.0

var sprite: Sprite2D

func _ready() -> void:
	z_index = 60
	sprite = Sprite2D.new()
	sprite.texture = Textures.create_dragon_texture()
	sprite.scale = Vector2(2.0, 2.0)
	add_child(sprite)

func _process(delta: float) -> void:
	var speed_mod: float = (1.0 + 2.0 * abs(sprite.position.x / 1000.0))
	t += delta
	sprite.position.x -= delta * speed * speed_mod

	if sprite.position.x > 0:
		sprite.rotation_degrees = -30
		sprite.position.y += delta * speed * speed_mod * 0.7
	else:
		sprite.rotation_degrees = 30
		sprite.position.y -= delta * speed * speed_mod * 0.7

	if t > bomb_rate:
		_drop_fireball(sprite.global_position)
		t -= bomb_rate

	if sprite.position.x < -1000:
		queue_free()

func _drop_fireball(pos: Vector2) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	var b = Node2D.new()
	b.global_position = pos
	var spr = Sprite2D.new()
	spr.texture = Textures.create_fireball_texture()
	spr.scale = Vector2(1.5, 1.5)
	b.add_child(spr)
	tree.current_scene.add_child(b)

	var tw = b.create_tween()
	tw.parallel().tween_property(b, "global_position:y", pos.y + 600.0, 2.0)
	tw.tween_callback(func():
		var tm = tree.root.find_child("TileMapManager", true, false)
		if tm:
			var m_pos = tm.local_to_map(b.global_position)
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					tm.damageTileCoords(Vector2i(m_pos.x + dx, m_pos.y + dy), damage)
		b.queue_free()
	)
'@ | Set-Content -Path $dsPath -Encoding UTF8

$wbPath = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\water_bomber_strike.gd"
@'
class_name WaterBomberStrike
extends Node2D

const Textures = preload("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/texture_factory.gd")

var damage: float = 120.0
var drop_rate: float = 0.04
var speed: float = 260.0
var t: float = 0.0

var sprite: Sprite2D

func _ready() -> void:
	z_index = 60
	sprite = Sprite2D.new()
	sprite.texture = Textures.create_water_bomber_texture()
	sprite.scale = Vector2(2.0, 2.0)
	add_child(sprite)

func _process(delta: float) -> void:
	var speed_mod: float = (1.0 + 2.0 * abs(sprite.position.x / 1000.0))
	t += delta
	sprite.position.x -= delta * speed * speed_mod

	if sprite.position.x > 0:
		sprite.rotation_degrees = -25
		sprite.position.y += delta * speed * speed_mod * 0.5
	else:
		sprite.rotation_degrees = 25
		sprite.position.y -= delta * speed * speed_mod * 0.5

	if t > drop_rate:
		_drop_water(sprite.global_position)
		t -= drop_rate

	if sprite.position.x < -1000:
		queue_free()

func _drop_water(pos: Vector2) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	var b = Node2D.new()
	b.global_position = pos
	var spr = Sprite2D.new()
	spr.texture = Textures.create_water_drop_texture()
	spr.scale = Vector2(1.5, 1.5)
	b.add_child(spr)
	tree.current_scene.add_child(b)

	var tw = b.create_tween()
	tw.parallel().tween_property(b, "global_position:y", pos.y + 600.0, 2.0)
	tw.tween_callback(func():
		var tm = tree.root.find_child("TileMapManager", true, false)
		if tm:
			var m_pos = tm.local_to_map(b.global_position)
			for dx in range(-3, 4):
				for dy in range(-3, 4):
					tm.damageTileCoords(Vector2i(m_pos.x + dx, m_pos.y + dy), damage)
		b.queue_free()
	)
'@ | Set-Content -Path $wbPath -Encoding UTF8
Write-Host "  Updated: dragon_strike.gd & water_bomber_strike.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. TARGET 4: FIX GORILLA SURFACE SPAWNER INDENTATION & STUN LOGIC
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Target 4: Rewriting gorilla_surface_spawner.gd with clean tabs & immobilize stun..." -ForegroundColor Cyan
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
		gorilla.position.x += 45.0 * delta * gorilla.get_meta("dir", 1.0)
		if gorilla.position.x > 600.0:
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
	gorilla.global_position = Vector2(460, -32)
	gorilla.set_meta("dir", 1.0)

	var spr = Sprite2D.new()
	spr.texture = _create_gorilla_texture()
	spr.scale = Vector2(1.6, 1.6)
	gorilla.add_child(spr)
	scene.add_child(gorilla)

func _create_gorilla_texture() -> ImageTexture:
	var img = Image.create(36, 36, false, Image.FORMAT_RGBA8)
	var fur_dark = Color(0.22, 0.11, 0.04, 1.0)
	var fur_mid  = Color(0.36, 0.18, 0.08, 1.0)
	var chest    = Color(0.74, 0.52, 0.34, 1.0)
	var tie_red  = Color(0.95, 0.15, 0.15, 1.0)
	var tie_gold = Color(1.0, 0.85, 0.20, 1.0)
	var eye_w    = Color(1.0, 1.0, 1.0, 1.0)
	var eye_b    = Color(0.05, 0.05, 0.05, 1.0)

	for x in range(36):
		for y in range(36):
			if y in range(4, 13) and x in range(11, 25):
				img.set_pixel(x, y, fur_mid if y < 9 else fur_dark)
			elif (y in range(13, 30) and x in range(8, 28)) or (y in range(14, 32) and (x in range(3, 9) or x in range(27, 33))):
				img.set_pixel(x, y, fur_mid if x % 2 == 0 else fur_dark)
			if (y in range(9, 13) and x in range(13, 23)) or (y in range(15, 24) and x in range(12, 24)):
				img.set_pixel(x, y, chest)
			if (y in range(15, 26) and x in range(16, 20)):
				img.set_pixel(x, y, tie_red)
			if (y == 20 or y == 21) and (x == 17 or x == 18):
				img.set_pixel(x, y, tie_gold)
			if y in range(7, 9) and (x == 14 or x == 20):
				img.set_pixel(x, y, eye_w)
			if y == 8 and (x == 15 or x == 21):
				img.set_pixel(x, y, eye_b)

	return ImageTexture.create_from_image(img)

func _create_barrel_texture() -> ImageTexture:
	var img = Image.create(22, 22, false, Image.FORMAT_RGBA8)
	var w_dark  = Color(0.40, 0.22, 0.10, 1.0)
	var w_light = Color(0.58, 0.36, 0.18, 1.0)
	var metal   = Color(0.24, 0.24, 0.26, 1.0)

	for x in range(22):
		for y in range(22):
			var dx = float(x - 11)
			var dy = float(y - 11)
			if dx*dx + dy*dy <= 105.0:
				if y in range(4, 7) or y in range(15, 18):
					img.set_pixel(x, y, metal)
				elif x % 3 == 0:
					img.set_pixel(x, y, w_dark)
				else:
					img.set_pixel(x, y, w_light)

	return ImageTexture.create_from_image(img)

func _toss_barrel(scene: Node, pos: Vector2) -> void:
	var barrel = Area2D.new()
	barrel.name = "RollingBarrel"
	barrel.global_position = pos
	barrel.collision_layer = 0
	barrel.collision_mask = 0xFFFFFFFF

	var spr = Sprite2D.new()
	spr.texture = _create_barrel_texture()
	spr.scale = Vector2(1.7, 1.7)
	barrel.add_child(spr)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16.0
	col.shape = shape
	barrel.add_child(col)

	var on_hit = func(target: Node):
		var p_node = target if (target.name == "Player" or target.is_in_group("player")) else target.get_parent()
		if p_node and (p_node.name == "Player" or p_node.is_in_group("player")):
			if "velocity" in p_node:
				p_node.velocity = Vector2.ZERO
			if "able_to_mine" in p_node:
				p_node.able_to_mine = false
			if p_node.has_node("StateMachine"):
				p_node.get_node("StateMachine").set_physics_process(false)

			var toast = Label.new()
			toast.text = "★ BONK! STUNNED! ★"
			toast.modulate = Color(1.0, 0.85, 0.2)
			toast.position = Vector2(-60, -40)
			p_node.add_child(toast)

			var bonk = AudioStreamPlayer2D.new()
			bonk.stream = load("res://assets/sound/sound effects/box_1.wav")
			bonk.pitch_scale = 1.3
			p_node.add_child(bonk)
			bonk.play()

			var tw = p_node.create_tween()
			tw.tween_interval(2.5)
			tw.tween_callback(func():
				if is_instance_valid(p_node):
					if "able_to_mine" in p_node:
						p_node.able_to_mine = true
					if p_node.has_node("StateMachine"):
						p_node.get_node("StateMachine").set_physics_process(true)
				toast.queue_free()
				bonk.queue_free()
			)
			barrel.queue_free()

	barrel.body_entered.connect(on_hit)
	barrel.area_entered.connect(on_hit)

	scene.add_child(barrel)
	var b_tween = barrel.create_tween()
	b_tween.parallel().tween_property(barrel, "global_position:x", 160.0, 4.0)
	b_tween.parallel().tween_property(barrel, "global_position:y", 680.0, 6.0)
	b_tween.parallel().tween_property(barrel, "rotation", 14.0, 6.0)
	b_tween.tween_callback(barrel.queue_free)
'@ | Set-Content -Path $dkSpawner -Encoding UTF8
Write-Host "  Updated: gorilla_surface_spawner.gd (Clean syntax & active stun)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. TARGET 5: FIX COLLECTOR PRIORITY METADATA STORAGE
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Target 5: Storing collector_priority_mode safely via metadata..." -ForegroundColor Cyan
$cpSettings = "$repo\mods-unpacked\gareth-collector_priority_mod\mods-unpacked\gareth-collector_priority_mod\extensions\scenes\Interfaces\Menus\settings_2.hooks.gd"
$cpSettingsCode = Get-Content $cpSettings -Raw
$cpSettingsCode = $cpSettingsCode.Replace('Gvars.collector_priority_mode = idx', 'Gvars.set_meta("collector_priority_mode", idx)')
$cpSettingsCode = $cpSettingsCode.Replace('cur_mode = int(Gvars.collector_priority_mode)', 'cur_mode = int(Gvars.get_meta("collector_priority_mode", 1))')
Set-Content -Path $cpSettings -Value $cpSettingsCode -Encoding UTF8

$cpLoot = "$repo\mods-unpacked\gareth-collector_priority_mod\mods-unpacked\gareth-collector_priority_mod\extensions\scripts\loot_drops.hooks.gd"
$cpLootCode = Get-Content $cpLoot -Raw
$cpLootCode = $cpLootCode.Replace('priority_mode = int(Gvars.collector_priority_mode)', 'priority_mode = int(Gvars.get_meta("collector_priority_mode", 1))')
Set-Content -Path $cpLoot -Value $cpLootCode -Encoding UTF8
Write-Host "  Updated: collector priority metadata persistence" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 7. TARGET 6: LASER BEAM INPUT (SUPPORT BOTH LEFT & RIGHT CLICK)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Target 6: Supporting right-click & left-click laser firing..." -ForegroundColor Cyan
$leePath = "$repo\mods-unpacked\gareth-laser_beam_mod\mods-unpacked\gareth-laser_beam_mod\scripts\laser_equip_effect.gd"
@'
class_name LaserEquipEffect
extends EquipEffect

var beam_node: Node2D = null

func start(player, _item):
	var script_res = load("res://mods-unpacked/gareth-laser_beam_mod/scripts/laser_beam_weapon.gd")
	beam_node = Node2D.new()
	beam_node.set_script(script_res)
	player.add_child(beam_node)

func end(player):
	if beam_node != null and is_instance_valid(beam_node):
		beam_node.call("stop_beam")
		beam_node.queue_free()
		beam_node = null

func physics_process(player, _delta):
	if beam_node == null or not is_instance_valid(beam_node):
		return
	if Input.is_action_pressed("useItem") or Input.is_action_pressed("fire") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		beam_node.call("fire_beam", player.global_position, player.pointer_global_pos, player.tilemap)
	else:
		beam_node.call("stop_beam")
'@ | Set-Content -Path $leePath -Encoding UTF8
Write-Host "  Updated: laser_equip_effect.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 8. TARGET 7: BOTTOM-RIGHT HUD MICRO-DOCK (COMPACT, NON-OVERLAPPING STACK)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 8. Target 7: Restructuring bottom-right HUD with clean vertical offsets..." -ForegroundColor Cyan

# 8a. Speed Controller: Slot 1 (-40 to -14, Height 26px)
$scPath = "$repo\mods-unpacked\gareth-game_speed_mod\mods-unpacked\gareth-game_speed_mod\scripts\speed_controller.gd"
@'
extends Node

var canvas: CanvasLayer
var panel: PanelContainer
var lbl_speed: Label
var btn_slower: Button
var btn_faster: Button

const SPEEDS := [0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0]
var current_idx := 3

func _ready() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 95
	add_child(canvas)

	panel = PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -160.0
	panel.offset_right = -10.0
	panel.offset_top = -40.0
	panel.offset_bottom = -14.0

	var empty_sb = StyleBoxEmpty.new()
	panel.add_theme_stylebox_override("panel", empty_sb)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 4)
	panel.add_child(hbox)

	btn_slower = Button.new()
	btn_slower.text = "◀"
	btn_slower.custom_minimum_size = Vector2(24, 22)
	btn_slower.add_theme_font_size_override("font_size", 10)
	btn_slower.pressed.connect(_decrease_speed)
	hbox.add_child(btn_slower)

	lbl_speed = Label.new()
	lbl_speed.text = "1.00x"
	lbl_speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_speed.custom_minimum_size = Vector2(44, 22)
	lbl_speed.add_theme_font_size_override("font_size", 10)
	hbox.add_child(lbl_speed)

	btn_faster = Button.new()
	btn_faster.text = "▶"
	btn_faster.custom_minimum_size = Vector2(24, 22)
	btn_faster.add_theme_font_size_override("font_size", 10)
	btn_faster.pressed.connect(_increase_speed)
	hbox.add_child(btn_faster)

	canvas.add_child(panel)

func _increase_speed() -> void:
	if current_idx < SPEEDS.size() - 1:
		current_idx += 1
		_apply_speed()

func _decrease_speed() -> void:
	if current_idx > 0:
		current_idx -= 1
		_apply_speed()

func _apply_speed() -> void:
	var sp = SPEEDS[current_idx]
	Engine.time_scale = sp
	lbl_speed.text = "%.2fx" % sp
'@ | Set-Content -Path $scPath -Encoding UTF8

# 8b. Amazon Delivery: Slot 2 (-72 to -46, Height 26px)
$amzPath = "$repo\mods-unpacked\gareth-scrap_and_delivery_mod\mods-unpacked\gareth-scrap_and_delivery_mod\scripts\amazon_delivery_manager.gd"
$amzCode = Get-Content $amzPath -Raw
$amzCode = $amzCode.Replace('hud_btn.offset_left = -396.0', 'hud_btn.offset_left = -160.0')
$amzCode = $amzCode.Replace('hud_btn.offset_left = -356.0', 'hud_btn.offset_left = -160.0')
$amzCode = $amzCode.Replace('hud_btn.offset_left = -172.0', 'hud_btn.offset_left = -160.0')
$amzCode = $amzCode.Replace('hud_btn.offset_right = -16.0', 'hud_btn.offset_right = -10.0')
$amzCode = $amzCode.Replace('hud_btn.offset_right = -20.0', 'hud_btn.offset_right = -10.0')
$amzCode = $amzCode.Replace('hud_btn.offset_right = -8.0', 'hud_btn.offset_right = -10.0')
$amzCode = $amzCode.Replace('hud_btn.offset_top = -88.0', 'hud_btn.offset_top = -72.0')
$amzCode = $amzCode.Replace('hud_btn.offset_top = -82.0', 'hud_btn.offset_top = -72.0')
$amzCode = $amzCode.Replace('hud_btn.offset_bottom = -54.0', 'hud_btn.offset_bottom = -46.0')
$amzCode = $amzCode.Replace('hud_btn.offset_bottom = -60.0', 'hud_btn.offset_bottom = -46.0')
if (-not $amzCode.Contains('add_theme_font_size_override("font_size", 10)')) {
	$amzCode = $amzCode.Replace(
		'hud_btn.text = "📦 Amazon (B)"',
		'hud_btn.text = "📦 Amazon (B)"`r`n`thud_btn.add_theme_font_size_override("font_size", 10)`r`n`thud_btn.custom_minimum_size = Vector2(150, 24)'
	)
}
Set-Content -Path $amzPath -Value $amzCode -Encoding UTF8

# 8c. Air Wings: Slot 3 (-104 to -78, Height 26px)
$eamPath = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\elemental_airstrike_manager.gd"
@'
extends Node

var canvas: CanvasLayer
var panel: PanelContainer
var btn_dragon: Button
var btn_water: Button
var btn_poison: Button

func _ready() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 94
	add_child(canvas)

	panel = PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -160.0
	panel.offset_right = -10.0
	panel.offset_top = -104.0
	panel.offset_bottom = -78.0

	var empty_sb = StyleBoxEmpty.new()
	panel.add_theme_stylebox_override("panel", empty_sb)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 4)
	panel.add_child(hbox)

	btn_dragon = Button.new()
	btn_dragon.text = "🔥 7"
	btn_dragon.tooltip_text = "Dragon Firebombing (Press 7)"
	btn_dragon.custom_minimum_size = Vector2(46, 22)
	btn_dragon.add_theme_font_size_override("font_size", 10)
	btn_dragon.pressed.connect(_launch_dragon)
	hbox.add_child(btn_dragon)

	btn_water = Button.new()
	btn_water.text = "💧 8"
	btn_water.tooltip_text = "Water Bomber (Press 8)"
	btn_water.custom_minimum_size = Vector2(46, 22)
	btn_water.add_theme_font_size_override("font_size", 10)
	btn_water.pressed.connect(_launch_water)
	hbox.add_child(btn_water)

	btn_poison = Button.new()
	btn_poison.text = "☣️ 9"
	btn_poison.tooltip_text = "Poison Gas Strike (Press 9)"
	btn_poison.custom_minimum_size = Vector2(46, 22)
	btn_poison.add_theme_font_size_override("font_size", 10)
	btn_poison.pressed.connect(_launch_poison)
	hbox.add_child(btn_poison)

	canvas.add_child(panel)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_7:
			_launch_dragon()
		elif event.keycode == KEY_8:
			_launch_water()
		elif event.keycode == KEY_9:
			_launch_poison()

func _launch_dragon() -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	var script = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/dragon_strike.gd")
	if script:
		var strike = Node2D.new()
		strike.set_script(script)
		tree.current_scene.add_child(strike)

func _launch_water() -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	var script = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/water_bomber_strike.gd")
	if script:
		var strike = Node2D.new()
		strike.set_script(script)
		tree.current_scene.add_child(strike)

func _launch_poison() -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	var script = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/dragon_strike.gd")
	if script:
		var strike = Node2D.new()
		strike.set_script(script)
		strike.modulate = Color(0.2, 1.0, 0.4)
		tree.current_scene.add_child(strike)
'@ | Set-Content -Path $eamPath -Encoding UTF8
Write-Host "  Updated: HUD coordinates aligned cleanly with zero-padding StyleBox" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 9. REPACK ONLY THE SPECIFIC MODS MODIFIED (STRICTLY TARGETED)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 9. Repackaging strictly targeted mods to Steam..." -ForegroundColor Cyan
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

$targetedMods = @(
	"gareth-mod_manager_mod",
	"gareth-laser_beam_mod",
	"gareth-collector_priority_mod",
	"gareth-donkey_kong_mod",
	"gareth-game_speed_mod",
	"gareth-scrap_and_delivery_mod",
	"gareth-elemental_airstrikes_mod"
)

foreach ($m in $targetedMods) {
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
# 10. COMMIT & PUSH TARGETED FIXES
# ------------------------------------------------------------------------------
Write-Host "`n>>> 10. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Targeted Fix: Register Inventory.hooks in mod_main, hide scrap buttons in store, fix airstrike class_name order, DK syntax, and zero-margin 150px HUD stack"
git push origin main

Write-Host "`nMaster targeted deployment complete!" -ForegroundColor Green