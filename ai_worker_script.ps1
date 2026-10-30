# ==============================================================================
# Coal LLC - Ball Damage Alias, Diagonal Map Stage Hook, Amazon Passives & Canvas Card
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$downMods   = "$steamRoot\downloaded_mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 400

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

# ------------------------------------------------------------------------------
# 2. RESTORE 'damage' PROPERTY ALIAS IN BOUNCING_BALL_PROJECTILE.GD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Adding damage property alias to bouncing_ball_projectile.gd..." -ForegroundColor Cyan
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

var _bounces_left: int = 4
var _total_bounces_made: int = 0
var _sprite: Sprite2D

func _ready() -> void:
	z_index = 35
	_sprite = get_node_or_null("Sprite2D")

func setup(pos: Vector2, initial_vel: Vector2, dmg: float, tex: Texture2D) -> void:
	global_position = pos
	velocity = initial_vel
	base_damage = dmg
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

		# 3-Tier Multiplier Calculation:
		# Multiplier 1: Rebound Kinetic Energy Stack (Consecutive Bounces)
		var mult_bounce: float = 1.0 + (_total_bounces_made * 0.65)

		# Multiplier 2: Momentum / Velocity Impulse (V relative to launch speed)
		var mult_velocity: float = clampf(velocity.length() / 260.0, 0.8, 3.5)

		# Multiplier 3: Global Player Passives Synergy
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
	var tree = get_tree()
	if not tree or not tree.root: return
	var tm = tree.root.find_child("TileMapManager", true, false)
	if tm and tm.has_method("damageTileCoords"):
		var cell = tm.local_to_map(pos)
		tm.damageTileCoords(cell, float(dmg))

func _detonate_final(pos: Vector2, dmg: float) -> void:
	var tree = get_tree()
	if not tree or not tree.root: return
	var tm = tree.root.find_child("TileMapManager", true, false)
	if tm and tm.has_method("damageTileCoords"):
		var center_cell = tm.local_to_map(pos)
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				tm.damageTileCoords(center_cell + Vector2i(dx, dy), float(dmg))
'@ | Set-Content -Path $bbProjPath -Encoding UTF8
Write-Host "  Updated: bouncing_ball_projectile.gd (damage alias restored, throwing enabled)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. FIX HENRY THE HOOVER & TELETUBBIES HOOK PARSE ERROR
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Fixing Object.get() argument count parse error in vacuum hooks..." -ForegroundColor Cyan
foreach ($m in @("gareth-henry_the_hoover_mod", "gareth-teletubbies_mod")) {
	$vhPath = "$repo\mods-unpacked\$m\mods-unpacked\$m\extensions\scenes\equipment\vacuum_cleaner.hooks.gd"
	if (Test-Path $vhPath) {
		$code = Get-Content $vhPath -Raw
		$code = $code.Replace('lvl = int(Gvars.bonus_equipment_manager.get("vacuum_level", 1))', 'lvl = int(Gvars.bonus_equipment_manager.vacuum_level) if ("vacuum_level" in Gvars.bonus_equipment_manager) else 1')
		Set-Content -Path $vhPath -Value $code -Encoding UTF8
		Write-Host "  Patched: $m\vacuum_cleaner.hooks.gd" -ForegroundColor Green
	}
}

# ------------------------------------------------------------------------------
# 4. FIX AMAZON DELIVERY (ROUTE PASSIVES EXCLUSIVELY TO BUY_EFFECT)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Routing Amazon passive upgrades to buy_effect (no hotbar clutter)..." -ForegroundColor Cyan
$amzPath = "$repo\mods-unpacked\gareth-scrap_and_delivery_mod\mods-unpacked\gareth-scrap_and_delivery_mod\scripts\amazon_delivery_manager.gd"
$amzCode = Get-Content $amzPath -Raw

$oldDeliverBlock = @'
	tween.tween_callback(func():
		var inv: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
		if inv:
			inv.addToInventory(item, 1)
		if item.itemBuyEffect:
			item.itemBuyEffect.buy_effect(item, 1)
		Bus.inventory_changed.emit()
		show_toast("📦 DELIVERED! [%s] safely received." % item.itemName)
		crate.queue_free()
	)
