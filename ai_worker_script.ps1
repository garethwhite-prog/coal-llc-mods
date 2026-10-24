Clear-Host

# ==============================================================================
# Coal LLC - Deploy Mod 3: Elemental Airstrikes Triad (Dragon, Water Bomber, Agent Orange)
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

# ------------------------------------------------------------------------------
# 2. CREATE DIRECTORY STRUCTURE
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Creating directory structure for gareth-elemental_airstrikes_mod..." -ForegroundColor Cyan
$eaRoot     = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod"
$eaInner    = "$eaRoot\mods-unpacked\gareth-elemental_airstrikes_mod"
$eaScripts  = "$eaInner\scripts"

New-Item -ItemType Directory -Path $eaScripts -Force | Out-Null

$eaManifest = @"
{
  "name": "elemental_airstrikes_mod",
  "namespace": "gareth",
  "version_number": "1.0.0",
  "description": "Elemental Airstrike Triad: Dragon Strike (Fire), Water Bomber (Wetness), and Agent Orange Bomber (Poison).",
  "website_url": "https://github.com/garethwhite-prog/coal-llc-mods",
  "dependencies": ["gareth-mod_manager_mod"],
  "extra": {
    "godot": {
      "display_name": "Elemental Airstrikes Triad",
      "category": "Weapons & Arsenal",
      "authors": ["Gareth White"],
      "compatible_mod_loader_version": ["7.0.1"],
      "compatible_game_version": ["1.4.1.1"]
    }
  }
}
"@
Set-Content -Path "$eaRoot\manifest.json" -Value $eaManifest -Encoding UTF8
Set-Content -Path "$eaInner\manifest.json" -Value $eaManifest -Encoding UTF8

# ------------------------------------------------------------------------------
# 3. TEXTURE GENERATOR (PIXEL-ART SPRITES)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Writing texture_factory.gd..." -ForegroundColor Cyan
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
			if (y >= 14 and y <= 17 and x >= 3 and x <= 28):
				img.set_pixel(x, y, white)
			elif (x >= 14 and x <= 17 and y >= 4 and y <= 27):
				img.set_pixel(x, y, blue)
			elif (y >= 20 and y <= 22 and x >= 10 and x <= 22) or (y >= 9 and y <= 11 and x >= 10 and x <= 22):
				img.set_pixel(x, y, yellow)
	return ImageTexture.create_from_image(img)

static func create_agent_orange_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var dark_camo = Color(0.2, 0.28, 0.2, 1.0)
	var toxic_green = Color(0.3, 0.95, 0.25, 1.0)
	var dark_metal = Color(0.35, 0.38, 0.35, 1.0)
	for x in range(32):
		for y in range(32):
			if (y >= 13 and y <= 18 and x >= 2 and x <= 29):
				img.set_pixel(x, y, dark_camo)
			elif (abs(x - 16) <= (28 - y) and y >= 6 and y <= 26):
				img.set_pixel(x, y, dark_metal)
			elif (x in [10, 16, 22] and y in [14, 15, 16, 17]):
				img.set_pixel(x, y, toxic_green)
	return ImageTexture.create_from_image(img)
'@ | Set-Content -Path "$eaScripts\texture_factory.gd" -Encoding UTF8

# ------------------------------------------------------------------------------
# 4. ELEMENTAL FLYERS (DRAGON, WATER BOMBER, AGENT ORANGE)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Writing flyer scripts..." -ForegroundColor Cyan

# dragon_strike.gd
@'
class_name DragonStrike
extends Node2D

var damage: float = 180.0
var bomb_rate: float = 0.05
var speed: float = 280.0
var t: float = 0.0

var sprite: Sprite2D

