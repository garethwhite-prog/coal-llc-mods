Clear-Host

# ==============================================================================
# Coal LLC - Shop Sorter, Knight Tiers 12-15 & Water Sprite Autonomous Companion
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

$mmInner    = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod"
$knightInner= "$repo\mods-unpacked\gareth-knight_class_mod\mods-unpacked\gareth-knight_class_mod"
$wsInner    = "$repo\mods-unpacked\gareth-water_spirit_mod\mods-unpacked\gareth-water_spirit_mod"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 600

# ------------------------------------------------------------------------------
# 2. GENERATE SWORD TEXTURES FOR TIERS 12-15
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Generating pixel-art textures for Knight Swords 12-15..." -ForegroundColor Cyan
$knightTexDir = "$knightInner\textures"
if (-not (Test-Path $knightTexDir)) { New-Item -ItemType Directory -Path $knightTexDir -Force | Out-Null }

Add-Type -AssemblyName System.Drawing
$diamondPath = "$steamRoot\_dump\assets\Equipment\Sword-Diamond.png"
$baseBmp = [System.Drawing.Bitmap]::FromFile($diamondPath)

$newTiers = @{
    "Spinel"    = [System.Drawing.Color]::FromArgb(255, 220, 20, 90)    # Deep magenta-crimson
    "Uranium"   = [System.Drawing.Color]::FromArgb(255, 60, 255, 20)    # Fluorescent green
    "Moonstone" = [System.Drawing.Color]::FromArgb(255, 140, 230, 255)  # Pearlescent cyan
    "Onyx"      = [System.Drawing.Color]::FromArgb(255, 30, 30, 35)     # Obsidian charcoal
}

foreach ($t in $newTiers.Keys) {
    $outBmp = New-Object System.Drawing.Bitmap($baseBmp.Width, $baseBmp.Height)
    $targetColor = $newTiers[$t]

    for ($y = 0; $y -lt $baseBmp.Height; $y++) {
        for ($x = 0; $x -lt $baseBmp.Width; $x++) {
            $px = $baseBmp.GetPixel($x, $y)
            if ($px.A -gt 0) {
                # Preserve sword hilt/handle (brown/dark pixels)
                if ($px.R -gt 100 -and $px.G -lt 80 -and $px.B -lt 60) {
                    $outBmp.SetPixel($x, $y, $px)
                } elseif ($px.R -lt 50 -and $px.G -lt 50 -and $px.B -lt 50) {
                    $outBmp.SetPixel($x, $y, $px)
                } else {
                    # Tint the diamond blade pixels into the tier gemstone color
                    $brightness = ($px.R + $px.G + $px.B) / (3.0 * 255.0)
                    $nr = [Math]::Min(255, [int]($targetColor.R * (0.4 + 0.6 * $brightness)))
                    $ng = [Math]::Min(255, [int]($targetColor.G * (0.4 + 0.6 * $brightness)))
                    $nb = [Math]::Min(255, [int]($targetColor.B * (0.4 + 0.6 * $brightness)))
                    $outBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($px.A, $nr, $ng, $nb))
                }
            } else {
                $outBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
            }
        }
    }
    $texFile = "$knightTexDir\Sword-$t.png"
    $outBmp.Save($texFile, [System.Drawing.Imaging.ImageFormat]::Png)
    $outBmp.Dispose()
    Write-Host "  Generated: Sword-$t.png" -ForegroundColor Green
}
$baseBmp.Dispose()

# ------------------------------------------------------------------------------
# 3. BUILD KNIGHT SWORD TRES FILES (TIERS 12-15) & UPDATE KNIGHT MOD_MAIN
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Creating Knight Sword .tres items for Tiers 12-15..." -ForegroundColor Cyan
$knightItemData = @(
    @{ id = "12_spinel";    name = "Spinel Knight Sword";    dmg = "140000.0"; price = "650000000";         sell = "325000000";         tex = "Sword-Spinel.png" },
    @{ id = "13_uranium";   name = "Uranium Knight Sword";   dmg = "280000.0"; price = "6500000000000";     sell = "3250000000000";     tex = "Sword-Uranium.png" },
    @{ id = "14_moonstone"; name = "Moonstone Knight Sword"; dmg = "560000.0"; price = "660000000000000000"; sell = "330000000000000000"; tex = "Sword-Moonstone.png" },
    @{ id = "15_onyx";      name = "Onyx Knight Sword";      dmg = "1120000.0"; price = "60000000000000000000000000"; sell = "30000000000000000000000000"; tex = "Sword-Onyx.png" }
)