'@

$newDeliverBlock = @'
	tween.tween_callback(func():
		if item.itemBuyEffect:
			item.itemBuyEffect.buy_effect(item, 1)
		else:
			var inv: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
			if inv:
				inv.addToInventory(item, 1)
		Bus.inventory_changed.emit()
		show_toast("📦 DELIVERED! [%s] applied/received." % item.itemName)
		crate.queue_free()
	)
'@

$amzCode = $amzCode.Replace($oldDeliverBlock, $newDeliverBlock)
Set-Content -Path $amzPath -Value $amzCode -Encoding UTF8
Write-Host "  Updated: amazon_delivery_manager.gd (Slots/stacks trigger buy_effect directly)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. FIX DIAGONAL MAP (MAP 105) REGISTRATION & ADD GAME.HOOKS.GD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Adding Game.hooks.gd and fixing stage transition for Diagonal Map (105)..." -ForegroundColor Cyan
$diagExtDir = "$repo\mods-unpacked\gareth-diagonal_map_mod\mods-unpacked\gareth-diagonal_map_mod\extensions"
New-Item -ItemType Directory -Path "$diagExtDir\scripts" -Force | Out-Null

@'
extends Object

func change_stage(chain: ModLoaderHookChain, stage, pos: Vector2) -> void:
	if Gvars and ("level" in Gvars) and Gvars.level == 105:
		var game = chain.reference_object
		if is_instance_valid(game):
			game.load_mine("res://scenes/Stages/MineRegion.tscn")
			return
	chain.execute_next([stage, pos])
'@ | Set-Content -Path "$diagExtDir\scripts\Game.hooks.gd" -Encoding UTF8

# Update mod_main.gd in gareth-diagonal_map_mod to register Game.hooks.gd
$diagMainPath = "$repo\mods-unpacked\gareth-diagonal_map_mod\mods-unpacked\gareth-diagonal_map_mod\mod_main.gd"
@'
extends Node

const MOD_ID := "gareth-diagonal_map_mod"