func _ready() -> void:
	z_index = 60
	sprite = Sprite2D.new()
	sprite.texture = ElementalAirstrikeTextures.create_dragon_texture()
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
	if not tree:
		return
	var tilemaps = tree.get_nodes_in_group("tilemap")
	if tilemaps.is_empty():
		return
	var tm = tilemaps[0]

	var mult: float = 1.0
	if Gvars and ("passives" in Gvars) and Gvars.passives:
		if "fire_damage" in Gvars.passives:
			mult += float(Gvars.passives.fire_damage)
		if "airstrike_damage" in Gvars.passives:
			mult += float(Gvars.passives.airstrike_damage)

	var center_cell = tm.local_to_map(tm.to_local(pos))
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			if dx*dx + dy*dy <= 4:
				var cell = center_cell + Vector2i(dx, dy)
				if tm.has_method("damageTileCoords"):
					tm.damageTileCoords(cell, (damage * 0.4) * mult)
				if tm.has_method("burn_tile"):
					tm.burn_tile(pos, damage * mult, 20)
				elif "fires" in tm and tm.fires and tm.fires.has_method("add_fire_tile"):
					tm.fires.add_fire_tile(cell, damage * mult, 20)
'@ | Set-Content -Path "$eaScripts\dragon_strike.gd" -Encoding UTF8

# water_bomber_strike.gd
@'
class_name WaterBomberStrike
extends Node2D

var damage: float = 120.0
var drop_rate: float = 0.04
var speed: float = 260.0
var t: float = 0.0

var sprite: Sprite2D

func _ready() -> void:
	z_index = 60
	sprite = Sprite2D.new()
	sprite.texture = ElementalAirstrikeTextures.create_water_bomber_texture()
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
	if not tree:
		return
	var tilemaps = tree.get_nodes_in_group("tilemap")
	if tilemaps.is_empty():
		return
	var tm = tilemaps[0]

	var mult: float = 1.0
	if Gvars and ("passives" in Gvars) and Gvars.passives:
		if "wet_damage" in Gvars.passives:
			mult += float(Gvars.passives.wet_damage)
		if "airstrike_damage" in Gvars.passives:
			mult += float(Gvars.passives.airstrike_damage)

	var center_cell = tm.local_to_map(tm.to_local(pos))
	for dx in range(-3, 4):
		for dy in range(-2, 3):
			if dx*dx + dy*dy <= 7:
				var cell = center_cell + Vector2i(dx, dy)
				if tm.has_method("wet_tile_coords"):
					tm.wet_tile_coords(cell)
				elif tm.has_method("wet_tile"):
					tm.wet_tile(pos)
				if tm.has_method("damageTileCoords"):
					tm.damageTileCoords(cell, 35.0 * mult)
'@ | Set-Content -Path "$eaScripts\water_bomber_strike.gd" -Encoding UTF8

# agent_orange_strike.gd
@'
class_name AgentOrangeStrike
extends Node2D

var damage: float = 150.0
var spray_rate: float = 0.05
var speed: float = 240.0
var t: float = 0.0

var sprite: Sprite2D

func _ready() -> void:
	z_index = 60
	sprite = Sprite2D.new()
	sprite.texture = ElementalAirstrikeTextures.create_agent_orange_texture()
	sprite.scale = Vector2(2.2, 2.2)
	add_child(sprite)

func _process(delta: float) -> void:
	var speed_mod: float = (1.0 + 2.0 * abs(sprite.position.x / 1000.0))
	t += delta
	sprite.position.x -= delta * speed * speed_mod

	if sprite.position.x > 0:
		sprite.rotation_degrees = -15
		sprite.position.y += delta * speed * speed_mod * 0.4
	else:
		sprite.rotation_degrees = 15
		sprite.position.y -= delta * speed * speed_mod * 0.4

	if t > spray_rate:
		_spray_poison(sprite.global_position)
		t -= spray_rate

	if sprite.position.x < -1000:
		queue_free()

