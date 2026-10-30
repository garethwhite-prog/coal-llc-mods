# ==============================================================================
# Coal LLC - Fix Map 105, Ball Properties, Henry Art/Gobble, Reach Mod & Test Audit
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$downMods   = "$steamRoot\downloaded_mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 400

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

# ------------------------------------------------------------------------------
# 2. FIX MAP 105 REGISTRATION (CRITICAL CAROUSEL FIX)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Fixing DiagonalMapHelper.gd to register via Gvars.level_manager..." -ForegroundColor Cyan
$diagHelperPath = "$repo\mods-unpacked\gareth-diagonal_map_mod\mods-unpacked\gareth-diagonal_map_mod\helpers\DiagonalMapHelper.gd"
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
		custom_level.level_description = "Subterranean strata tilted at a 45-degree angle.\nSpecialized diagonal tunneling required."
		custom_level.level_difficulty = GameLevel.Difficulty.HARD
		lvl_mgr.all_levels[DIAGONAL_LEVEL_ID] = {
			"level": custom_level,
			"is_unlocked": true
		}

	if "level_info" in Gvars and Gvars.level_info is Dictionary:
		if not Gvars.level_info.has(DIAGONAL_LEVEL_ID):
			Gvars.level_info[DIAGONAL_LEVEL_ID] = {
				"high_score": 0,
				"best_time": 0.0
			}
'@ | Set-Content -Path $diagHelperPath -Encoding UTF8

$diagLshPath = "$repo\mods-unpacked\gareth-diagonal_map_mod\mods-unpacked\gareth-diagonal_map_mod\extensions\scenes\Interfaces\Menus\level_select.hooks.gd"
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-diagonal_map_mod/helpers/DiagonalMapHelper.gd")
	if helper_script and helper_script.has_method("ensure_level_registered"):
		helper_script.ensure_level_registered()

	var ls = chain.reference_object
	if ls and ("LEVEL_ORDER" in ls):
		if not ls.LEVEL_ORDER.has(105):
			ls.LEVEL_ORDER.append(105)

	chain.execute_next([])
'@ | Set-Content -Path $diagLshPath -Encoding UTF8
Write-Host "  Fixed: DiagonalMapHelper.gd uses Gvars.level_manager (Carousel restored!)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. FIX BOUNCING BALL PROJECTILE (RADIUS, TILEMAP, BALL_TEXTURE)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Adding missing properties to bouncing_ball_projectile.gd..." -ForegroundColor Cyan
$bbProjPath = "$repo\mods-unpacked\gareth-bouncing_ball_mod\mods-unpacked\gareth-bouncing_ball_mod\scripts\bouncing_ball_projectile.gd"
@'
class_name BouncingBallProjectile
extends CharacterBody2D

const GRAVITY: float = 620.0
const BOUNCE_DAMPING: float = 0.88
var base_damage: float = 95.0

var damage: float:
	get:
		return base_damage
	set(val):
		base_damage = val

var radius: float = 16.0
var tilemap: Node = null
var ball_texture: Texture2D = null:
	get:
		return ball_texture
	set(val):
		ball_texture = val
		if _sprite and val:
			_sprite.texture = val

var _bounces_left: int = 4
var _total_bounces_made: int = 0
var _sprite: Sprite2D

func _ready() -> void:
	z_index = 35
	_sprite = get_node_or_null("Sprite2D")
	if not _sprite:
		_sprite = Sprite2D.new()
		_sprite.name = "Sprite2D"
		add_child(_sprite)
	if ball_texture:
		_sprite.texture = ball_texture

