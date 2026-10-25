# ==============================================================================
# Coal LLC - Targeted Fix: Consumable Airstrikes + B-52, Amazon HUD, & Menu Guard
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
# 2. FIX TEXTURE_FACTORY.GD (FIREBALL, WATER DROP, AGENT ORANGE, B-52 & BOMBS)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Implementing all procedural textures in texture_factory.gd..." -ForegroundColor Cyan
$tfPath = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\texture_factory.gd"
@'
class_name ElementalAirstrikeTextures
extends RefCounted

static func create_dragon_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var red = Color(0.9, 0.15, 0.1, 1.0)
	var orange = Color(1.0, 0.55, 0.1, 1.0)
	var yellow = Color(1.0, 0.9, 0.2, 1.0)
	for x in range(32):
		for y in range(32):
			if (y >= 13 and y <= 18 and x >= 4 and x <= 27) or (x >= 12 and x <= 20 and y >= 6 and y <= 25):
				img.set_pixel(x, y, red)
			elif (y >= 10 and y <= 12 and x >= 8 and x <= 24) or (x >= 24 and x <= 28 and y >= 14 and y <= 17):
				img.set_pixel(x, y, orange)
			elif x >= 27 and x <= 30 and y >= 15 and y <= 16:
				img.set_pixel(x, y, yellow)
	return ImageTexture.create_from_image(img)

static func create_water_bomber_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var blue = Color(0.1, 0.55, 0.95, 1.0)
	var white = Color(0.95, 0.95, 1.0, 1.0)
	var yellow = Color(1.0, 0.85, 0.2, 1.0)
	for x in range(32):
		for y in range(32):
			if (y >= 14 and y <= 17 and x >= 3 and x <= 28) or (x >= 13 and x <= 18 and y >= 8 and y <= 23):
				img.set_pixel(x, y, blue)
			elif (y in [13, 18] and x >= 10 and x <= 21):
				img.set_pixel(x, y, white)
			elif x >= 27 and x <= 30 and y >= 15 and y <= 16:
				img.set_pixel(x, y, yellow)
	return ImageTexture.create_from_image(img)

static func create_agent_orange_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var green = Color(0.15, 0.75, 0.25, 1.0)
	var dark_green = Color(0.08, 0.45, 0.15, 1.0)
	var yellow = Color(1.0, 0.85, 0.15, 1.0)
	for x in range(32):
		for y in range(32):
			if (y >= 13 and y <= 17 and x >= 4 and x <= 28) or (x >= 12 and x <= 19 and y >= 9 and y <= 22):
				img.set_pixel(x, y, green)
			elif y in [12, 18] and x >= 8 and x <= 23:
				img.set_pixel(x, y, dark_green)
			elif x >= 27 and x <= 30 and y >= 14 and y <= 16:
				img.set_pixel(x, y, yellow)
	return ImageTexture.create_from_image(img)

static func create_b52_texture() -> ImageTexture:
	var img = Image.create(40, 40, false, Image.FORMAT_RGBA8)
	var camo_dark = Color(0.22, 0.26, 0.22, 1.0)
	var camo_light = Color(0.38, 0.44, 0.35, 1.0)
	var cockpit = Color(0.65, 0.85, 0.95, 1.0)
	for x in range(40):
		for y in range(40):
			if (y >= 17 and y <= 22 and x >= 2 and x <= 37) or (x >= 15 and x <= 24 and y >= 5 and y <= 34):
				img.set_pixel(x, y, camo_dark if (x + y) % 3 == 0 else camo_light)
			elif x in range(32, 36) and y in range(18, 21):
				img.set_pixel(x, y, cockpit)
	return ImageTexture.create_from_image(img)

static func create_fireball_texture() -> ImageTexture:
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var core = Color(1.0, 0.95, 0.3, 1.0)
	var outer = Color(0.95, 0.25, 0.1, 1.0)
	for x in range(16):
		for y in range(16):
			var dist = (x - 8)*(x - 8) + (y - 8)*(y - 8)
			if dist <= 16:
				img.set_pixel(x, y, core)
			elif dist <= 36:
				img.set_pixel(x, y, outer)
	return ImageTexture.create_from_image(img)

