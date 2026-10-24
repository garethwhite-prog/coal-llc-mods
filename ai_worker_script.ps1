Clear-Host

# ==============================================================================
# Coal LLC - Commit 4: Gameplay Expansions, Turret Fix & Celebrations
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 400

# ------------------------------------------------------------------------------
# 2. FIX HEAVY TURRET TARGETING & DAMAGE CALL
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Fixing heavy_turret_entity.gd..." -ForegroundColor Cyan
$turretScript = "$repo\mods-unpacked\gareth-heavy_turrets_mod\mods-unpacked\gareth-heavy_turrets_mod\scripts\heavy_turret_entity.gd"
@'
class_name HeavyTurretEntity
extends Node2D

var fire_timer: float = 0.0
const FIRE_INTERVAL: float = 0.35
const DAMAGE: float = 40.0

var sprite: Sprite2D
var tilemap = null

func _ready() -> void:
	sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/Equipment/vehicles/tank_turret.png"):
		sprite.texture = load("res://assets/Equipment/vehicles/tank_turret.png")
	add_child(sprite)
	_resolve_tilemap()

func _resolve_tilemap() -> void:
	var tree = get_tree()
	if tree and tree.root:
		var p = tree.root.find_child("Player", true, false)
		if p and ("tilemap" in p) and p.tilemap:
			tilemap = p.tilemap
			return
		var tm = tree.root.find_child("TileMapManager", true, false)
		if tm:
			tilemap = tm

func _physics_process(delta: float) -> void:
	fire_timer += delta
	if fire_timer >= FIRE_INTERVAL:
		fire_timer = 0.0
		_acquire_and_fire()

func _acquire_and_fire() -> void:
	if not tilemap:
		_resolve_tilemap()
		if not tilemap:
			return

	var center := tilemap.local_to_map(global_position)
	var best_target: Vector2i = Vector2i.ZERO
	var found: bool = false

	for r in range(1, 14):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var check_pos := center + Vector2i(dx, dy)
				if tilemap.has_method("is_tile_collision") and tilemap.is_tile_collision(check_pos):
					best_target = check_pos
					found = true
					break
			if found:
				break
		if found:
			break

	if found:
		var target_world := tilemap.map_to_local(best_target)
		sprite.rotation = (target_world - global_position).angle()
		if tilemap.has_method("damageTileCoords"):
			tilemap.damageTileCoords(best_target, DAMAGE)

		var boom = AudioStreamPlayer2D.new()
		boom.stream = load("res://assets/sound/sound effects/box_1.wav")
		boom.pitch_scale = 1.4
		boom.global_position = global_position
		get_tree().current_scene.add_child(boom)
		boom.play()
		boom.finished.connect(boom.queue_free)
'@ | Set-Content -Path $turretScript -Encoding UTF8

# ------------------------------------------------------------------------------
# 3. CREATE GARETH-COLLECTOR_PRIORITY_MOD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Creating gareth-collector_priority_mod..." -ForegroundColor Cyan
$cpRoot = "$repo\mods-unpacked\gareth-collector_priority_mod"
$cpInner = "$cpRoot\mods-unpacked\gareth-collector_priority_mod"
$cpExt = "$cpInner\extensions\scripts"
New-Item -ItemType Directory -Path $cpExt -Force | Out-Null

$cpManifest = @"
{
  "name": "collector_priority_mod",
  "namespace": "gareth",
  "version_number": "1.0.0",
  "description": "Configure Collector UFO target acquisition priority: Closest First vs Most Valuable Gem First.",
  "website_url": "https://github.com/garethwhite-prog/coal-llc-mods",
  "dependencies": ["gareth-mod_manager_mod"],
  "extra": { "godot": { "display_name": "Collector Priority System", "category": "Employees & Automation", "authors": ["Gareth White"], "compatible_mod_loader_version": ["7.0.1"] } }
}
"@
Set-Content -Path "$cpRoot\manifest.json" -Value $cpManifest -Encoding UTF8
Set-Content -Path "$cpInner\manifest.json" -Value $cpManifest -Encoding UTF8