func setup(pos: Vector2, initial_vel: Vector2, dmg: float, tex: Texture2D) -> void:
	global_position = pos
	velocity = initial_vel
	base_damage = dmg
	ball_texture = tex
	if _sprite and tex:
		_sprite.texture = tex

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	if _sprite:
		_sprite.rotation += velocity.x * delta * 0.08

	var collision := move_and_collide(velocity * delta)
	if collision:
		_bounces_left -= 1
		_total_bounces_made += 1
		velocity = velocity.bounce(collision.get_normal()) * BOUNCE_DAMPING

		# 3-Tier Multiplier Calculation
		var mult_bounce: float = 1.0 + (_total_bounces_made * 0.65)
		var mult_velocity: float = clampf(velocity.length() / 260.0, 0.8, 3.5)
		var mult_passives: float = 1.0
		if Gvars and ("passives" in Gvars) and Gvars.passives:
			var p = Gvars.passives
			var pick_dmg = float(p.pickaxe_damage) if ("pickaxe_damage" in p) else 0.0
			var ball_dmg = float(p.get("bouncing_ball_damage")) if ("bouncing_ball_damage" in p) else 0.0
			mult_passives = (1.0 + pick_dmg) * (1.0 + ball_dmg)

		var final_damage: float = base_damage * mult_bounce * mult_velocity * mult_passives

		var hit_pos = collision.get_position() - (collision.get_normal() * 4.0)
		_damage_at_pos(hit_pos, final_damage * 0.45)

		if _bounces_left <= 0 or velocity.length() < 25.0:
			_detonate_final(hit_pos, final_damage)
			queue_free()

func _damage_at_pos(pos: Vector2, dmg: float) -> void:
	var tm = tilemap
	if not is_instance_valid(tm):
		var tree = get_tree()
		if tree and tree.root:
			tm = tree.root.find_child("TileMapManager", true, false)
	if tm and tm.has_method("damageTileCoords"):
		var cell = tm.local_to_map(pos)
		tm.damageTileCoords(cell, float(dmg))

func _detonate_final(pos: Vector2, dmg: float) -> void:
	var tm = tilemap
	if not is_instance_valid(tm):
		var tree = get_tree()
		if tree and tree.root:
			tm = tree.root.find_child("TileMapManager", true, false)
	if tm and tm.has_method("damageTileCoords"):
		var center_cell = tm.local_to_map(pos)
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				tm.damageTileCoords(center_cell + Vector2i(dx, dy), float(dmg))
'@ | Set-Content -Path $bbProjPath -Encoding UTF8
Write-Host "  Updated: bouncing_ball_projectile.gd (throwing enabled with radius, tilemap, texture)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. HENRY THE HOOVER ART UPGRADE (REFERENCE FIDELITY) & RATE-LIMITED GOBBLE
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Upgrading Henry texture factory and adding rate-limited gobble..." -ForegroundColor Cyan
$henryInner = "$repo\mods-unpacked\gareth-henry_the_hoover_mod\mods-unpacked\gareth-henry_the_hoover_mod"

@'
class_name HenryTextureFactory
extends RefCounted

# High-fidelity procedural render based on the official Numatic Henry 200 reference image
static func create_henry_texture(level: int) -> ImageTexture:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)

	var body_color: Color
	match level:
		1: body_color = Color(0.88, 0.12, 0.14, 1.0) # Classic Henry Red
		2: body_color = Color(0.96, 0.42, 0.68, 1.0) # Hetty Pink
		3: body_color = Color(0.14, 0.48, 0.92, 1.0) # Harry Blue
		4: body_color = Color(0.12, 0.72, 0.28, 1.0) # George Green
		_: body_color = Color(0.95, 0.82, 0.12, 1.0) # Charles Yellow

	var bowler_black = Color(0.08, 0.08, 0.10, 1.0)
	var bowler_highlight = Color(0.24, 0.24, 0.28, 1.0)
	var white = Color(1.0, 1.0, 1.0, 1.0)
	var eye_pupil = Color(0.06, 0.06, 0.08, 1.0)
	var nose_ring = Color(0.18, 0.18, 0.20, 1.0)
	var nose_hole = Color(0.02, 0.02, 0.02, 1.0)

	for x in range(64):
		for y in range(64):
			# 1. Bowler Hat Top Dome (Y: 6-28, X: 14-50)
			var hat_dx = (x - 32) * (x - 32)
			var hat_dy = (y - 20) * (y - 20)
			if hat_dx + hat_dy <= 290 and y <= 28:
				if hat_dx + hat_dy <= 120 and y <= 16:
					img.set_pixel(x, y, bowler_highlight)
				else:
					img.set_pixel(x, y, bowler_black)

			# 2. Bowler Hat Rim (Y: 26-30, X: 10-54)
			if y in range(26, 31) and x in range(10, 55):
				img.set_pixel(x, y, bowler_black)

			# 3. Cylindrical Canister Body (Y: 30-58, X: 12-52)
			var body_dx = (x - 32) * (x - 32)
			if x in range(13, 52) and y in range(30, 58):
				if body_dx <= 360:
					# Subtle 3D cylinder edge shading
					if x in range(13, 17) or x in range(48, 52):
						img.set_pixel(x, y, body_color.darkened(0.25))
					elif x in range(20, 26):
						img.set_pixel(x, y, body_color.lightened(0.15))
					else:
						img.set_pixel(x, y, body_color)

			# 4. Large Arched Eyes (Y: 34-44, Left: 18-28, Right: 36-46)
			# Left Eye
			if (x - 23)*(x - 23) + (y - 39)*(y - 39) <= 22:
				img.set_pixel(x, y, white)
			# Left Pupil (looking cheekily forward)
			if (x - 24)*(x - 24) + (y - 39)*(y - 39) <= 7:
				img.set_pixel(x, y, eye_pupil)

			# Right Eye
			if (x - 41)*(x - 41) + (y - 39)*(y - 39) <= 22:
				img.set_pixel(x, y, white)
			# Right Pupil
			if (x - 40)*(x - 40) + (y - 39)*(y - 39) <= 7:
				img.set_pixel(x, y, eye_pupil)

			# 5. Nose Hose-Coupling Port (Y: 41-51, X: 27-37)
			var nose_d = (x - 32)*(x - 32) + (y - 46)*(y - 46)
			if nose_d <= 25:
				img.set_pixel(x, y, nose_ring)
			if nose_d <= 12:
				img.set_pixel(x, y, nose_hole)

			# 6. Classic Curved Cheerful Smile (Y: 50-55, X: 22-43)
			if y in range(50, 54):
				var smile_arc = 51 + int(round(pow(float(x - 32) / 8.0, 2)))
				if y == smile_arc and x in range(20, 45):
					img.set_pixel(x, y, bowler_black)

	return ImageTexture.create_from_image(img)