static func create_water_drop_texture() -> ImageTexture:
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var core = Color(0.4, 0.85, 1.0, 1.0)
	var outer = Color(0.1, 0.45, 0.9, 1.0)
	for x in range(16):
		for y in range(16):
			var dist = (x - 8)*(x - 8) + (y - 8)*(y - 8)
			if dist <= 16:
				img.set_pixel(x, y, core)
			elif dist <= 36:
				img.set_pixel(x, y, outer)
	return ImageTexture.create_from_image(img)

static func create_heavy_bomb_texture() -> ImageTexture:
	var img = Image.create(18, 18, false, Image.FORMAT_RGBA8)
	var iron = Color(0.2, 0.2, 0.22, 1.0)
	var yellow = Color(0.95, 0.8, 0.1, 1.0)
	for x in range(18):
		for y in range(18):
			var dist = (x - 9)*(x - 9) + (y - 9)*(y - 9)
			if dist <= 32:
				img.set_pixel(x, y, yellow if x % 4 == 0 else iron)
	return ImageTexture.create_from_image(img)
'@ | Set-Content -Path $tfPath -Encoding UTF8
Write-Host "  Updated: texture_factory.gd with all procedural textures" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. CREATE B-52 CARPET STRIKE SCRIPT & UPDATE EXISTING AIRSTRIKES
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Implementing B-52 carpet strike & screen-relative flight paths..." -ForegroundColor Cyan
$b52Path = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\b52_carpet_strike.gd"
@'
class_name B52CarpetStrike
extends Node2D

const Textures = preload("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/texture_factory.gd")

var damage: float = 240.0
var drop_rate: float = 0.08
var speed: float = 220.0
var t: float = 0.0
var sprite: Sprite2D
var target_y: float = -140.0

func _ready() -> void:
	z_index = 60
	sprite = Sprite2D.new()
	sprite.texture = Textures.create_b52_texture()
	sprite.scale = Vector2(2.2, 2.2)
	add_child(sprite)

	var p = get_tree().root.find_child("Player", true, false)
	if p:
		target_y = p.global_position.y - 140.0
		global_position = Vector2(p.global_position.x + 850.0, target_y)

func _process(delta: float) -> void:
	t += delta
	position.x -= delta * speed

	if t > drop_rate:
		_drop_carpet_bomb(global_position)
		t -= drop_rate

	var p = get_tree().root.find_child("Player", true, false)
	if p and position.x < (p.global_position.x - 900.0):
		queue_free()

func _drop_carpet_bomb(pos: Vector2) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	var b = Node2D.new()
	b.global_position = pos
	var spr = Sprite2D.new()
	spr.texture = Textures.create_heavy_bomb_texture()
	spr.scale = Vector2(1.6, 1.6)
	b.add_child(spr)
	tree.current_scene.add_child(b)

	var tw = b.create_tween()
	tw.parallel().tween_property(b, "global_position:y", pos.y + 450.0, 1.4)
	tw.tween_callback(func():
		var tm = tree.root.find_child("TileMapManager", true, false)
		if tm:
			var m_pos = tm.local_to_map(b.global_position)
			for dx in range(-3, 4):
				for dy in range(-3, 4):
					tm.damageTileCoords(Vector2i(m_pos.x + dx, m_pos.y + dy), damage)
		b.queue_free()
	)
'@ | Set-Content -Path $b52Path -Encoding UTF8

# Update dragon_strike.gd to fly relative to player height
$dsPath = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\dragon_strike.gd"
@'
class_name DragonStrike
extends Node2D

const Textures = preload("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/texture_factory.gd")

var damage: float = 180.0
var bomb_rate: float = 0.06
var speed: float = 280.0
var t: float = 0.0
var sprite: Sprite2D
var start_x: float = 0.0

func _ready() -> void:
	z_index = 60
	sprite = Sprite2D.new()
	sprite.texture = Textures.create_dragon_texture()
	sprite.scale = Vector2(2.0, 2.0)
	add_child(sprite)

	var p = get_tree().root.find_child("Player", true, false)
	if p:
		global_position = Vector2(p.global_position.x + 850.0, p.global_position.y - 130.0)
		start_x = p.global_position.x

func _process(delta: float) -> void:
	t += delta
	position.x -= delta * speed
	position.y += sin(t * 4.0) * 1.5

	if t > bomb_rate:
		_drop_fireball(global_position)
		t -= bomb_rate

	var p = get_tree().root.find_child("Player", true, false)
	if p and position.x < (p.global_position.x - 900.0):
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
	tw.parallel().tween_property(b, "global_position:y", pos.y + 450.0, 1.5)
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

