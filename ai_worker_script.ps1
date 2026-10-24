Clear-Host

# ==============================================================================
# Coal LLC - Part 4: Chest Tier Variance Mod & Documentation (COLLISION-FREE)
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot instances..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 600

# ------------------------------------------------------------------------------
# 2. CREATE GARETH-CHEST_VARIANCE_MOD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Creating gareth-chest_variance_mod..." -ForegroundColor Cyan
$cvRoot  = "$repo\mods-unpacked\gareth-chest_variance_mod"
$cvInner = "$cvRoot\mods-unpacked\gareth-chest_variance_mod"
$cvExt   = "$cvInner\extensions\scripts"
New-Item -ItemType Directory -Path $cvExt -Force | Out-Null

# Dual Manifests
$cvManifest = @"
{
  "name": "chest_variance_mod",
  "namespace": "gareth",
  "version_number": "1.0.0",
  "description": "Dynamic chest tier variance, weighted class weapon seeding, and dangerous booby-trap explosions.",
  "website_url": "[https://github.com/garethwhite-prog/coal-llc-mods](https://github.com/garethwhite-prog/coal-llc-mods)",
  "dependencies": [],
  "extra": {
    "godot": {
      "compatible_game_version": ["1.0.0"]
    }
  }
}
"@
Set-Content -Path "$cvRoot\manifest.json" -Value $cvManifest -Encoding UTF8
Set-Content -Path "$cvInner\manifest.json" -Value $cvManifest -Encoding UTF8

# Dual READMEs
$cvReadme = @"
# Chest Tier Variance & Trap Explosions Mod

Introduces roguelite risk/reward dynamics to subterranean chests in Coal LLC:
- **Tier Variance:** Opening a chest rolls a weighted tier shift (+/- 1 tier: 15% chance; +/- 2 tiers: 5% jackpot/dud chance).
- **Class Weapon Seeding:** Injects custom class weapons (Knight Broadswords, Jedi Energy Sabers, custom tanks) into the power-up scroll pool.
- **Bonus Percentage Scaling:** Passive upgrade scrolls dynamically scale their bonus percentages to match the shifted tier level.
- **Booby-Trap Explosions:** 3% chance a chest triggers a kinetic shockwave upon opening, shattering nearby rock.
"@
Set-Content -Path "$cvRoot\README.md" -Value $cvReadme -Encoding UTF8
Set-Content -Path "$cvInner\README.md" -Value $cvReadme -Encoding UTF8

# mod_main.gd
@'
extends Node

const MOD_DIR := "gareth-chest_variance_mod"

func _init() -> void:
	ModLoaderMod.install_script_extension("res://mods-unpacked/gareth-chest_variance_mod/extensions/scripts/Chest.hooks.gd")

func _ready() -> void:
	ModLoaderLog.info("Chest Variance, Class Seeding & Trap Mod active!", MOD_DIR)
'@ | Set-Content -Path "$cvInner\mod_main.gd" -Encoding UTF8

# Chest.hooks.gd
@'
extends Object

const PASSIVE_RES_PATH := "res://resources/Items/power_ups/PassiveUpgrade.tres"