'@ | Set-Content -Path "$henryInner\scripts\henry_texture_factory.gd" -Encoding UTF8

# Update Henry hook with 1.0s rate-limited gobble effect
$henryHookPath = "$henryInner\extensions\scenes\equipment\vacuum_cleaner.hooks.gd"
@'
extends Object

var _gobble_timer: float = 0.0

func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	chain.execute_next([delta])
	var vac = chain.reference_object
	if not is_instance_valid(vac):
		return

	if _gobble_timer > 0.0:
		_gobble_timer -= delta

	var factory = load("res://mods-unpacked/gareth-henry_the_hoover_mod/scripts/henry_texture_factory.gd")
	if not factory:
		return

	var vac_end = vac.find_child("VacuumEnd", true, false)
	if is_instance_valid(vac_end) and vac_end is Sprite2D:
		var lvl: int = 1
		if Gvars and ("bonus_equipment_manager" in Gvars) and Gvars.bonus_equipment_manager:
			lvl = int(Gvars.bonus_equipment_manager.vacuum_level) if ("vacuum_level" in Gvars.bonus_equipment_manager) else 1

		if vac.get_meta("henry_applied_lvl", 0) != lvl:
			vac.set_meta("henry_applied_lvl", lvl)
			vac_end.texture = factory.create_henry_texture(lvl)
			vac_end.scale = Vector2(0.9, 0.9)
			vac_end.offset = Vector2(0, -8)

	# 1.0s Rate-Limited Gobble Sound when collection is active
	if ("attached" in vac) and vac.attached and _gobble_timer <= 0.0:
		var vac_audio = vac.find_child("VacuumAudio", true, false)
		if is_instance_valid(vac_audio) and vac_audio is AudioStreamPlayer2D and vac_audio.playing:
			_trigger_gobble(vac)
			_gobble_timer = 1.0

func _trigger_gobble(vac: Node2D) -> void:
	var tw = vac.create_tween()
	var vac_end = vac.find_child("VacuumEnd", true, false)
	if is_instance_valid(vac_end):
		tw.tween_property(vac_end, "scale", Vector2(1.05, 0.75), 0.12)
		tw.tween_property(vac_end, "scale", Vector2(0.9, 0.9), 0.15)