func _spray_poison(pos: Vector2) -> void:
	var tree = get_tree()
	if not tree:
		return
	var tilemaps = tree.get_nodes_in_group("tilemap")
	if tilemaps.is_empty():
		return
	var tm = tilemaps[0]

	var mult: float = 1.0
	if Gvars and ("passives" in Gvars) and Gvars.passives:
		if "poison_damage" in Gvars.passives:
			mult += float(Gvars.passives.poison_damage)
		if "airstrike_damage" in Gvars.passives:
			mult += float(Gvars.passives.airstrike_damage)

	var center_cell = tm.local_to_map(tm.to_local(pos))
	for dx in range(-3, 4):
		for dy in range(-2, 3):
			if dx*dx + dy*dy <= 6:
				var cell = center_cell + Vector2i(dx, dy)
				if tm.has_method("poison_tile_coords"):
					tm.poison_tile_coords(cell, damage * mult, 30)
				elif tm.has_method("poison_tile"):
					tm.poison_tile(pos, damage * mult, 30)
				elif "poisons" in tm and tm.poisons and tm.poisons.has_method("add_poison_tile"):
					tm.poisons.add_poison_tile(cell, damage * mult, 30)
				if tm.has_method("damageTileCoords"):
					tm.damageTileCoords(cell, 20.0 * mult)
'@ | Set-Content -Path "$eaScripts\agent_orange_strike.gd" -Encoding UTF8

# ------------------------------------------------------------------------------
# 5. AIR WINGS HUD CONTROLLER & SHORTCUT MANAGER
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Writing elemental_airstrike_manager.gd..." -ForegroundColor Cyan
@'
extends Node

var canvas: CanvasLayer
var panel: PanelContainer
var btn_dragon: Button
var btn_water: Button
var btn_poison: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()

func _build_hud() -> void:
	canvas = CanvasLayer.new()
	canvas.name = "AirWingsHUDCanvas"
	canvas.layer = 94
	add_child(canvas)

	panel = PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -348.0
	panel.offset_right = -16.0
	panel.offset_top = 58.0
	panel.offset_bottom = 92.0

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)

	btn_dragon = Button.new()
	btn_dragon.text = "🔥 Dragon (7)"
	btn_dragon.modulate = Color(1.0, 0.4, 0.2, 1.0)
	btn_dragon.tooltip_text = "Deploy Fire Dragon Airstrike [ Key 7 ]"
	btn_dragon.pressed.connect(func(): trigger_strike("dragon"))
	hbox.add_child(btn_dragon)

	btn_water = Button.new()
	btn_water.text = "💧 Water (8)"
	btn_water.modulate = Color(0.3, 0.7, 1.0, 1.0)
	btn_water.tooltip_text = "Deploy Water Bomber Airstrike [ Key 8 ]"
	btn_water.pressed.connect(func(): trigger_strike("water"))
	hbox.add_child(btn_water)

	btn_poison = Button.new()
	btn_poison.text = "☣️ Poison (9)"
	btn_poison.modulate = Color(0.4, 1.0, 0.4, 1.0)
	btn_poison.tooltip_text = "Deploy Agent Orange Poison Bomber [ Key 9 ]"
	btn_poison.pressed.connect(func(): trigger_strike("poison"))
	hbox.add_child(btn_poison)

	panel.add_child(hbox)
	canvas.add_child(panel)

func _process(_delta: float) -> void:
	var tree = get_tree()
	var in_game := false
	if tree and tree.root:
		var p = tree.root.find_child("Player", true, false)
		in_game = is_instance_valid(p)

	if panel:
		panel.visible = in_game

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_7:
			trigger_strike("dragon")
		elif event.keycode == KEY_8:
			trigger_strike("water")
		elif event.keycode == KEY_9:
			trigger_strike("poison")

