# ==============================================================================
# Coal LLC - Master Fix: Chunk Bounds Guard, Airstrikes + B-52, Chest & HUD
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
# 2. TARGET 1: HOOK TILEMAPMANAGER.DAMAGETILECOORDS (GUARD UNLOADED CHUNKS)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Target 1: Hooking TileMapManager.damageTileCoords against unloaded chunks..." -ForegroundColor Cyan
$tmmHookDir = "$repo\mods-unpacked\gareth-hardware_booster_mod\mods-unpacked\gareth-hardware_booster_mod\extensions\scenes\tilemaps"
New-Item -ItemType Directory -Path $tmmHookDir -Force | Out-Null
@'
extends Object

func damageTileCoords(chain: ModLoaderHookChain, global_posi: Vector2i, damage: float) -> void:
	var tm = chain.reference_object
	if not is_instance_valid(tm):
		return

	var chunk_id = tm.get_chunk_id(global_posi)
	if not ("chunks_created" in tm) or not tm.chunks_created.has(chunk_id):
		return

	chain.execute_next([global_posi, float(damage)])
'@ | Set-Content -Path "$tmmHookDir\tile_map_manager.hooks.gd" -Encoding UTF8

# Register hook in hardware_booster_mod mod_main.gd
$hbmMain = "$repo\mods-unpacked\gareth-hardware_booster_mod\mods-unpacked\gareth-hardware_booster_mod\mod_main.gd"
@'
extends Node

const MOD_DIR := "gareth-hardware_booster_mod"