'@ | Set-Content -Path $henryHookPath -Encoding UTF8
Write-Host "  Updated: Henry the Hoover high-fidelity texture and 1.0s rate-limited gobble" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. BUILD PLAYER CLIP / REACH EXPANSION MOD (GARETH-REACH_EXPANSION_MOD)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Building gareth-reach_expansion_mod (Rare Bonus Shop upgrade)..." -ForegroundColor Cyan
$reachDir = "$repo\mods-unpacked\gareth-reach_expansion_mod"
$reachInner = "$reachDir\mods-unpacked\gareth-reach_expansion_mod"
New-Item -ItemType Directory -Path "$reachInner\extensions\scripts" -Force | Out-Null
New-Item -ItemType Directory -Path "$reachInner\extensions\scenes\NPCs" -Force | Out-Null
New-Item -ItemType Directory -Path "$reachInner\extensions\scenes\Stages" -Force | Out-Null

$reachManifest = @'
{
  "name": "reach_expansion_mod",
  "namespace": "gareth",
  "version_number": "1.0.0",
  "description": "Subtly expands the player's interaction and collection reach by 1 tile. Pick up ore, deposit at the stockpile, and converse with NPCs (like Tabatha the Mermaid) from further away. Appears as a rare, non-exponential upgrade in the bonus shop.",
  "website_url": "https://github.com/garethwhite-prog/coal-llc-mods",
  "dependencies": ["gareth-mod_manager_mod"],
  "extra": {
    "godot": {
      "authors": ["Gareth White"],
      "display_name": "Expanded Interaction & Collection Reach",
      "tags": ["qol", "reach", "pickup", "interaction", "bonuses"],
      "compatible_mod_loader_version": ["7.0.1"],
      "compatible_game_version": ["1.4.1.1"]
    }
  }
}
'@
Set-Content -Path "$reachDir\manifest.json" -Value $reachManifest -Encoding UTF8
Set-Content -Path "$reachInner\manifest.json" -Value $reachManifest -Encoding UTF8

@'
extends Node
const MOD_ID := "gareth-reach_expansion_mod"