func trigger_strike(strike_type: String) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return

	var p = tree.root.find_child("Player", true, false)
	var target_pos: Vector2 = p.global_position if is_instance_valid(p) else Vector2.ZERO

	var strike_node: Node2D = null
	if strike_type == "dragon":
		var scr = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/dragon_strike.gd")
		strike_node = Node2D.new()
		strike_node.set_script(scr)
	elif strike_type == "water":
		var scr = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/water_bomber_strike.gd")
		strike_node = Node2D.new()
		strike_node.set_script(scr)
	elif strike_type == "poison":
		var scr = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/agent_orange_strike.gd")
		strike_node = Node2D.new()
		strike_node.set_script(scr)

	if strike_node:
		strike_node.global_position = target_pos
		tree.current_scene.add_child(strike_node)

		var boom_audio = AudioStreamPlayer2D.new()
		boom_audio.stream = load("res://assets/sound/sound effects/box_1.wav")
		boom_audio.pitch_scale = 0.8
		boom_audio.global_position = target_pos
		tree.current_scene.add_child(boom_audio)
		boom_audio.play()
		boom_audio.finished.connect(boom_audio.queue_free)
'@ | Set-Content -Path "$eaScripts\elemental_airstrike_manager.gd" -Encoding UTF8

# ------------------------------------------------------------------------------
# 6. MOD_MAIN.GD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Writing mod_main.gd..." -ForegroundColor Cyan
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
	ModLoaderLog.info("Elemental Airstrikes Triad active! (Dragon [7], Water Bomber [8], Agent Orange [9])", MOD_DIR)

func _register_elemental_items() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks or not ("all_equipment_items" in item_unlocks):
		return

	var d_item = Item.new()
	d_item.itemID = "dragon_strike_whistle"
	d_item.itemName = "Dragon Strike Whistle"
	d_item.itemDescription = "Summon an ancient fiery dragon to carpet the mine in incendiary flame bursts."
	d_item.itemType = "equipment"
	d_item.itemBuyPrice = 45000.0
	d_item.itemSellPrice = 22500.0
	d_item.itemTexture = ElementalAirstrikeTextures.create_dragon_texture()
	item_unlocks.all_equipment_items.append(d_item)

	var w_item = Item.new()
	w_item.itemID = "water_bomber_radio"
	w_item.itemName = "Water Bomber Radio"
	w_item.itemDescription = "Call in an amphibious water plane to drench strata with elemental wet cascades."
	w_item.itemType = "equipment"
	w_item.itemBuyPrice = 35000.0
	w_item.itemSellPrice = 17500.0
	w_item.itemTexture = ElementalAirstrikeTextures.create_water_bomber_texture()
	item_unlocks.all_equipment_items.append(w_item)

	var p_item = Item.new()
	p_item.itemID = "agent_orange_transceiver"
	p_item.itemName = "Agent Orange Transceiver"
	p_item.itemDescription = "Order a heavy strategic bomber to deploy toxic chemical canisters across the dig site."
	p_item.itemType = "equipment"
	p_item.itemBuyPrice = 55000.0
	p_item.itemSellPrice = 27500.0
	p_item.itemTexture = ElementalAirstrikeTextures.create_agent_orange_texture()
	item_unlocks.all_equipment_items.append(p_item)
'@ | Set-Content -Path "$eaInner\mod_main.gd" -Encoding UTF8

# ------------------------------------------------------------------------------
# 7. REPACKAGING GARETH-ELEMENTAL_AIRSTRIKES_MOD.ZIP
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Repackaging gareth-elemental_airstrikes_mod.zip..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression.FileSystem

$src = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod"
$zip = "$steamMods\gareth-elemental_airstrikes_mod.zip"
if (Test-Path $zip) { Remove-Item -Path $zip -Force }

$stream  = [System.IO.File]::Open($zip, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $src -Recurse -File)) {
	$entryName = $f.FullName.Substring($src.Length + 1).Replace("\", "/")
	[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Write-Host "  Repacked: gareth-elemental_airstrikes_mod.zip" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 8. GIT STAGING, COMMIT & PUSH (DEDICATED MOD 3 COMMIT)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 8. Staging, committing and pushing Mod 3 to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Part 7: Implement Elemental Airstrikes Triad Mod (Dragon Fire, Water Bomber, Agent Orange Poison)"
git push origin main

Write-Host "`nMod 3: Elemental Airstrikes Triad deployed and committed cleanly!" -ForegroundColor Green