# Update water_bomber_strike.gd to fly relative to player height
$wbPath = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\water_bomber_strike.gd"
@'
class_name WaterBomberStrike
extends Node2D

const Textures = preload("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/texture_factory.gd")

var damage: float = 120.0
var drop_rate: float = 0.05
var speed: float = 260.0
var t: float = 0.0
var sprite: Sprite2D

func _ready() -> void:
	z_index = 60
	sprite = Sprite2D.new()
	sprite.texture = Textures.create_water_bomber_texture()
	sprite.scale = Vector2(2.0, 2.0)
	add_child(sprite)

	var p = get_tree().root.find_child("Player", true, false)
	if p:
		global_position = Vector2(p.global_position.x + 850.0, p.global_position.y - 130.0)

func _process(delta: float) -> void:
	t += delta
	position.x -= delta * speed

	if t > drop_rate:
		_drop_water(global_position)
		t -= drop_rate

	var p = get_tree().root.find_child("Player", true, false)
	if p and position.x < (p.global_position.x - 900.0):
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
	tw.parallel().tween_property(b, "global_position:y", pos.y + 450.0, 1.5)
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

# ------------------------------------------------------------------------------
# 4. IMPLEMENT CONSUMABLE EQUIP EFFECT FOR AIRSTRIKE ITEMS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Creating airstrike_equip_effect.gd (single-use consumable execution)..." -ForegroundColor Cyan
$aeePath = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\airstrike_equip_effect.gd"
@'
class_name AirstrikeEquipEffect
extends EquipEffect

@export var strike_type: String = "dragon"

func physics_process(player, _delta: float) -> void:
	if Input.is_action_just_pressed("useItem") or Input.is_mouse_button_just_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_just_pressed(MOUSE_BUTTON_RIGHT):
		var tree = player.get_tree()
		if not tree or not tree.current_scene:
			return

		var script_map = {
			"dragon": "res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/dragon_strike.gd",
			"water": "res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/water_bomber_strike.gd",
			"poison": "res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/dragon_strike.gd",
			"b52": "res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/b52_carpet_strike.gd"
		}

		if script_map.has(strike_type):
			var sc = load(script_map[strike_type])
			if sc:
				var strike = Node2D.new()
				strike.set_script(sc)
				if strike_type == "poison":
					strike.modulate = Color(0.2, 1.0, 0.4)
				tree.current_scene.add_child(strike)

		# Consume 1 charge from player inventory
		var inv: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
		if inv and is_instance_valid(player) and ("item_equipped" in player) and player.item_equipped:
			inv.sellFromInventory(player.item_equipped, 1)
			Bus.inventory_changed.emit()
'@ | Set-Content -Path $aeePath -Encoding UTF8

# ------------------------------------------------------------------------------
# 5. REGISTER CONSUMABLE AIRSTRIKE ITEMS (WITH VALID ITEMBUYEFFECT)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Registering consumable airstrike items + B-52 Carpet Bomber in mod_main.gd..." -ForegroundColor Cyan
$airstrikesModMain = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\mod_main.gd"
@'
extends Node

const MOD_DIR := "gareth-elemental_airstrikes_mod"

func _ready() -> void:
	var mgr_script = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/elemental_airstrike_manager.gd")
	var mgr = Node.new()
	mgr.name = "ElementalAirstrikeManager"
	mgr.set_script(mgr_script)
	get_tree().root.call_deferred("add_child", mgr)

	_register_elemental_items()
	ModLoaderLog.info("Elemental Airstrikes Triad + B-52 Bomber active!", MOD_DIR)