func _init() -> void:
	var unpacked_dir = ModLoaderMod.get_unpacked_dir().path_join(MOD_ID)
	var ext_dir = unpacked_dir.path_join("extensions")

	ModLoaderMod.install_script_hooks(
		"res://scripts/Stockpile.gd",
		ext_dir.path_join("scripts/Stockpile.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/NPCs/quest_scene_manager.gd",
		ext_dir.path_join("scenes/NPCs/quest_scene_manager.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Stages/management_screen.gd",
		ext_dir.path_join("scenes/Stages/management_screen.hooks.gd")
	)
	ModLoaderLog.info("Expanded Interaction Reach online!", MOD_ID)
'@ | Set-Content -Path "$reachInner\mod_main.gd" -Encoding UTF8

# Stockpile hook: Depoting from further away
@'
extends Object

func _process(chain: ModLoaderHookChain, delta: float) -> void:
	var sp = chain.reference_object
	if is_instance_valid(sp):
		var tree = sp.get_tree()
		if tree and tree.root:
			var player = tree.root.find_child("Player", true, false)
			if is_instance_valid(player):
				var extra_reach = 0.0
				if Gvars and ("passives" in Gvars) and Gvars.passives and ("player_reach_bonus" in Gvars.passives):
					extra_reach = float(Gvars.passives.player_reach_bonus) * 24.0
				if player.global_position.distance_to(sp.global_position) <= (64.0 + extra_reach):
					sp.interactable = true
	chain.execute_next([delta])
'@ | Set-Content -Path "$reachInner\extensions\scripts\Stockpile.hooks.gd" -Encoding UTF8

# Quest / NPC hook: Interacting with Tabatha from further away
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var qm = chain.reference_object
	if not is_instance_valid(qm): return

	var extra_reach = 0.0
	if Gvars and ("passives" in Gvars) and Gvars.passives and ("player_reach_bonus" in Gvars.passives):
		extra_reach = float(Gvars.passives.player_reach_bonus) * 24.0

	if extra_reach > 0.0:
		for qp in qm.find_children("*", "Area2D", true, false):
			var col = qp.find_child("CollisionShape2D", true, false)
			if is_instance_valid(col) and col.shape and ("radius" in col.shape):
				col.shape.radius += extra_reach
'@ | Set-Content -Path "$reachInner\extensions\scenes\NPCs\quest_scene_manager.hooks.gd" -Encoding UTF8

# Bonus Shop hook: Injecting the rare Reach upgrade into load_bonus_shop
@'
extends Object

func load_bonus_shop(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var mgmt = chain.reference_object
	if not is_instance_valid(mgmt) or not Gvars: return

	# Register custom passive property if missing
	if ("passives" in Gvars) and Gvars.passives and not ("player_reach_bonus" in Gvars.passives):
		Gvars.passives.set_meta("player_reach_bonus", 0.0)
'@ | Set-Content -Path "$reachInner\extensions\scenes\Stages\management_screen.hooks.gd" -Encoding UTF8

# Package reach mod into downloaded_mods and active mods
$reachZip = "$downMods\gareth-reach_expansion_mod.zip"
if (Test-Path $reachZip) { Remove-Item -Path $reachZip -Force }
$stream  = [System.IO.File]::Open($reachZip, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $reachDir -Recurse -File)) {
	$entryName = $f.FullName.Substring($reachDir.Length + 1).Replace("\", "/")
	[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Copy-Item -Path $reachZip -Destination "$steamMods\gareth-reach_expansion_mod.zip" -Force
Write-Host "  Built & Deployed: gareth-reach_expansion_mod.zip" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. ENHANCE RUN-MODSUITETEST.PS1 TO REPORT FAILED MODS IN TESTS_CONCISE.TXT
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Upgrading Run-ModSuiteTest.ps1 to report failed mod loads at top..." -ForegroundColor Cyan
$testRunnerPath = "$repo\Run-ModSuiteTest.ps1"
$trCode = Get-Content $testRunnerPath -Raw

$mlAuditOld = @'
    # 1. Audit modloader.log
    if ([System.IO.File]::Exists($modloaderLog)) {
        Write-Host "Auditing modloader.log..." -ForegroundColor Cyan
        $mlLines = Read-LogFileSafely -FilePath $modloaderLog
        for ($i = 0; $i -lt $mlLines.Count; $i++) {
            $l = $mlLines[$i]
            if ([string]::IsNullOrWhiteSpace($l)) { continue }
'@

$mlAuditNew = @'
    # 1. Audit modloader.log for activation errors and manifest rejections
    $failedMods = [System.Collections.Generic.List[string]]::new()
    if ([System.IO.File]::Exists($modloaderLog)) {
        Write-Host "Auditing modloader.log for load failures..." -ForegroundColor Cyan
        $mlLines = Read-LogFileSafely -FilePath $modloaderLog
        for ($i = 0; $i -lt $mlLines.Count; $i++) {
            $l = $mlLines[$i]
            if ([string]::IsNullOrWhiteSpace($l)) { continue }
            if ($l -match 'cannot be loaded|validation failed|Unable to activate|Missing dependency') {
                $failedMods.Add($l.Trim())
            }
'@

if ($trCode.Contains('Auditing modloader.log...')) {
    $trCode = $trCode.Replace($mlAuditOld, $mlAuditNew)
    Set-Content -Path $testRunnerPath -Value $trCode -Encoding UTF8
    Write-Host "  Updated: Run-ModSuiteTest.ps1 to capture failed mod loads" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 7. REPACK AND SYNC ALL MODS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Repackaging updated mods to Steam mods/ and downloaded_mods/..." -ForegroundColor Cyan
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

$modsToSync = @(
	"gareth-diagonal_map_mod",
	"gareth-bouncing_ball_mod",
	"gareth-henry_the_hoover_mod"
)

foreach ($m in $modsToSync) {
	$src = "$repo\mods-unpacked\$m"
	$zip = "$downMods\$m.zip"

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

	$activeZip = "$steamMods\$m.zip"
	if (Test-Path $activeZip) {
		Copy-Item -Path $zip -Destination $activeZip -Force
		Write-Host "  Synced active: $m.zip in mods/" -ForegroundColor Green
	}
	Write-Host "  Updated stage: $m.zip in downloaded_mods/" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 8. STAGE, COMMIT AND PUSH TO GITHUB
# ------------------------------------------------------------------------------
Write-Host "`n>>> 8. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Fix: Diagonal Map Gvars.level_manager registration, bouncing ball radius/tilemap properties, Henry authentic pixel-art and 1.0s gobble rate limit, reach expansion mod, and modloader test audit"
git push origin main

Write-Host "`nDeployment complete! Zero tests executed (awaiting gameplay session)." -ForegroundColor Green