func _init() -> void:
	var unpacked_dir = ModLoaderMod.get_unpacked_dir().path_join(MOD_ID)
	var ext_dir = unpacked_dir.path_join("extensions")

	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/Menus/level_select.gd",
		ext_dir.path_join("scenes/Interfaces/Menus/level_select.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/tilemaps/tile_map_chunk.gd",
		ext_dir.path_join("scenes/tilemaps/tile_map_chunk.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/Game.gd",
		ext_dir.path_join("scripts/Game.hooks.gd")
	)
	ModLoaderLog.info("Diagonal Map Mod initialized with Game.hooks.gd change_stage support.", MOD_ID)
'@ | Set-Content -Path $diagMainPath -Encoding UTF8

# Update DiagonalMapHelper.gd to register proper CustomLevel resource
$diagHelperPath = "$repo\mods-unpacked\gareth-diagonal_map_mod\mods-unpacked\gareth-diagonal_map_mod\helpers\DiagonalMapHelper.gd"
@'
class_name DiagonalMapHelper
extends RefCounted

const DIAGONAL_LEVEL_ID: int = 105

static func ensure_level_registered() -> void:
	var lvl_mgr = Engine.get_main_loop().root.get_node_or_null("/root/LevelManager")
	if not lvl_mgr:
		var scene = Engine.get_main_loop().current_scene
		if scene:
			lvl_mgr = scene.find_child("LevelManager", true, false)

	if lvl_mgr and ("all_levels" in lvl_mgr):
		if not lvl_mgr.all_levels.has(DIAGONAL_LEVEL_ID):
			var base_res = load("res://resources/Levels/level_1.tres")
			var custom_level = base_res.duplicate() if base_res else Resource.new()
			custom_level.set("level_id", DIAGONAL_LEVEL_ID)
			custom_level.set("level_name", "Diagonal Seams")
			custom_level.set("level_description", "Subterranean strata tilted at a 45-degree angle. Specialized diagonal tunneling required.")
			custom_level.set("mining_scene_path", "res://scenes/Stages/MineRegion.tscn")
			lvl_mgr.all_levels[DIAGONAL_LEVEL_ID] = custom_level
'@ | Set-Content -Path $diagHelperPath -Encoding UTF8
Write-Host "  Updated: gareth-diagonal_map_mod (Game.hooks.gd installed, level 105 loads into day)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. DOCK BROWSE IMAGE BUTTON DIRECTLY ONTO MAP 103 CARD (LEVEL_SELECT.HOOKS.GD)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Repositioning Browse Image button directly onto Map 103 card..." -ForegroundColor Cyan
$lshPath = "$repo\mods-unpacked\gareth-living_canvas_mod\mods-unpacked\gareth-living_canvas_mod\extensions\scenes\Interfaces\Menus\level_select.hooks.gd"
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
	if helper_script and helper_script.has_method("ensure_level_registered"):
		helper_script.ensure_level_registered()

	var ls = chain.reference_object
	if ls and ("LEVEL_ORDER" in ls):
		if not ls.LEVEL_ORDER.has(103):
			ls.LEVEL_ORDER.append(103)

	chain.execute_next([])

	if not is_instance_valid(ls):
		return

	# Remove any lingering root-level button on the grass
	var old_root_btn = ls.get_node_or_null("CanvasImagePickerBtn")
	if is_instance_valid(old_root_btn):
		old_root_btn.queue_free()

	# Attach Browse button directly inside the Level 103 card in %Levels
	var levels_box = ls.get_node_or_null("%Levels")
	if levels_box:
		for card in levels_box.get_children():
			var is_target := false
			if ("level" in card) and card.level and ("level_id" in card.level) and card.level.level_id == 103:
				is_target = true
			elif "103" in card.name or "canvas" in card.name.to_lower():
				is_target = true
			else:
				for lbl in card.find_children("*", "Label", true, false):
					if "Living Canvas" in lbl.text:
						is_target = true
						break

			if is_target and not card.has_node("CanvasImagePickerBtn"):
				var btn_pick = Button.new()
				btn_pick.name = "CanvasImagePickerBtn"
				btn_pick.text = "📁 Browse Custom Image"
				btn_pick.custom_minimum_size = Vector2(0, 28)
				btn_pick.modulate = Color(0.4, 0.9, 1.0)
				btn_pick.pressed.connect(func(): _open_file_dialog(ls))
				card.add_child(btn_pick)
				break

func _open_file_dialog(menu: Control) -> void:
	var fd = FileDialog.new()
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.filters = PackedStringArray(["*.png, *.jpg, *.jpeg ; Image Files"])
	fd.title = "Select Image for The Living Canvas Mosaic"
	fd.file_selected.connect(func(path: String):
		var helper = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
		if helper and helper.has_method("set_active_canvas_image"):
			helper.set_active_canvas_image(path)
		fd.queue_free()
	)
	menu.add_child(fd)
	fd.popup_centered(Vector2i(700, 500))
'@ | Set-Content -Path $lshPath -Encoding UTF8
Write-Host "  Updated: level_select.hooks.gd (Button attached inside card, grass clear)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 7. REPACK AND SYNC ALL AFFECTED MODS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Repackaging and syncing updated archives..." -ForegroundColor Cyan
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

$modsToSync = @(
	"gareth-bouncing_ball_mod",
	"gareth-scrap_and_delivery_mod",
	"gareth-diagonal_map_mod",
	"gareth-living_canvas_mod",
	"gareth-henry_the_hoover_mod",
	"gareth-teletubbies_mod"
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

	# If currently installed in Steam mods/, update active copy as well
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
git commit -m "Fix: Bouncing ball damage alias, Diagonal Map change_stage hook, Amazon passive upgrade delivery, and Living Canvas card button docking"
git push origin main

Write-Host "`nDeployment complete! Zero tests executed (awaiting gameplay session)." -ForegroundColor Green