func _register_elemental_items() -> void:
	var factory = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/texture_factory.gd")
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks or not ("all_equipment_items" in item_unlocks) or not factory:
		return

	var buy_fx = load("res://resources/BuyEffects/Scripts/AddToInventory.gd").new()
	var equip_effect_script = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/airstrike_equip_effect.gd")

	var items_data = [
		{
			"id": "dragon_strike_whistle",
			"name": "Dragon Strike Whistle",
			"desc": "Single-use tactical flare. Calls an ancient dragon to carpet the mine in incendiary fire.",
			"price": 250.0,
			"type": "dragon",
			"tex": factory.create_dragon_texture()
		},
		{
			"id": "water_bomber_radio",
			"name": "Water Bomber Radio",
			"desc": "Single-use emergency radio. Calls a water-bomber plane to deluge cavern fires and soften clay.",
			"price": 150.0,
			"type": "water",
			"tex": factory.create_water_bomber_texture()
		},
		{
			"id": "agent_orange_transceiver",
			"name": "Agent Orange Transceiver",
			"desc": "Single-use chemical beacon. Disperses concentrated defoliant across the active strata.",
			"price": 350.0,
			"type": "poison",
			"tex": factory.create_agent_orange_texture()
		},
		{
			"id": "b52_carpet_bomber",
			"name": "B-52 Carpet Bomber",
			"desc": "Single-use heavy airstrike. Drops 10 high-explosive ordnance bombs, devastating stone strata.",
			"price": 850.0,
			"type": "b52",
			"tex": factory.create_b52_texture()
		}
	]

	for data in items_data:
		var it = Item.new()
		it.itemID = data["id"]
		it.itemName = data["name"]
		it.itemDescription = data["desc"]
		it.itemBuyPrice = data["price"]
		it.itemSellPrice = data["price"] * 0.5
		it.itemType = "equipment"
		it.itemTexture = data["tex"]
		it.itemUnlocked = true
		it.itemBuyEffect = buy_fx

		var eq = equip_effect_script.new()
		eq.strike_type = data["type"]
		it.itemEquipEffect = eq

		var exists := false
		for existing in item_unlocks.all_equipment_items:
			if existing and existing.itemID == it.itemID:
				exists = true
				break
		if not exists:
			item_unlocks.all_equipment_items.append(it)
			if "all_items" in item_unlocks:
				item_unlocks.all_items.append(it)
'@ | Set-Content -Path $airstrikesModMain -Encoding UTF8
Write-Host "  Updated: Registered 4 consumable airstrike items with functional buy_effect" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. FIX AMAZON_DELIVERY_MANAGER.GD SYNTAX & IN-MINE VISIBILITY GUARD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Repairing amazon_delivery_manager.gd syntax & offsets..." -ForegroundColor Cyan
$amzPath = "$repo\mods-unpacked\gareth-scrap_and_delivery_mod\mods-unpacked\gareth-scrap_and_delivery_mod\scripts\amazon_delivery_manager.gd"
$amzCode = Get-Content $amzPath -Raw

# Replace corrupt backtick string with clean string
$badSnippet = 'hud_btn.text = "📦 Amazon (B)"`r`n`thud_btn.add_theme_font_size_override("font_size", 10)`r`n`thud_btn.custom_minimum_size = Vector2(150, 24)'
$goodSnippet = @"
hud_btn.text = "📦 Amazon (B)"
	hud_btn.add_theme_font_size_override("font_size", 10)
	hud_btn.custom_minimum_size = Vector2(150, 24)
"@
$amzCode = $amzCode.Replace($badSnippet, $goodSnippet)

# Ensure clean offsets
$amzCode = $amzCode.Replace('hud_btn.offset_left = -396.0', 'hud_btn.offset_left = -160.0')
$amzCode = $amzCode.Replace('hud_btn.offset_right = -16.0', 'hud_btn.offset_right = -10.0')
$amzCode = $amzCode.Replace('hud_btn.offset_top = -88.0', 'hud_btn.offset_top = -72.0')
$amzCode = $amzCode.Replace('hud_btn.offset_bottom = -54.0', 'hud_btn.offset_bottom = -46.0')

Set-Content -Path $amzPath -Value $amzCode -Encoding UTF8
Write-Host "  Repaired: amazon_delivery_manager.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 7. ADD MENU HIDE GUARD & B-52 BUTTON TO ELEMENTAL_AIRSTRIKE_MANAGER.GD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Adding menu hide guard & B-52 button to elemental_airstrike_manager.gd..." -ForegroundColor Cyan
$eamPath = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\elemental_airstrike_manager.gd"
@'
extends Node

