$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. Expanding Knowledge Base & Documentation ---"
$knownRegressionsPath = Join-Path $repoRoot "docs\KNOWN_REGRESSIONS_AND_MISTAKES.md"
$knownRegressions = @"
# Known Regressions, Mistakes & Safeguards

This dossier tracks identified defects, the underlying engine root-cause, and regression assertions enforced by automated test runners.

## 1. ModRegistry Interface Contract
- **Symptom**: 5,000+ physics errors (`Nonexistent function 'is_mod_active_for_run' in base 'GDScript'`).
- **Root Cause**: Omitting `static func is_mod_active_for_run(mod_key: String) -> bool` from `mod_registry.gd`.

## 2. Block Hit / Damage Desync
- **Symptom**: Blocks appear to take damage and instantly "heal" on the subsequent hit.
- **Root Cause**: Physics frame termination due to unhandled GDScript exceptions in player or chunk hooks.

## 3. In-Game Stage Gating
- **Symptom**: HUD widgets (Speed, Amazon) either permanently invisible or overlapping Main Menu.
- **Root Cause**: Assuming `Gconsts.Stages._IN_GAME` exists (vanilla enum uses `_MINE_REGION` = 2).

## 4. 0g Shop Item Division by Zero
- **Symptom**: Crash on purchase.
- **Root Cause**: Unhandled 0 item prices. Guarded by `itemBuyPrice = max(1.0, val)`.

## 5. Engine Arity Limits (Object.get)
- **Symptom**: Fatal parse error `Expected at most 1 but received 2` for `get()`.
- **Root Cause**: Passing a default value to `Object.get()`. `Dictionary.get()` takes 2, `Object.get()` strictly takes 1.

## 6. Scene Tree Locks (add_child)
- **Symptom**: `Parent node is busy setting up children, add_child() failed.`
- **Root Cause**: Using `add_child()` directly inside a `_ready()` hook while the node is still mounting. 
- **Safeguard**: Always use `call_deferred("add_child", node)` in setup phases.

## 7. Asynchronous Coroutines (change_stage)
- **Symptom**: Camera zooms out infinitely, player dumped out of viewport.
- **Root Cause**: Calling `chain.execute_next()` without `await` on a vanilla function that uses coroutines.
- **Safeguard**: Any hook modifying `Game.gd:change_stage` must use `await chain.execute_next(...)`.

## 8. ModLoader File Locks
- **Symptom**: ModLoader aborts zip generation, silently disabling ALL mods.
- **Root Cause**: Godot background processes locking `mod-hooks.zip` or syntax parse errors blocking compilation.
"@
$knownRegressions | Set-Content -Path $knownRegressionsPath -Encoding UTF8

$parallelStoriesPath = Join-Path $repoRoot "docs\user_stories\US-EXT-01_Historical_Mods.md"
$parallelStories = @"
# US-EXT-01: Historical Core Systems

**1. Bouncing Ball Ordnance:**
3-Tier damage scaling based on rebound momentum, bounce stacks, and global pickaxe synergies.

**2. Amazon Delivery Integration:**
Parachute supply crates spawning at Z-index 60 triggered via hotkey [B], bypassing double-charges on stack limits.

**3. Mod Store & Multisave Data Gating:**
Category filtering and Save Slot mounting that actively syncs `downloaded_mods/` to `mods/` at boot.
"@
$parallelStories | Set-Content -Path $parallelStoriesPath -Encoding UTF8

$parallelDiscoveryPath = Join-Path $repoRoot "docs\discovery\PARALLEL_DISCOVERY.md"
$parallelDiscovery = @"
# Global Architecture Ledger

- **Total Active Mods**: 64 modules identified.
- **UI Canvas Intercepts**: MainMenu, level_select, settings_2.
- **Core Loop Intercepts**: TileMapManager, Game.gd, Player2.gd.
- **Outstanding Sync Points**: Ensure all custom class hooks safely validate `is_instance_valid(target)`.
"@
$parallelDiscovery | Set-Content -Path $parallelDiscoveryPath -Encoding UTF8