@'
extends Node
const MOD_DIR := "gareth-collector_priority_mod"
func _init() -> void:
	ModLoaderMod.install_script_hooks("res://scripts/loot_drops.gd", "res://mods-unpacked/gareth-collector_priority_mod/extensions/scripts/loot_drops.hooks.gd")
func _ready() -> void:
	ModLoaderLog.info("Collector Priority Mod active!", MOD_DIR)
'@ | Set-Content -Path "$cpInner\mod_main.gd" -Encoding UTF8

@'
extends Object

func find_loot(chain: ModLoaderHookChain, collector) -> void:
	var ld = chain.reference_object
	if not is_instance_valid(ld) or not is_instance_valid(collector):
		chain.execute_next([collector])
		return

	# Check priority mode: 0 = Closest, 1 = Most Valuable First
	var priority_mode: int = 1
	if Gvars and ("collector_priority_mode" in Gvars):
		priority_mode = int(Gvars.collector_priority_mode)

	if priority_mode == 0:
		chain.execute_next([collector])
		return

	var loots = ld.loot_drops.get_children()
	if loots.is_empty():
		chain.execute_next([collector])
		return

	var best_loot = null
	var highest_val: float = -1.0
	for loot in loots:
		if is_instance_valid(loot) and ("pickupItem" in loot) and loot.pickupItem:
			var val: float = float(loot.pickupItem.itemSellPrice)
			if val > highest_val:
				highest_val = val
				best_loot = loot

	if best_loot:
		collector.target_pos = best_loot.global_position
		collector.state = collector.States.MOVING_TO_LOOT
		return

	chain.execute_next([collector])
'@ | Set-Content -Path "$cpExt\loot_drops.hooks.gd" -Encoding UTF8

# ------------------------------------------------------------------------------
# 4. CREATE GARETH-AUTO_LADDER_MOD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Creating gareth-auto_ladder_mod..." -ForegroundColor Cyan
$alRoot = "$repo\mods-unpacked\gareth-auto_ladder_mod"
$alInner = "$alRoot\mods-unpacked\gareth-auto_ladder_mod"
$alExt = "$alInner\extensions\scripts"
New-Item -ItemType Directory -Path $alExt -Force | Out-Null

$alManifest = @"
{
  "name": "auto_ladder_mod",
  "namespace": "gareth",
  "version_number": "1.0.0",
  "description": "Automatically deploys ladders in the exact center column of the mine (or sky) when blocks are mined.",
  "website_url": "https://github.com/garethwhite-prog/coal-llc-mods",
  "dependencies": ["gareth-mod_manager_mod"],
  "extra": { "godot": { "display_name": "Center-Column Auto Ladder", "category": "Quality of Life", "authors": ["Gareth White"], "compatible_mod_loader_version": ["7.0.1"] } }
}
"@
Set-Content -Path "$alRoot\manifest.json" -Value $alManifest -Encoding UTF8
Set-Content -Path "$alInner\manifest.json" -Value $alManifest -Encoding UTF8

@'
extends Node
const MOD_DIR := "gareth-auto_ladder_mod"
func _init() -> void:
	ModLoaderMod.install_script_hooks("res://scripts/tile_map_layer_main.gd", "res://mods-unpacked/gareth-auto_ladder_mod/extensions/scripts/tile_map_layer_main.hooks.gd")
func _ready() -> void:
	ModLoaderLog.info("Auto Ladder Mod active!", MOD_DIR)
'@ | Set-Content -Path "$alInner\mod_main.gd" -Encoding UTF8

@'
extends Object