var canvas: CanvasLayer
var panel: PanelContainer
var btn_dragon: Button
var btn_water: Button
var btn_poison: Button
var btn_b52: Button

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
	panel.offset_top = -102.0
	panel.offset_bottom = -76.0

	var empty_sb = StyleBoxEmpty.new()
	panel.add_theme_stylebox_override("panel", empty_sb)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 2)
	panel.add_child(hbox)

	btn_dragon = Button.new()
	btn_dragon.text = "🔥 7"
	btn_dragon.tooltip_text = "Dragon Firebombing (Press 7)"
	btn_dragon.custom_minimum_size = Vector2(34, 24)
	btn_dragon.add_theme_font_size_override("font_size", 9)
	btn_dragon.pressed.connect(_launch_dragon)
	hbox.add_child(btn_dragon)

	btn_water = Button.new()
	btn_water.text = "💧 8"
	btn_water.tooltip_text = "Water Bomber (Press 8)"
	btn_water.custom_minimum_size = Vector2(34, 24)
	btn_water.add_theme_font_size_override("font_size", 9)
	btn_water.pressed.connect(_launch_water)
	hbox.add_child(btn_water)

	btn_poison = Button.new()
	btn_poison.text = "☣️ 9"
	btn_poison.tooltip_text = "Poison Gas Strike (Press 9)"
	btn_poison.custom_minimum_size = Vector2(34, 24)
	btn_poison.add_theme_font_size_override("font_size", 9)
	btn_poison.pressed.connect(_launch_poison)
	hbox.add_child(btn_poison)

	btn_b52 = Button.new()
	btn_b52.text = "💣 0"
	btn_b52.tooltip_text = "B-52 Carpet Bomber (Press 0)"
	btn_b52.custom_minimum_size = Vector2(34, 24)
	btn_b52.add_theme_font_size_override("font_size", 9)
	btn_b52.pressed.connect(_launch_b52)
	hbox.add_child(btn_b52)

	canvas.add_child(panel)

func _process(_delta: float) -> void:
	var tree = get_tree()
	if not tree or not tree.root:
		return
	var in_mine: bool = is_instance_valid(tree.root.find_child("TileMapManager", true, false)) and is_instance_valid(tree.root.find_child("Player", true, false))
	var pause = tree.root.find_child("PauseMenu", true, false)
	if pause and pause.visible:
		in_mine = false

	if panel and panel.visible != in_mine:
		panel.visible = in_mine

func _unhandled_input(event: InputEvent) -> void:
	if not panel.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_7:
			_launch_dragon()
		elif event.keycode == KEY_8:
			_launch_water()
		elif event.keycode == KEY_9:
			_launch_poison()
		elif event.keycode == KEY_0:
			_launch_b52()

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

func _launch_b52() -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	var script = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/b52_carpet_strike.gd")
	if script:
		var strike = Node2D.new()
		strike.set_script(script)
		tree.current_scene.add_child(strike)
'@ | Set-Content -Path $eamPath -Encoding UTF8
Write-Host "  Updated: elemental_airstrike_manager.gd (In-mine guard + B-52 Carpet Bomber)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 8. ADD MENU HIDE GUARD TO SPEED_CONTROLLER.GD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 8. Adding menu hide guard to speed_controller.gd..." -ForegroundColor Cyan
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
	panel.offset_top = -42.0
	panel.offset_bottom = -16.0

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

func _process(_delta: float) -> void:
	var tree = get_tree()
	if not tree or not tree.root:
		return
	var in_mine: bool = is_instance_valid(tree.root.find_child("TileMapManager", true, false)) and is_instance_valid(tree.root.find_child("Player", true, false))
	var pause = tree.root.find_child("PauseMenu", true, false)
	if pause and pause.visible:
		in_mine = false

	if panel and panel.visible != in_mine:
		panel.visible = in_mine

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
Write-Host "  Updated: speed_controller.gd (Clean menu hide guard)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 9. REPACK ONLY AFFECTED MOD ARCHIVES (STRICTLY TARGETED)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 9. Repackaging strictly targeted mods to Steam..." -ForegroundColor Cyan
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

$targetedMods = @(
	"gareth-elemental_airstrikes_mod",
	"gareth-scrap_and_delivery_mod",
	"gareth-game_speed_mod"
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
# 10. COMMIT & PUSH
# ------------------------------------------------------------------------------
Write-Host "`n>>> 10. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Targeted Fix: Add B-52 Carpet Bomber, fix airstrike store buy_effects & texture methods, repair Amazon syntax, hide HUD in menus, and stack 150px HUD column"
git push origin main

Write-Host "`nTargeted deployment complete!" -ForegroundColor Green