func roll_loot(chain: ModLoaderHookChain) -> void:
	var chest = chain.reference_object
	if not is_instance_valid(chest):
		chain.execute_next([])
		return

	# 3% chance of a booby-trap explosion
	if randf() < 0.03:
		_trigger_trap_explosion(chest)
		return

	# Tier variance roll:
	# -2 tiers: 5% | -1 tier: 15% | 0 (base): 60% | +1 tier: 15% | +2 tiers: 5%
	var roll: float = randf()
	var tier_shift: int = 0
	if roll < 0.05:
		tier_shift = -2
	elif roll < 0.20:
		tier_shift = -1
	elif roll > 0.95:
		tier_shift = 2
	elif roll > 0.80:
		tier_shift = 1

	var original_level: int = chest.loot_level
	var effective_level: int = clampi(original_level + tier_shift, 1, 15)
	chest.loot_level = effective_level

	chain.execute_next([])

	# Scale passive upgrade multipliers to match effective tier
	if is_instance_valid(chest.loot) and chest.loot.itemType == "passive_upgrade":
		if chest.loot.itemPickupEffect and ("multiplier" in chest.loot.itemPickupEffect):
			if effective_level <= 4:
				chest.loot.itemPickupEffect.multiplier = float(effective_level)
			else:
				chest.loot.itemPickupEffect.multiplier = float(effective_level ** 2)

	# Seed custom class weapons into power-up scroll drops
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if item_unlocks and is_instance_valid(chest.loot) and chest.loot.itemType == "scroll":
		var candidates: Array = []
		for it in item_unlocks.all_equipment_items:
			if is_instance_valid(it) and it.itemType in ["sword", "jedi_saber", "tank_fire", "tank_poison", "tank_uranium"]:
				candidates.append(it)
		if candidates.size() > 0 and randf() < 0.35:
			var custom_weapon = candidates.pick_random()
			chest.loot = chest.generate_power_up_scroll_for_item(custom_weapon)

	chest.loot_level = original_level

func _trigger_trap_explosion(chest: Node2D) -> void:
	chest.looted = true
	chest.opened = true
	if "sprite_empty" in chest and is_instance_valid(chest.sprite_empty):
		chest.sprite_empty.visible = true
	if "sprite_closed" in chest and is_instance_valid(chest.sprite_closed):
		chest.sprite_closed.visible = false
	if "sprite_open" in chest and is_instance_valid(chest.sprite_open):
		chest.sprite_open.visible = false

	var tree = chest.get_tree()
	if not tree:
		return

	var tilemaps = tree.get_nodes_in_group("tilemap")
	var tilemap = tilemaps[0] if tilemaps.size() > 0 else null

	var center_pos: Vector2 = chest.global_position
	if tilemap and tilemap.has_method("damageTileCoords"):
		var center_cell: Vector2i = tilemap.local_to_map(tilemap.to_local(center_pos))
		for dx in range(-3, 4):
			for dy in range(-3, 4):
				if dx*dx + dy*dy <= 9:
					var cell = center_cell + Vector2i(dx, dy)
					tilemap.damageTileCoords(cell, 350.0)

	var boom_audio = AudioStreamPlayer2D.new()
	boom_audio.stream = load("res://assets/sound/sound effects/box_1.wav")
	boom_audio.global_position = center_pos
	tree.current_scene.add_child(boom_audio)
	boom_audio.play()
	boom_audio.finished.connect(boom_audio.queue_free)
