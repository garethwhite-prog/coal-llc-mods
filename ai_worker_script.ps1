Clear-Host

# ==============================================================================
# Coal LLC - Part 2: Knight Swords (12-15) & Water Spirit Fairy Visuals
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

$knightInner= "$repo\mods-unpacked\gareth-knight_class_mod\mods-unpacked\gareth-knight_class_mod"
$wsInner    = "$repo\mods-unpacked\gareth-water_spirit_mod\mods-unpacked\gareth-water_spirit_mod"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 600

# ------------------------------------------------------------------------------
# 2. GENERATE DISTINCT 16x16 FAIRY / WISP ICONS FOR ALL 15 WATER SPIRIT TIERS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Generating 16x16 elemental fairy sprites for Water Spirit tiers..." -ForegroundColor Cyan
$wsTexDir = "$wsInner\textures"
if (-not (Test-Path $wsTexDir)) { New-Item -ItemType Directory -Path $wsTexDir -Force | Out-Null }

Add-Type -AssemblyName System.Drawing

$tierPalettes = @{
    "01_shoddy"      = [System.Drawing.Color]::FromArgb(255, 175, 180, 190) # Slate Grey
    "02_copper"      = [System.Drawing.Color]::FromArgb(255, 215, 125, 75)  # Copper Bronze
    "03_iron"        = [System.Drawing.Color]::FromArgb(255, 220, 225, 235) # Iron Silver
    "04_sapphire"    = [System.Drawing.Color]::FromArgb(255, 40, 150, 255)  # Sapphire Blue
    "05_emerald"     = [System.Drawing.Color]::FromArgb(255, 50, 230, 120)  # Emerald Green
    "06_silver"      = [System.Drawing.Color]::FromArgb(255, 235, 240, 255) # Pure Silver
    "07_amethyst"    = [System.Drawing.Color]::FromArgb(255, 180, 70, 240)  # Amethyst Purple
    "08_gold"        = [System.Drawing.Color]::FromArgb(255, 255, 215, 0)   # Golden Amber
    "09_ruby"        = [System.Drawing.Color]::FromArgb(255, 245, 40, 60)   # Ruby Crimson
    "10_diamond"     = [System.Drawing.Color]::FromArgb(255, 100, 245, 255) # Diamond Ice Blue
    "11_pinkdiamond" = [System.Drawing.Color]::FromArgb(255, 255, 105, 180) # Rose Pink
    "12_spinel"      = [System.Drawing.Color]::FromArgb(255, 220, 20, 90)   # Spinel Magenta
    "13_uranium"     = [System.Drawing.Color]::FromArgb(255, 60, 255, 20)   # Radioactive Green
    "14_moonstone"   = [System.Drawing.Color]::FromArgb(255, 160, 230, 255) # Pearlescent Pale Cyan
    "15_onyx"        = [System.Drawing.Color]::FromArgb(255, 50, 30, 65)    # Obsidian Purple
}