Write-Output "--- 2. Fixing Drone Workforce & Thomas Train Scene Tree Locks ---"
$droneMinerPath = Join-Path $repoRoot "mods-unpacked\gareth-drone_workforce_mod\mods-unpacked\gareth-drone_workforce_mod\extensions\scenes\AutoMiners\employee_miner_2.hooks.gd"
$droneMiner = @"
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var miner = chain.reference_object
	if not is_instance_valid(miner): return

	var factory = load("res://mods-unpacked/gareth-drone_workforce_mod/scripts/drone_texture_factory.gd")
	if not factory: return

	for part in ["Head", "Torso", "Legs", "Tool"]:
		var node = miner.find_child(part, true, false)
		if is_instance_valid(node) and node is CanvasItem:
			node.visible = false

	var drone_spr = miner.get_node_or_null("MinerDroneSprite")
	if not drone_spr:
		drone_spr = Sprite2D.new()
		drone_spr.name = "MinerDroneSprite"
		drone_spr.texture = factory.create_miner_drone_texture()
		drone_spr.scale = Vector2(1.5, 1.5)
		miner.call_deferred("add_child", drone_spr)
"@
$droneMiner | Set-Content -Path $droneMinerPath -Encoding UTF8

$droneUfoPath = Join-Path $repoRoot "mods-unpacked\gareth-drone_workforce_mod\mods-unpacked\gareth-drone_workforce_mod\extensions\scripts\LootCollectorUFO.hooks.gd"
$droneUfo = @"
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var ufo = chain.reference_object
	if not is_instance_valid(ufo): return

	var factory = load("res://mods-unpacked/gareth-drone_workforce_mod/scripts/drone_texture_factory.gd")
	if not factory: return

	var models = ufo.find_child("Models", true, false)
	if is_instance_valid(models) and models is CanvasItem:
		models.visible = false

	var cargo_spr = ufo.get_node_or_null("CargoDroneSprite")
	if not cargo_spr:
		cargo_spr = Sprite2D.new()
		cargo_spr.name = "CargoDroneSprite"
		cargo_spr.texture = factory.create_cargo_drone_texture()
		cargo_spr.scale = Vector2(1.5, 1.5)
		ufo.call_deferred("add_child", cargo_spr)
"@
$droneUfo | Set-Content -Path $droneUfoPath -Encoding UTF8

$thomasTrainPath = Join-Path $repoRoot "mods-unpacked\gareth-thomas_tank_engine_mod\mods-unpacked\gareth-thomas_tank_engine_mod\scripts\thomas_train_manager.gd"
$thomasTrain = @"
class_name ThomasTrainManager
extends Node2D

var left_stop: float = 64.0
var right_stop: float = 880.0
var speed: float = 140.0
var direction: float = 1.0

var loco_tier: int = 1
var wagon_count: int = 2
var wagon_capacity: float = 150.0
var current_haul: float = 0.0

var loco_sprite: Sprite2D
var wagons: Array[Sprite2D] = []

func _ready() -> void:
	z_index = 20
	position = Vector2(left_stop, 24.0)

	loco_sprite = Sprite2D.new()
	loco_sprite.scale = Vector2(1.8, 1.8)
	call_deferred("add_child", loco_sprite)
"@
$thomasTrain | Set-Content -Path $thomasTrainPath -Encoding UTF8

Write-Output "--- 3. Implementing Henry Hoover High-Fidelity Visuals & Audio Lock ---"
$henryFactoryPath = Join-Path $repoRoot "mods-unpacked\gareth-henry_the_hoover_mod\mods-unpacked\gareth-henry_the_hoover_mod\helpers\henry_texture_factory.gd"
$henryFactory = @"
class_name HenryTextureFactory
extends RefCounted