foreach ($kd in $knightItemData) {
    $itemPath = "$knightInner\items\KnightSword_$($kd.id).tres"
    $tresContent = @"
[gd_resource type="Resource" script_class="Item" load_steps=8 format=3]

[ext_resource type="Script" path="res://resources/BuyEffects/Scripts/AddToInventory.gd" id="1"]
[ext_resource type="Texture2D" path="res://mods-unpacked/gareth-knight_class_mod/textures/$($kd.tex)" id="2"]
[ext_resource type="Script" path="res://mods-unpacked/gareth-knight_class_mod/scripts/knight_sword_equip.gd" id="3"]
[ext_resource type="Script" path="res://resources/PickupEffects/Scripts/PickupToInventory.gd" id="4"]
[ext_resource type="AudioStream" path="res://assets/sound/sound effects/SwordThud.wav" id="5"]
[ext_resource type="Script" path="res://resources/Items/Scripts/Item.gd" id="6"]

[sub_resource type="Resource" id="Resource_buy"]
script = ExtResource("1")

[sub_resource type="Resource" id="Resource_equip"]
script = ExtResource("3")

[sub_resource type="Resource" id="Resource_pickup"]
script = ExtResource("4")

[resource]
script = ExtResource("6")
itemID = "KnightSword_$($kd.id)"
itemName = "$($kd.name)"
itemDescription = "Broadsword ($($kd.dmg) damage). Sweeps in a wide 180° frontal arc cleaving rock and ore."
itemTexture = ExtResource("2")
itemEquipEffect = SubResource("Resource_equip")
itemPickupEffect = SubResource("Resource_pickup")
pickupSound = ExtResource("5")
itemBuyPrice = $($kd.price)
itemSellPrice = $($kd.sell)
itemUnlocked = true
"@
    Set-Content -Path $itemPath -Value $tresContent -Encoding UTF8
    Write-Host "  Created: KnightSword_$($kd.id).tres" -ForegroundColor Green
}

# Update knight_class_mod mod_main.gd to load all 15 tiers
$kmMainPath = "$knightInner\mod_main.gd"
@'
extends Node

func _ready() -> void:
	var reg = load("res://mods-unpacked/gareth-mod_manager_mod/scripts/mod_registry.gd")
	if reg and not reg.is_mod_active_for_run("knight_class"):
		return

	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if item_unlocks:
		var all_tiers = [
			"01_shoddy", "02_copper", "03_iron", "04_sapphire", "05_emerald",
			"06_silver", "07_amethyst", "08_gold", "09_ruby", "10_diamond",
			"11_pinkdiamond", "12_spinel", "13_uranium", "14_moonstone", "15_onyx"
		]
		for id_str in all_tiers:
			var path := "res://mods-unpacked/gareth-knight_class_mod/items/KnightSword_%s.tres" % id_str
			if ResourceLoader.exists(path):
				var res = load(path)
				if res and not (res in item_unlocks.all_equipment_items):
					item_unlocks.all_equipment_items.append(res)

	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return

	var pm = Gvars.profession_manager
	var prof_script = load("res://mods-unpacked/gareth-knight_class_mod/scripts/knight_profession.gd")
	var p = prof_script.new()
	p.profession_name = "Knight"
	p.description = "Master of chivalric blade combat.\nStarts with a Shoddy Sword.\nAll 15 sword tiers, standalone mod weapons, and utilities are purchasable."
	if ResourceLoader.exists("res://assets/Equipment/Sword-Shoddy.png"):
		p.image = load("res://assets/Equipment/Sword-Shoddy.png")

	pm.all_professions[101] = { "profession": p, "is_unlocked": true }
'@ | Set-Content -Path $kmMainPath -Encoding UTF8
Write-Host "  Updated: knight_class_mod mod_main.gd with all 15 tiers" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. CONVERT WATER SPIRIT TO AUTONOMOUS PERSISTENT COMPANION (ROUNDHOUSE KICK PATTERN)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Updating water_spirit_equip.gd with autonomous toggle lifecycle..." -ForegroundColor Cyan
$wsEquipPath = "$wsInner\scripts\water_spirit_equip.gd"
@'
class_name WaterSpiritEquipEffect
extends EquipEffect