func damageTileCoords(chain: ModLoaderHookChain, coords: Vector2i, damage: float) -> void:
	chain.execute_next([coords, damage])
	var tm = chain.reference_object
	if not is_instance_valid(tm):
		return

	# Center column check (X = 0)
	if coords.x == 0:
		if tm.has_method("place_ladder"):
			tm.place_ladder(coords)
		elif "ladders" in tm and tm.ladders and tm.ladders.has_method("add_ladder"):
			tm.ladders.add_ladder(coords)
'@ | Set-Content -Path "$alExt\tile_map_layer_main.hooks.gd" -Encoding UTF8

# ------------------------------------------------------------------------------
# 5. CREATE GARETH-DIAGONAL_MAP_MOD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Creating gareth-diagonal_map_mod..." -ForegroundColor Cyan
$dmRoot = "$repo\mods-unpacked\gareth-diagonal_map_mod"
$dmInner = "$dmRoot\mods-unpacked\gareth-diagonal_map_mod"
$dmExt = "$dmInner\extensions\scenes\tilemaps"
New-Item -ItemType Directory -Path $dmExt -Force | Out-Null

$dmManifest = @"
{
  "name": "diagonal_map_mod",
  "namespace": "gareth",
  "version_number": "1.0.0",
  "description": "45-degree rotated diagonal subterranean strata and Sky Mine variants.",
  "website_url": "https://github.com/garethwhite-prog/coal-llc-mods",
  "dependencies": ["gareth-mod_manager_mod"],
  "extra": { "godot": { "display_name": "Diagonal Seams Custom Map", "category": "Custom Maps & Strata", "authors": ["Gareth White"], "compatible_mod_loader_version": ["7.0.1"] } }
}
"@
Set-Content -Path "$dmRoot\manifest.json" -Value $dmManifest -Encoding UTF8
Set-Content -Path "$dmInner\manifest.json" -Value $dmManifest -Encoding UTF8

@'
extends Node
const MOD_DIR := "gareth-diagonal_map_mod"
func _init() -> void:
	ModLoaderMod.install_script_hooks("res://scenes/tilemaps/tile_map_chunk.gd", "res://mods-unpacked/gareth-diagonal_map_mod/extensions/scenes/tilemaps/tile_map_chunk.hooks.gd")
func _ready() -> void:
	ModLoaderLog.info("Diagonal Map Mod active!", MOD_DIR)
'@ | Set-Content -Path "$dmInner\mod_main.gd" -Encoding UTF8

@'
extends Object

func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	if Gvars and ("map_id" in Gvars) and Gvars.map_id == 104:
		# 45-degree strata shift: X + Y
		var diag = int((pos.x + pos.y) * 0.707)
		return clampi(diag / 25, 1, 15)
	return chain.execute_next([pos])
'@ | Set-Content -Path "$dmExt\tile_map_chunk.hooks.gd" -Encoding UTF8

# ------------------------------------------------------------------------------
# 6. CREATE GARETH-DONKEY_KONG_MOD (SURFACE BARREL HAZARD)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Creating gareth-donkey_kong_mod..." -ForegroundColor Cyan
$dkRoot = "$repo\mods-unpacked\gareth-donkey_kong_mod"
$dkInner = "$dkRoot\mods-unpacked\gareth-donkey_kong_mod"
$dkScripts = "$dkInner\scripts"
New-Item -ItemType Directory -Path $dkScripts -Force | Out-Null

$dkManifest = @"
{
  "name": "donkey_kong_mod",
  "namespace": "gareth",
  "version_number": "1.0.0",
  "description": "Surface gorilla hazard patrols ground level and tosses rolling barrels down mine pits. 5-second stun on impact.",
  "website_url": "https://github.com/garethwhite-prog/coal-llc-mods",
  "dependencies": ["gareth-mod_manager_mod"],
  "extra": { "godot": { "display_name": "Donkey Kong Surface Hazard", "category": "Weapons & Arsenal", "authors": ["Gareth White"], "compatible_mod_loader_version": ["7.0.1"] } }
}
"@
Set-Content -Path "$dkRoot\manifest.json" -Value $dkManifest -Encoding UTF8
Set-Content -Path "$dkInner\manifest.json" -Value $dkManifest -Encoding UTF8