static func apply_henry_skin(sprite: Sprite2D, tier: int) -> void:
	if not is_instance_valid(sprite): return
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var body = Color(0.88, 0.12, 0.14, 1.0)
	match tier:
		2: body = Color(0.96, 0.42, 0.68, 1.0) # Hetty Pink
		3: body = Color(0.14, 0.48, 0.92, 1.0) # Harry Blue
		4: body = Color(0.12, 0.72, 0.28, 1.0) # George Green
		5: body = Color(0.95, 0.82, 0.12, 1.0) # Charles Yellow
	
	var black = Color(0.1, 0.1, 0.1, 1.0)
	var white = Color(1.0, 1.0, 1.0, 1.0)
	
	for x in range(8, 24):
		for y in range(4, 12):
			img.set_pixel(x, y, black)
	for x in range(4, 28):
		img.set_pixel(x, 12, black)
		
	for x in range(6, 26):
		for y in range(13, 30):
			img.set_pixel(x, y, body)
			
	for x in range(10, 14):
		for y in range(16, 20):
			img.set_pixel(x, y, white)
			if x > 11 and y > 17: img.set_pixel(x, y, black)
	for x in range(18, 22):
		for y in range(16, 20):
			img.set_pixel(x, y, white)
			if x > 19 and y > 17: img.set_pixel(x, y, black)
			
	for x in range(14, 18):
		for y in range(20, 24):
			img.set_pixel(x, y, black)
			
	for x in range(10, 22):
		var sy = 26 + int(abs(x - 15.5) * 0.3)
		if sy < 32:
			img.set_pixel(x, sy, black)
			
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.offset = Vector2(0, -16)
"@
$henryFactory | Set-Content -Path $henryFactoryPath -Encoding UTF8

$vacHookPath = Join-Path $repoRoot "mods-unpacked\gareth-henry_the_hoover_mod\mods-unpacked\gareth-henry_the_hoover_mod\extensions\scenes\equipment\vacuum_cleaner.hooks.gd"
$vacHook = @"
extends Object

func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	var vac = chain.reference_object
	if is_instance_valid(vac):
		if not vac.has_meta("henry_initialized"):
			vac.set_meta("henry_initialized", true)
			vac.set_meta("gobble_cooldown", 0.0)
			
			var lvl: int = 1
			if Gvars and ("bonus_equipment_manager" in Gvars) and Gvars.bonus_equipment_manager:
				if "vacuum_level" in Gvars.bonus_equipment_manager:
					lvl = int(Gvars.bonus_equipment_manager.vacuum_level)
					
			var sprite = vac.get_node_or_null("Sprite2D")
			if sprite:
				var factory = load("res://mods-unpacked/gareth-henry_the_hoover_mod/helpers/henry_texture_factory.gd")
				if factory and factory.has_method("apply_henry_skin"):
					factory.apply_henry_skin(sprite, lvl)

		var cd = float(vac.get_meta("gobble_cooldown", 0.0))
		if cd > 0.0:
			vac.set_meta("gobble_cooldown", cd - delta)
			
		var audio = vac.get_node_or_null("AudioStreamPlayer2D")
		if is_instance_valid(audio) and audio.playing:
			if cd > 0.0:
				audio.volume_db = -80.0
			else:
				audio.volume_db = 0.0
				vac.set_meta("gobble_cooldown", 1.0)

	chain.execute_next([delta])
"@
$vacHook | Set-Content -Path $vacHookPath -Encoding UTF8

Write-Output "--- 4. Repacking Mod Files ---"
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force }

$targetMods = @("gareth-drone_workforce_mod", "gareth-thomas_tank_engine_mod", "gareth-henry_the_hoover_mod")
Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($mod in $targetMods) {
    $srcDir = Join-Path $repoRoot "mods-unpacked\$mod"
    $downZip = Join-Path $downMods "$mod.zip"
    $steamZip = Join-Path $steamMods "$mod.zip"
    
    if (Test-Path $downZip) { Remove-Item $downZip -Force }
    $archive = [System.IO.Compression.ZipFile]::Open($downZip, [System.IO.Compression.ZipArchiveMode]::Create)
    $files = Get-ChildItem -Path $srcDir -Recurse -File
    foreach ($file in $files) {
        $entryName = $file.FullName.Substring($srcDir.Length + 1).Replace("\", "/")
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $entryName)
    }
    $archive.Dispose()
    
    if (Test-Path $steamZip) { Copy-Item -Path $downZip -Destination $steamZip -Force }
    Write-Output "Deployed $mod.zip"
}

Write-Output "--- Committing to Git ---"
git add -A
git commit -m "Docs & Fixes: Scaffold agile user stories, update Knowledge Base regressions, migrate drone and train instantiations to call_deferred, and inject Numatic Henry 200 pixel art."
git push origin main
Write-Output "Sprints Deployed Successfully!"