foreach ($tierKey in $tierPalettes.Keys) {
    $bmp = New-Object System.Drawing.Bitmap(16, 16)
    $c = $tierPalettes[$tierKey]
    $wingColor = [System.Drawing.Color]::FromArgb(180, [Math]::Min(255, $c.R + 40), [Math]::Min(255, $c.G + 40), [Math]::Min(255, $c.B + 40))
    $coreColor = [System.Drawing.Color]::FromArgb(255, [Math]::Min(255, $c.R + 60), [Math]::Min(255, $c.G + 60), [Math]::Min(255, $c.B + 60))
    $glowColor = [System.Drawing.Color]::FromArgb(210, $c.R, $c.G, $c.B)

    # Clear transparent
    for ($y=0; $y -lt 16; $y++) {
        for ($x=0; $x -lt 16; $x++) {
            $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
        }
    }

    # Fairy Wings (semi-translucent wisps)
    $bmp.SetPixel(4, 5, $wingColor); $bmp.SetPixel(5, 4, $wingColor); $bmp.SetPixel(6, 5, $wingColor)
    $bmp.SetPixel(9, 5, $wingColor); $bmp.SetPixel(10, 4, $wingColor); $bmp.SetPixel(11, 5, $wingColor)
    $bmp.SetPixel(4, 6, $wingColor); $bmp.SetPixel(11, 6, $wingColor)
    $bmp.SetPixel(5, 7, $wingColor); $bmp.SetPixel(10, 7, $wingColor)

    # Outer Orb Glow
    $bmp.SetPixel(7, 5, $glowColor); $bmp.SetPixel(8, 5, $glowColor)
    $bmp.SetPixel(6, 6, $glowColor); $bmp.SetPixel(9, 6, $glowColor)
    $bmp.SetPixel(6, 9, $glowColor); $bmp.SetPixel(9, 9, $glowColor)
    $bmp.SetPixel(7, 10, $glowColor); $bmp.SetPixel(8, 10, $glowColor)

    # Inner Fairy Orb
    for ($y=6; $y -le 9; $y++) {
        for ($x=7; $x -le 8; $x++) {
            $bmp.SetPixel($x, $y, $glowColor)
        }
    }
    # Bright magical core
    $bmp.SetPixel(7, 7, $coreColor); $bmp.SetPixel(8, 7, $coreColor)
    $bmp.SetPixel(7, 8, $coreColor); $bmp.SetPixel(8, 8, $coreColor)

    # Water droplet / trail tail
    $bmp.SetPixel(7, 11, $glowColor); $bmp.SetPixel(8, 11, $glowColor)
    $bmp.SetPixel(7, 12, $wingColor)

    $destFile = "$wsTexDir\spirit_$tierKey.png"
    $bmp.Save($destFile, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "  Generated: spirit_$tierKey.png" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 3. UPDATE WATER SPIRIT MOD_MAIN & SCRIPTS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Updating water_spirit_mod scripts..." -ForegroundColor Cyan

$wsMainPath = "$wsInner\mod_main.gd"
@'
extends Node

const MOD_DIR := "gareth-water_spirit_mod"

func _load_image_texture(path: String) -> Texture2D:
	if FileAccess.file_exists(path):
		var buffer = FileAccess.get_file_as_bytes(path)
		if buffer.size() > 0:
			var img = Image.new()
			if img.load_png_from_buffer(buffer) == OK:
				return ImageTexture.create_from_image(img)
	return null

func _ready() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks:
		return

	var tiers = [
		"01_shoddy", "02_copper", "03_iron", "04_sapphire", "05_emerald",
		"06_silver", "07_amethyst", "08_gold", "09_ruby", "10_diamond",
		"11_pinkdiamond", "12_spinel", "13_uranium", "14_moonstone", "15_onyx"
	]

	for t in tiers:
		var item_path := "res://mods-unpacked/gareth-water_spirit_mod/items/water_spirit_%s.tres" % t
		if ResourceLoader.exists(item_path):
			var item = load(item_path)
			var tex_path := "res://mods-unpacked/gareth-water_spirit_mod/textures/spirit_%s.png" % t
			var custom_tex = _load_image_texture(tex_path)
			if custom_tex and item:
				item.itemTexture = custom_tex
			if item and not (item in item_unlocks.all_equipment_items):
				item_unlocks.all_equipment_items.append(item)
			if item and not (item in item_unlocks.all_items):
				item_unlocks.all_items.append(item)

	ModLoaderLog.info("15 Water Spirit Fairy tiers loaded with custom textures.", MOD_DIR)
'@ | Set-Content -Path $wsMainPath -Encoding UTF8

$wsNodePath = "$wsInner\scripts\water_spirit_node.gd"
@'
class_name WaterSpiritNode
extends Node2D

var orbit_radius: float = 48.0
var rotation_speed: float = 12.0
var brush_radius: int = 1
var fairy_texture: Texture2D = null

var tilemap = null
var player = null
var current_rotation: float = 0.0

var centre: Node2D
var orb: Sprite2D
var trail: Sprite2D

func _ready() -> void:
	z_index = 50

	centre = Node2D.new()
	centre.name = "Centre"
	add_child(centre)

	var use_texture = fairy_texture
	if not use_texture:
		use_texture = load("res://assets/Equipment/kicks/kick_04_sapphire.png")

	orb = Sprite2D.new()
	orb.name = "Orb"
	orb.texture = use_texture
	orb.scale = Vector2(1.5, 1.5)
	orb.position = Vector2(orbit_radius, 0.0)
	centre.add_child(orb)

	trail = Sprite2D.new()
	trail.name = "Trail"
	trail.texture = use_texture
	trail.modulate = Color(0.1, 0.6, 1.0, 0.4)
	trail.scale = Vector2(1.0, 1.0)
	trail.position = Vector2(orbit_radius * 0.95, -12.0)
	centre.add_child(trail)

	_resolve_tilemap()

func _resolve_tilemap() -> void:
	if player and ("tilemap" in player) and player.tilemap:
		tilemap = player.tilemap

func _physics_process(delta: float) -> void:
	current_rotation += rotation_speed * delta
	if centre:
		centre.rotation = current_rotation

	if not tilemap:
		_resolve_tilemap()
		if not tilemap:
			return

	if orb:
		var tip_pos: Vector2 = orb.global_position
		var map_pos: Vector2i = tilemap.local_to_map(tilemap.to_local(tip_pos))
		for dx in range(-brush_radius, brush_radius + 1):
			for dy in range(-brush_radius, brush_radius + 1):
				var cell = map_pos + Vector2i(dx, dy)
				if tilemap.has_method("damageTileCoords"):
					tilemap.damageTileCoords(cell, 25.0)
'@ | Set-Content -Path $wsNodePath -Encoding UTF8

$wsEquipPath = "$wsInner\scripts\water_spirit_equip.gd"
@'
class_name WaterSpiritEquipEffect
extends EquipEffect

@export var orbit_radius: float = 48.0
@export var rotation_speed: float = 12.0
@export var brush_radius: int = 1

var held_item_texture: Texture2D = null

func start(_player, item):
	if item and item.itemTexture:
		held_item_texture = item.itemTexture

func end(_player):
	# Persistent companion pattern: hotbar swapping leaves the spirit node active
	pass

func physics_process(player, _delta):
	if not player:
		return

	if Input.is_action_just_pressed("useItem") or Input.is_action_just_pressed("toggle_use_item"):
		var existing = player.get_node_or_null("ActiveWaterSpirit")
		if existing and is_instance_valid(existing):
			existing.queue_free()
		else:
			_spawn_spirit(player)

func _spawn_spirit(player) -> void:
	var spirit_script = load("res://mods-unpacked/gareth-water_spirit_mod/scripts/water_spirit_node.gd")
	var spirit = Node2D.new()
	spirit.name = "ActiveWaterSpirit"
	spirit.set_script(spirit_script)
	spirit.orbit_radius = orbit_radius
	spirit.rotation_speed = rotation_speed
	spirit.brush_radius = brush_radius
	spirit.player = player
	spirit.fairy_texture = held_item_texture
	if "tilemap" in player:
		spirit.tilemap = player.tilemap

	player.call_deferred("add_child", spirit)
'@ | Set-Content -Path $wsEquipPath -Encoding UTF8
Write-Host "  Updated: water_spirit_mod scripts" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. UPDATE KNIGHT CLASS MOD_MAIN: PROGRAMMATIC REGISTRATION FOR TIERS 1-15
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Updating knight_class_mod mod_main.gd to load all 15 tiers programmatically..." -ForegroundColor Cyan

$knightMainPath = "$knightInner\mod_main.gd"
@'
extends Node

const MOD_DIR := "gareth-knight_class_mod"

const TIER_DATA := [
	{ "id": "01_shoddy",      "name": "Shoddy Knight Sword",        "dmg": 70.0,      "price": 0.0,                    "sell": 0.0 },
	{ "id": "02_copper",      "name": "Copper Knight Sword",        "dmg": 140.0,     "price": 2500.0,                 "sell": 1250.0 },
	{ "id": "03_iron",        "name": "Iron Knight Sword",          "dmg": 280.0,     "price": 8500.0,                 "sell": 4250.0 },
	{ "id": "04_sapphire",    "name": "Sapphire Knight Sword",      "dmg": 560.0,     "price": 24000.0,                "sell": 12000.0 },
	{ "id": "05_emerald",     "name": "Emerald Knight Sword",       "dmg": 1100.0,    "price": 75000.0,                "sell": 37500.0 },
	{ "id": "06_silver",      "name": "Silver Knight Sword",        "dmg": 2200.0,    "price": 220000.0,               "sell": 110000.0 },
	{ "id": "07_amethyst",    "name": "Amethyst Knight Sword",      "dmg": 4400.0,    "price": 650000.0,               "sell": 325000.0 },
	{ "id": "08_gold",        "name": "Gold Knight Sword",          "dmg": 8800.0,    "price": 1800000.0,              "sell": 900000.0 },
	{ "id": "09_ruby",        "name": "Ruby Knight Sword",          "dmg": 17500.0,   "price": 5000000.0,              "sell": 2500000.0 },
	{ "id": "10_diamond",     "name": "Diamond Knight Sword",       "dmg": 35000.0,   "price": 15000000.0,             "sell": 7500000.0 },
	{ "id": "11_pinkdiamond", "name": "Pink Diamond Knight Sword",  "dmg": 70000.0,   "price": 45000000.0,             "sell": 22500000.0 },
	{ "id": "12_spinel",      "name": "Spinel Knight Sword",        "dmg": 140000.0,  "price": 650000000.0,            "sell": 325000000.0 },
	{ "id": "13_uranium",     "name": "Uranium Knight Sword",       "dmg": 280000.0,  "price": 6500000000000.0,        "sell": 3250000000000.0 },
	{ "id": "14_moonstone",   "name": "Moonstone Knight Sword",     "dmg": 560000.0,  "price": 660000000000000000.0,   "sell": 330000000000000000.0 },
	{ "id": "15_onyx",        "name": "Onyx Knight Sword",          "dmg": 1120000.0, "price": 60000000000000000000000000.0, "sell": 30000000000000000000000000.0 }
]

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	if FileAccess.file_exists(path):
		var buffer = FileAccess.get_file_as_bytes(path)
		if buffer.size() > 0:
			var img = Image.new()
			if img.load_png_from_buffer(buffer) == OK:
				return ImageTexture.create_from_image(img)
	return null

func _ready() -> void:
	var reg = load("res://mods-unpacked/gareth-mod_manager_mod/scripts/mod_registry.gd")
	if reg and not reg.is_mod_active_for_run("knight_class"):
		return

	var item_script = load("res://resources/Items/Scripts/Item.gd")
	var buy_script = load("res://resources/BuyEffects/Scripts/AddToInventory.gd")
	var pickup_script = load("res://resources/PickupEffects/Scripts/PickupToInventory.gd")
	var equip_script = load("res://mods-unpacked/gareth-knight_class_mod/scripts/knight_sword_equip.gd")
	var pickup_sound = load("res://assets/sound/sound effects/SwordThud.wav")
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")

	for t in TIER_DATA:
		var item = item_script.new()
		item.itemID = "KnightSword_" + t["id"]
		item.itemName = t["name"]
		item.itemDescription = "Broadsword (%d damage). Sweeps in a wide 180° frontal arc cleaving rock and ore." % int(t["dmg"])
		item.itemType = "sword"
		item.itemBuyPrice = t["price"]
		item.itemSellPrice = t["sell"]
		item.itemUnlocked = true
		item.pickupSound = pickup_sound

		var tex_name = t["name"].replace(" Knight Sword", "").replace(" ", "")
		var tex_path = "res://assets/Equipment/Sword-%s.png" % tex_name
		if not ResourceLoader.exists(tex_path):
			tex_path = "res://mods-unpacked/gareth-knight_class_mod/textures/Sword-%s.png" % tex_name
		item.itemTexture = _load_texture(tex_path)

		var equip = equip_script.new()
		item.itemEquipEffect = equip
		item.itemBuyEffect = buy_script.new()
		item.itemPickupEffect = pickup_script.new()

		if item_unlocks:
			var already_registered := false
			for existing in item_unlocks.all_equipment_items:
				if existing and existing.itemID == item.itemID:
					already_registered = true
					break
			if not already_registered:
				item_unlocks.all_equipment_items.append(item)
			if not (item in item_unlocks.all_items):
				item_unlocks.all_items.append(item)

	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return

	var pm = Gvars.profession_manager
	var prof_script = load("res://mods-unpacked/gareth-knight_class_mod/scripts/knight_profession.gd")
	var p = prof_script.new()
	p.profession_name = "Knight"
	p.description = "Master of chivalric blade combat.\nStarts with a Shoddy Sword.\nAll 15 sword tiers, standalone weapons, and tools are purchasable."
	p.image = _load_texture("res://assets/Equipment/Sword-Shoddy.png")

	pm.all_professions[101] = { "profession": p, "is_unlocked": true }
	ModLoaderLog.info("15 Knight Sword tiers registered programmatically into shop.", MOD_DIR)
'@ | Set-Content -Path $knightMainPath -Encoding UTF8
Write-Host "  Updated: knight_class_mod mod_main.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. PURGE HOOK CACHE & REPACK MODS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Purging mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
	Remove-Item -Path $hookZip -Force
	Write-Host "  Removed: $hookZip" -ForegroundColor Green
}

Write-Host "`n>>> 6. Repackaging modified mods..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression.FileSystem

$modsToRepack = @(
	"gareth-knight_class_mod",
	"gareth-water_spirit_mod"
)

foreach ($m in $modsToRepack) {
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
	Write-Host "  Repacked: $m.zip" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 7. GIT STAGING, COMMIT & PUSH
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Staging, committing and pushing Part 2 to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Part 2: Programmatic Knight sword progression (tiers 12-15) and Water Spirit fairy icons & companion visuals"
git push origin main

Write-Host "`nPart 2 deployment complete!" -ForegroundColor Green