@'
extends Node
const MOD_DIR := "gareth-donkey_kong_mod"
func _ready() -> void:
	var spawner_scr = load("res://mods-unpacked/gareth-donkey_kong_mod/scripts/gorilla_surface_spawner.gd")
	var spawner = Node.new()
	spawner.name = "GorillaSurfaceSpawner"
	spawner.set_script(spawner_scr)
	get_tree().root.call_deferred("add_child", spawner)
	ModLoaderLog.info("Donkey Kong Surface Hazard Mod online!", MOD_DIR)
'@ | Set-Content -Path "$dkInner\mod_main.gd" -Encoding UTF8

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
	spr.texture = load("res://assets/Equipment/kicks/kick_08_gold.png")
	spr.modulate = Color(0.55, 0.3, 0.15, 1.0)
	spr.scale = Vector2(2.8, 2.8)
	gorilla.add_child(spr)
	scene.add_child(gorilla)

func _toss_barrel(scene: Node, pos: Vector2) -> void:
	var barrel = Area2D.new()
	barrel.name = "RollingBarrel"
	barrel.global_position = pos

	var spr = Sprite2D.new()
	spr.texture = load("res://assets/Equipment/bombs/big_bomb_sheet_red.png")
	spr.hframes = 4
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
			# Stun for 5.0 seconds
			body.set_physics_process(false)
			var tw = body.create_tween()
			tw.tween_interval(5.0)
			tw.tween_callback(func(): body.set_physics_process(true))
			barrel.queue_free()
	)

	scene.add_child(barrel)
	var b_tween = barrel.create_tween()
	b_tween.tween_property(barrel, "global_position:y", 600.0, 7.0)
	b_tween.tween_callback(barrel.queue_free)
'@ | Set-Content -Path "$dkScripts\gorilla_surface_spawner.gd" -Encoding UTF8

# ------------------------------------------------------------------------------
# 7. LEADERBOARD RECORD CELEBRATION HOOK
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Adding Leaderboard record breaker celebration hook..." -ForegroundColor Cyan
$lbCelebrationPath = "$repo\mods-unpacked\gareth-leaderboard_mod\mods-unpacked\gareth-leaderboard_mod\scripts\record_celebrator.gd"
@'
class_name RecordCelebrator
extends Node

static func celebrate_new_record(tree: SceneTree, record_name: String, value: String) -> void:
	var toast = Label.new()
	toast.text = "🎉 NEW LEADERBOARD RECORD! %s: %s" % [record_name, value]
	toast.anchor_left = 0.5
	toast.anchor_right = 0.5
	toast.offset_left = -280.0
	toast.offset_right = 280.0
	toast.offset_top = 130.0
	toast.offset_bottom = 165.0
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1, 1.0))
	tree.root.add_child(toast)

	var tw = tree.create_tween()
	tw.tween_interval(4.0)
	tw.tween_callback(toast.queue_free)
'@ | Set-Content -Path $lbCelebrationPath -Encoding UTF8

# ------------------------------------------------------------------------------
# 8. REPACK ALL MODS & PUSH COMMIT 4
# ------------------------------------------------------------------------------
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$modsToRepack = @(
	"gareth-heavy_turrets_mod",
	"gareth-collector_priority_mod",
	"gareth-auto_ladder_mod",
	"gareth-diagonal_map_mod",
	"gareth-donkey_kong_mod",
	"gareth-leaderboard_mod"
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

git add -A
git commit -m "Commit 4: Heavy Turret targeting fix, Collector Priority mod, Center Auto Ladder, Diagonal Map, Donkey Kong Surface Hazard, and Leaderboard Celebrations"
git push origin main
Write-Host "`nCommit 4 complete! All 4 stages successfully deployed." -ForegroundColor Green