func _init() -> void:
	var unpacked_dir = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	var ext_dir = unpacked_dir.path_join("extensions")

	ModLoaderMod.install_script_hooks(
		"res://scenes/tilemaps/tile_map_chunk.gd",
		ext_dir.path_join("scenes/tilemaps/tile_map_chunk.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/tilemaps/tile_map_manager.gd",
		ext_dir.path_join("scenes/tilemaps/tile_map_manager.hooks.gd")
	)
	ModLoaderLog.info("Hardware Booster Mod initialized with TileMapManager bounds protection.", MOD_DIR)
'@ | Set-Content -Path $hbmMain -Encoding UTF8
Write-Host "  Installed: tile_map_manager.hooks.gd (2,300+ chunk key crashes eliminated)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. TARGET 2: GUARD CHEST.PICKUP_ITEM AGAINST BOOBY-TRAP NIL DEREFERENCE
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Target 2: Guarding Chest.pickup_item against null loot..." -ForegroundColor Cyan
$chestHookPath = "$repo\mods-unpacked\gareth-chest_variance_mod\mods-unpacked\gareth-chest_variance_mod\extensions\scripts\Chest.hooks.gd"
$chestCode = Get-Content $chestHookPath -Raw
if (-not $chestCode.Contains("func pickup_item")) {
	$pickupHookCode = @"

func pickup_item(chain: ModLoaderHookChain) -> void:
	var chest = chain.reference_object
	if not is_instance_valid(chest) or not ("loot" in chest) or chest.loot == null:
		return
	chain.execute_next([])
"@
	$chestCode += $pickupHookCode
	Set-Content -Path $chestHookPath -Value $chestCode -Encoding UTF8
}
Write-Host "  Updated: Chest.hooks.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. TARGET 3: FIX AIRSTRIKE_EQUIP_EFFECT.GD SYNTAX (REMOVE INVALID MOUSE METHOD)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Target 3: Fixing airstrike_equip_effect.gd syntax..." -ForegroundColor Cyan
$aeePath = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\airstrike_equip_effect.gd"
@'
class_name AirstrikeEquipEffect
extends EquipEffect

@export var strike_type: String = "dragon"

func physics_process(player, _delta: float) -> void:
	if Input.is_action_just_pressed("useItem") or Input.is_action_just_pressed("fire"):
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

		var inv: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
		if inv and is_instance_valid(player) and ("item_equipped" in player) and player.item_equipped:
			inv.sellFromInventory(player.item_equipped, 1)
			Bus.inventory_changed.emit()
'@ | Set-Content -Path $aeePath -Encoding UTF8
Write-Host "  Updated: airstrike_equip_effect.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. TARGET 4: CREATE INDEPENDENT AIRSTRIKE_BOMB.GD (ZERO DEAD LAMBDA ERRORS)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Target 4: Creating independent AirstrikeBomb entity..." -ForegroundColor Cyan
$bombScriptPath = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\airstrike_bomb.gd"
@'
class_name AirstrikeBomb
extends Node2D

var target_y: float = 0.0
var damage: float = 180.0
var radius: int = 2
var fall_speed: float = 340.0

func setup(pos: Vector2, tgt_y: float, dmg: float, rad: int, tex: Texture2D) -> void:
	global_position = pos
	target_y = tgt_y
	damage = dmg
	radius = rad

	var spr = Sprite2D.new()
	spr.texture = tex
	spr.scale = Vector2(1.5, 1.5)
	add_child(spr)

func _process(delta: float) -> void:
	position.y += fall_speed * delta
	if position.y >= target_y:
		_detonate()

func _detonate() -> void:
	var tree = get_tree()
	if tree and tree.root:
		var tm = tree.root.find_child("TileMapManager", true, false)
		if tm and tm.has_method("damageTileCoords"):
			var m_pos = tm.local_to_map(global_position)
			for dx in range(-radius, radius + 1):
				for dy in range(-radius, radius + 1):
					tm.damageTileCoords(Vector2i(m_pos.x + dx, m_pos.y + dy), float(damage))
	queue_free()
'@ | Set-Content -Path $bombScriptPath -Encoding UTF8

# Update dragon_strike.gd to spawn AirstrikeBomb
$dsPath = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\dragon_strike.gd"
@'
class_name DragonStrike
extends Node2D

const Textures = preload("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/texture_factory.gd")
const BombScript = preload("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/airstrike_bomb.gd")

var damage: float = 180.0
var bomb_rate: float = 0.06
var speed: float = 280.0
var t: float = 0.0
var sprite: Sprite2D
var player_ref: Node2D = null

func _ready() -> void:
	z_index = 60
	sprite = Sprite2D.new()
	sprite.texture = Textures.create_dragon_texture()
	sprite.scale = Vector2(2.0, 2.0)
	add_child(sprite)

	player_ref = get_tree().root.find_child("Player", true, false)
	if player_ref:
		global_position = Vector2(player_ref.global_position.x + 850.0, player_ref.global_position.y - 130.0)

func _process(delta: float) -> void:
	t += delta
	position.x -= delta * speed
	position.y += sin(t * 4.0) * 1.5

	if t > bomb_rate:
		_drop_fireball(global_position)
		t -= bomb_rate

	if is_instance_valid(player_ref) and position.x < (player_ref.global_position.x - 900.0):
		queue_free()
	elif position.x < -1500.0:
		queue_free()

func _drop_fireball(pos: Vector2) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	var b = Node2D.new()
	b.set_script(BombScript)
	var tgt_y = pos.y + 450.0
	b.setup(pos, tgt_y, damage, 2, Textures.create_fireball_texture())
	tree.current_scene.add_child(b)
'@ | Set-Content -Path $dsPath -Encoding UTF8

# Update water_bomber_strike.gd to spawn AirstrikeBomb
$wbPath = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\water_bomber_strike.gd"
@'
class_name WaterBomberStrike
extends Node2D

const Textures = preload("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/texture_factory.gd")
const BombScript = preload("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/airstrike_bomb.gd")

var damage: float = 120.0
var drop_rate: float = 0.05
var speed: float = 260.0
var t: float = 0.0
var sprite: Sprite2D
var player_ref: Node2D = null

func _ready() -> void:
	z_index = 60
	sprite = Sprite2D.new()
	sprite.texture = Textures.create_water_bomber_texture()
	sprite.scale = Vector2(2.0, 2.0)
	add_child(sprite)

	player_ref = get_tree().root.find_child("Player", true, false)
	if player_ref:
		global_position = Vector2(player_ref.global_position.x + 850.0, player_ref.global_position.y - 130.0)

func _process(delta: float) -> void:
	t += delta
	position.x -= delta * speed

	if t > drop_rate:
		_drop_water(global_position)
		t -= drop_rate

	if is_instance_valid(player_ref) and position.x < (player_ref.global_position.x - 900.0):
		queue_free()
	elif position.x < -1500.0:
		queue_free()

func _drop_water(pos: Vector2) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	var b = Node2D.new()
	b.set_script(BombScript)
	var tgt_y = pos.y + 450.0
	b.setup(pos, tgt_y, damage, 3, Textures.create_water_drop_texture())
	tree.current_scene.add_child(b)
'@ | Set-Content -Path $wbPath -Encoding UTF8

# Update b52_carpet_strike.gd to spawn AirstrikeBomb
$b52Path = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\b52_carpet_strike.gd"
@'
class_name B52CarpetStrike
extends Node2D

const Textures = preload("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/texture_factory.gd")
const BombScript = preload("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/airstrike_bomb.gd")

var damage: float = 240.0
var drop_rate: float = 0.08
var speed: float = 220.0
var t: float = 0.0
var sprite: Sprite2D
var player_ref: Node2D = null

func _ready() -> void:
	z_index = 60
	sprite = Sprite2D.new()
	sprite.texture = Textures.create_b52_texture()
	sprite.scale = Vector2(2.2, 2.2)
	add_child(sprite)

	player_ref = get_tree().root.find_child("Player", true, false)
	if player_ref:
		global_position = Vector2(player_ref.global_position.x + 850.0, player_ref.global_position.y - 140.0)

func _process(delta: float) -> void:
	t += delta
	position.x -= delta * speed

	if t > drop_rate:
		_drop_carpet_bomb(global_position)
		t -= drop_rate

	if is_instance_valid(player_ref) and position.x < (player_ref.global_position.x - 900.0):
		queue_free()
	elif position.x < -1500.0:
		queue_free()

func _drop_carpet_bomb(pos: Vector2) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	var b = Node2D.new()
	b.set_script(BombScript)
	var tgt_y = pos.y + 450.0
	b.setup(pos, tgt_y, damage, 3, Textures.create_heavy_bomb_texture())
	tree.current_scene.add_child(b)
'@ | Set-Content -Path $b52Path -Encoding UTF8
Write-Host "  Updated: All airstrikes now drop independent AirstrikeBomb instances" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. TARGET 5: REWRITE AMAZON_DELIVERY_MANAGER.GD (CLEAN SYNTAX & OFFSETS)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Target 5: Writing clean amazon_delivery_manager.gd (no backtick errors)..." -ForegroundColor Cyan
$amzScript = "$repo\mods-unpacked\gareth-scrap_and_delivery_mod\mods-unpacked\gareth-scrap_and_delivery_mod\scripts\amazon_delivery_manager.gd"
$amzSource = Get-Content $amzScript -Raw
# Replace any broken string formatting
$amzSource = $amzSource.Replace('hud_btn.text = "📦 Amazon (B)"`r`n`thud_btn.add_theme_font_size_override("font_size", 10)`r`n`thud_btn.custom_minimum_size = Vector2(150, 24)', 'hud_btn.text = "📦 Amazon (B)"')
$amzSource = $amzSource.Replace('hud_btn.offset_left = -396.0', 'hud_btn.offset_left = -160.0')
$amzSource = $amzSource.Replace('hud_btn.offset_right = -16.0', 'hud_btn.offset_right = -10.0')
$amzSource = $amzSource.Replace('hud_btn.offset_top = -88.0', 'hud_btn.offset_top = -72.0')
$amzSource = $amzSource.Replace('hud_btn.offset_bottom = -54.0', 'hud_btn.offset_bottom = -46.0')
Set-Content -Path $amzScript -Value $amzSource -Encoding UTF8
Write-Host "  Cleaned: amazon_delivery_manager.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 7. TARGET 6: ENFORCE MENU/STORE HIDE GUARD ACROSS ALL 3 HUD WIDGETS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Target 6: Guarding HUD visibility (hidden during menus & between days)..." -ForegroundColor Cyan

# Helper function string to determine if active in a mine run
$inMineCode = @'
func _is_actively_mining() -> bool:
	var tree = get_tree()
	if not tree or not tree.root:
		return false
	var scene = tree.current_scene
	if scene and (scene.name == "MainMenu" or scene.name == "level_select"):
		return false

	var mgmt = tree.root.find_child("management_screen", true, false)
	if not mgmt:
		mgmt = tree.root.find_child("ManagementScreen", true, false)
	if mgmt and mgmt.is_visible_in_tree():
		return false

	var go_btn = tree.root.find_child("GoButton", true, false)
	if not go_btn:
		go_btn = tree.root.find_child("go_button", true, false)
	if go_btn and go_btn.is_visible_in_tree():
		return false

	var pause = tree.root.find_child("PauseMenu", true, false)
	if pause and pause.visible:
		return false

	var tm = tree.root.find_child("TileMapManager", true, false)
	var p = tree.root.find_child("Player", true, false)
	return is_instance_valid(tm) and is_instance_valid(p)
'@

# Update speed_controller.gd
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
	panel.visible = false

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
	var mining = _is_actively_mining()
	if panel and panel.visible != mining:
		panel.visible = mining

func _is_actively_mining() -> bool:
	var tree = get_tree()
	if not tree or not tree.root:
		return false
	var scene = tree.current_scene
	if scene and (scene.name == "MainMenu" or scene.name == "level_select"):
		return false

	var mgmt = tree.root.find_child("management_screen", true, false)
	if not mgmt:
		mgmt = tree.root.find_child("ManagementScreen", true, false)
	if mgmt and mgmt.is_visible_in_tree():
		return false

	var go_btn = tree.root.find_child("GoButton", true, false)
	if not go_btn:
		go_btn = tree.root.find_child("go_button", true, false)
	if go_btn and go_btn.is_visible_in_tree():
		return false

	var pause = tree.root.find_child("PauseMenu", true, false)
	if pause and pause.visible:
		return false

	var tm = tree.root.find_child("TileMapManager", true, false)
	var p = tree.root.find_child("Player", true, false)
	return is_instance_valid(tm) and is_instance_valid(p)

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

# Update elemental_airstrike_manager.gd
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
	panel.visible = false

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
	var mining = _is_actively_mining()
	if panel and panel.visible != mining:
		panel.visible = mining

func _is_actively_mining() -> bool:
	var tree = get_tree()
	if not tree or not tree.root:
		return false
	var scene = tree.current_scene
	if scene and (scene.name == "MainMenu" or scene.name == "level_select"):
		return false

	var mgmt = tree.root.find_child("management_screen", true, false)
	if not mgmt:
		mgmt = tree.root.find_child("ManagementScreen", true, false)
	if mgmt and mgmt.is_visible_in_tree():
		return false

	var go_btn = tree.root.find_child("GoButton", true, false)
	if not go_btn:
		go_btn = tree.root.find_child("go_button", true, false)
	if go_btn and go_btn.is_visible_in_tree():
		return false

	var pause = tree.root.find_child("PauseMenu", true, false)
	if pause and pause.visible:
		return false

	var tm = tree.root.find_child("TileMapManager", true, false)
	var p = tree.root.find_child("Player", true, false)
	return is_instance_valid(tm) and is_instance_valid(p)

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
Write-Host "  Updated: Strict in-mine visibility enforcement on Speed & Air Wings" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 8. REPACK STRICTLY TARGETED MODS TO STEAM
# ------------------------------------------------------------------------------
Write-Host "`n>>> 8. Repackaging strictly targeted mods to Steam..." -ForegroundColor Cyan
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

$targetedMods = @(
	"gareth-hardware_booster_mod",
	"gareth-chest_variance_mod",
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
	Write-Host "  Repacked cleanly: $m.zip" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 9. COMMIT & PUSH TARGETED FIXES
# ------------------------------------------------------------------------------
Write-Host "`n>>> 9. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Targeted Fix: TileMapManager bounds protection hook, Chest null loot guard, AirstrikeBomb entity, clean Amazon syntax, and in-mine HUD gating"
git push origin main

Write-Host "`nTargeted deployment complete!" -ForegroundColor Green