'@ | Set-Content -Path "$cvExt\Chest.hooks.gd" -Encoding UTF8
Write-Host "  Created: gareth-chest_variance_mod scripts" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. UPDATE SESSION_PROMPT.MD (COLLISION-FREE STRING BUILD)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Updating SESSION_PROMPT.md..." -ForegroundColor Cyan
$sessPromptPath = "$repo\SESSION_PROMPT.md"
if (Test-Path $sessPromptPath) {
	$sessContent = Get-Content $sessPromptPath -Raw
	if ($sessContent -notmatch "Custom Profession Persistence") {
		$b3 = [char]96 + [char]96 + [char]96
		$b1 = [char]96
		$sessAdditions = @"

## 4. Custom Profession Persistence & Serialization
- Gvars ${b1}save_Gvars()${b1} hardcodes an iteration over ${b1}profession_manager.Professions.values()${b1}, which only contains base game enum IDs (0 to 11).
- Custom classes with IDs >= 100 (e.g. Knight = 101, Jedi = 102) fail to serialize, falling back to Barbarian or leaving ${b1}Gvars.profession${b1} null on reload.
- Always use a ${b1}save_Gvars${b1} and ${b1}load_Gvars${b1} post-hook in ${b1}gareth-mod_manager_mod${b1} to map custom IDs directly against ${b1}Gvars.profession_manager.all_professions${b1}.

## 5. Virtual Filesystem Image Loading in Godot 4 Zips
- Loose PNG textures packed inside ${b1}.zip${b1} archives fail ${b1}ResourceLoader.load()${b1} because Godot lacks pre-compiled ${b1}.png.import${b1} files.
- ${b1}Image.load_from_file()${b1} also fails inside virtual mounts (${b1}res://${b1}).
- Always decode PNGs via memory buffers:
$b3
var buffer = FileAccess.get_file_as_bytes(path)
var img = Image.new()
if img.load_png_from_buffer(buffer) == OK:
    return ImageTexture.create_from_image(img)
$b3

## 6. Equipment Shop Search, Sorter & Passive Panel
- Shop items are rendered in ${b1}%EquipmentShop${b1} as instances of ${b1}ShopItemCard${b1}.
- Filters and sorters must be injected into the ${b1}VBoxContainer${b1} directly above the ${b1}ScrollContainer${b1}.
- ${b1}PassiveBonuses.gd${b1} only iterates ${b1}ChoosePassive.ALL_PASSIVES${b1}. Worker and custom class weapon stats in ${b1}Gvars.passives${b1} must be appended in a post-hook on ${b1}PassiveBonuses:refresh()${b1}.

## 7. Subterranean Chest Variance & Loot Seeding
- ${b1}Chest.gd${b1} rolls loot via ${b1}roll_loot()${b1}.
- Modifying ${b1}chest.loot_level${b1} before executing ${b1}chain.execute_next()${b1} shifts the rolled stratum tier (+/- 1 or +/- 2).
- Custom class weapons and tanks can be seeded into ${b1}chest.loot${b1} by overriding ${b1}chest.loot${b1} when ${b1}chest.loot.itemType == "scroll"${b1}.
"@
		Add-Content -Path $sessPromptPath -Value $sessAdditions -Encoding UTF8
		Write-Host "  Updated: SESSION_PROMPT.md" -ForegroundColor Green
	}
}

# ------------------------------------------------------------------------------
# 4. UPDATE ROOT README.MD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Updating root README.md..." -ForegroundColor Cyan
$readmePath = "$repo\README.md"
if (Test-Path $readmePath) {
	$readmeContent = Get-Content $readmePath -Raw
	if ($readmeContent -notmatch "chest_variance_mod") {
		$newModRow = "| **Chest Tier Variance** | `gareth-chest_variance_mod` | Mechanics | Roguelite chest rolls with +/- 2 tier variance, custom class weapon seeding, and booby-trap explosions. |`n"
		$readmeContent = $readmeContent.Replace("| **Water Spirit**", "$newModRow| **Water Spirit**")
		Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
		Write-Host "  Updated: root README.md" -ForegroundColor Green
	}
}

# ------------------------------------------------------------------------------
# 5. PURGE HOOK CACHE & REPACK CHEST VARIANCE MOD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Purging mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
	Remove-Item -Path $hookZip -Force
	Write-Host "  Removed: $hookZip" -ForegroundColor Green
}

Write-Host "`n>>> 6. Repackaging gareth-chest_variance_mod..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression.FileSystem

$src = "$repo\mods-unpacked\gareth-chest_variance_mod"
$zip = "$steamMods\gareth-chest_variance_mod.zip"
if (Test-Path $zip) { Remove-Item -Path $zip -Force }

$stream  = [System.IO.File]::Open($zip, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $src -Recurse -File)) {
	$entryName = $f.FullName.Substring($src.Length + 1).Replace("\", "/")
	[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Write-Host "  Repacked: gareth-chest_variance_mod.zip" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. GIT STAGING, COMMIT & PUSH
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Staging, committing and pushing Part 4 to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Part 4: Implement chest tier variance, class weapon seeding, booby-traps, and update SESSION_PROMPT/README documentation"
git push origin main

Write-Host "`nPart 4 deployment complete! All 4 parts are now deployed." -ForegroundColor Green