@export var orbit_radius: float = 48.0
@export var rotation_speed: float = 12.0
@export var brush_radius: int = 1

func start(_player, _item):
	pass

func end(_player):
	# Mirrors vanilla roundhouse kick: switching hotbar weapons leaves the active companion running
	pass

func physics_process(player, _delta):
	if not player:
		return

	var toggle_pressed: bool = false
	if Input.is_action_just_pressed("useItem") or Input.is_action_just_pressed("toggle_use_item"):
		toggle_pressed = true

	if toggle_pressed:
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
	if "tilemap" in player:
		spirit.tilemap = player.tilemap

	player.call_deferred("add_child", spirit)
'@ | Set-Content -Path $wsEquipPath -Encoding UTF8
Write-Host "  Updated: water_spirit_equip.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. CONFIGURE CENTRALIZED SHOP TIER SORTER IN MOD MANAGER
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Installing Centralized Shop Tier Sorter in mod_manager..." -ForegroundColor Cyan
$mgmtHookPath = "$mmInner\extensions\scenes\Stages\management_screen.hooks.gd"
@'
extends Object

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	_sort_equipment_catalog()
	chain.execute_next([])

func _sort_equipment_catalog() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks or not ("all_equipment_items" in item_unlocks) or not (item_unlocks.all_equipment_items is Array):
		return

	var original_list: Array = item_unlocks.all_equipment_items
	if original_list.is_empty():
		return

	var indexed_items: Array = []
	for i in range(original_list.size()):
		var it = original_list[i]
		if is_instance_valid(it):
			var rank: int = _get_tier_rank(it)
			indexed_items.append({ "item": it, "rank": rank, "orig_idx": i })

	indexed_items.sort_custom(func(a, b):
		if a["rank"] != b["rank"]:
			return a["rank"] < b["rank"]
		return a["orig_idx"] < b["orig_idx"]
	)

	var sorted_list: Array[Item] = []
	for entry in indexed_items:
		sorted_list.append(entry["item"])

	item_unlocks.all_equipment_items = sorted_list

func _get_tier_rank(it: Item) -> int:
	var id: String = str(it.itemID).to_lower()
	var nm: String = str(it.itemName).to_lower()
	var s: String = id + " " + nm

	# Material tiers checked in specific priority
	if "shoddy" in s: return 1
	if "copper" in s: return 2
	if "iron" in s: return 3
	if "sapphire" in s: return 4
	if "emerald" in s: return 5
	if "silver" in s: return 6
	if "amethyst" in s: return 7
	if "gold" in s: return 8
	if "ruby" in s: return 9
	if "pinkdiamond" in s or "pink_diamond" in s or "pink diamond" in s: return 11
	if "diamond" in s: return 10
	if "spinel" in s: return 12
	if "moonstone" in s: return 14
	if "onyx" in s: return 15
	if "uranium" in s: return 13

	# Top utilities (Ladders, bombs, mortars, drills, whistles)
	if ("ladder" in s or "platform" in s or "bomb" in s or "dynamite" in s or 
		"mortar" in s or "drill" in s or "teleporter" in s or "whistle" in s or 
		"gravity" in s or "water_staff" in s or "water_gun" in s):
		return 0

	# Bottom uniques and upgrades
	return 16
'@ | Set-Content -Path $mgmtHookPath -Encoding UTF8
Write-Host "  Updated: management_screen.hooks.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. PURGE HOOK CACHE & REPACK AFFECTED MODS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Purging mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
	Remove-Item -Path $hookZip -Force
	Write-Host "  Removed: $hookZip" -ForegroundColor Green
}

Write-Host "`n>>> 7. Repackaging modified mods..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$modsToPack = @("gareth-mod_manager_mod", "gareth-knight_class_mod", "gareth-water_spirit_mod")
foreach ($m in $modsToPack) {
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

Write-Host "`n>>> 8. Git commit and push..." -ForegroundColor Cyan
git add -A
git commit -m "Organize shop by tiers, expand Knight swords to Onyx, and enable Water Spirit autonomous loop"
git push origin main

Write-Host "`nDeployment complete. Launch Coal LLC to verify!" -ForegroundColor Green