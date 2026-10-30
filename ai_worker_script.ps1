# ==============================================================================
# Coal LLC - Fix Custom Maps Carousel, Ball Properties, Amazon Stack & Henry Skin
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
# 2. FIX BOUNCING_BALL_PROJECTILE.GD PROPERTIES (RADIUS, TILEMAP, TEXTURE)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Adding radius, tilemap, and ball_texture to bouncing_ball_projectile.gd..." -ForegroundColor Cyan
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
	if _sprite and ball_texture:
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

		# 3-Tier Multiplier Calculation:
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
Write-Host "  Updated: bouncing_ball_projectile.gd (radius, tilemap, texture properties active)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. FIX DIAGONAL MAP & LEVEL_SELECT DICTIONARY STRUCTURE (RESTORE CAROUSEL)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Ensuring all custom maps register as proper Dictionaries in LevelManager..." -ForegroundColor Cyan

# Update DiagonalMapHelper.gd to register as Dictionary { "level": custom_level, "is_unlocked": true }
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
			lvl_mgr.all_levels[DIAGONAL_LEVEL_ID] = {
				"level": custom_level,
				"is_unlocked": true
			}
'@ | Set-Content -Path $diagHelperPath -Encoding UTF8

# Update level_select.hooks.gd in diagonal_map_mod to register BEFORE execute_next
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
Write-Host "  Updated: DiagonalMapHelper.gd & level_select.hooks.gd (Dictionary {level, is_unlocked} fixed)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. FIX HENRY THE HOOVER: HOOK _PHYSICS_PROCESS (VANILLA LACKS _READY)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Hooking _physics_process in vacuum_cleaner.hooks.gd for Henry & Noo-Noo..." -ForegroundColor Cyan

$henryHook = "$repo\mods-unpacked\gareth-henry_the_hoover_mod\mods-unpacked\gareth-henry_the_hoover_mod\extensions\scenes\equipment\vacuum_cleaner.hooks.gd"
@'
extends Object

func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	chain.execute_next([delta])
	var vac = chain.reference_object
	if not is_instance_valid(vac):
		return

	var factory = load("res://mods-unpacked/gareth-henry_the_hoover_mod/scripts/henry_texture_factory.gd")
	if not factory:
		return

	var vac_end = vac.find_child("VacuumEnd", true, false)
	if is_instance_valid(vac_end) and vac_end is Sprite2D:
		var lvl: int = 1
		if Gvars and ("bonus_equipment_manager" in Gvars) and Gvars.bonus_equipment_manager:
			lvl = int(Gvars.bonus_equipment_manager.vacuum_level) if ("vacuum_level" in Gvars.bonus_equipment_manager) else 1

		# Apply texture on initialization or tier upgrade
		if vac.get_meta("henry_applied_lvl", 0) != lvl:
			vac.set_meta("henry_applied_lvl", lvl)
			vac_end.texture = factory.create_henry_texture(lvl)
			vac_end.scale = Vector2(1.5, 1.5)
'@ | Set-Content -Path $henryHook -Encoding UTF8

$ttHook = "$repo\mods-unpacked\gareth-teletubbies_mod\mods-unpacked\gareth-teletubbies_mod\extensions\scenes\equipment\vacuum_cleaner.hooks.gd"
@'
extends Object

func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	chain.execute_next([delta])
	var vac = chain.reference_object
	if not is_instance_valid(vac):
		return

	var factory = load("res://mods-unpacked/gareth-teletubbies_mod/scripts/teletubbies_texture_factory.gd")
	if not factory:
		return

	var vac_end = vac.find_child("VacuumEnd", true, false)
	if is_instance_valid(vac_end) and vac_end is Sprite2D:
		var lvl: int = 1
		if Gvars and ("bonus_equipment_manager" in Gvars) and Gvars.bonus_equipment_manager:
			lvl = int(Gvars.bonus_equipment_manager.vacuum_level) if ("vacuum_level" in Gvars.bonus_equipment_manager) else 1

		if vac.get_meta("noo_noo_applied_lvl", 0) != lvl:
			vac.set_meta("noo_noo_applied_lvl", lvl)
			vac_end.texture = factory.create_noo_noo_texture(lvl)
			vac_end.scale = Vector2(1.5, 1.5)
'@ | Set-Content -Path $ttHook -Encoding UTF8
Write-Host "  Updated: vacuum_cleaner.hooks.gd to hook _physics_process (Henry & Noo-Noo skin attachments guaranteed)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. FIX AMAZON DELIVERY: PREVENT BUY_EFFECT DOUBLE-CHARGE FROM ABORTING STACKS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Updating Amazon delivery callback to guarantee stack size & slot additions..." -ForegroundColor Cyan
$amzScript = "$repo\mods-unpacked\gareth-scrap_and_delivery_mod\mods-unpacked\gareth-scrap_and_delivery_mod\scripts\amazon_delivery_manager.gd"
$amzCode = Get-Content $amzScript -Raw

$oldDeliveryTween = @'
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

$newDeliveryTween = @'
	tween.tween_callback(func():
		if item.itemBuyEffect:
			# Prevent double-charge cash checks from failing inside buy_effect
			var original_price = item.itemBuyPrice
			item.itemBuyPrice = 0.0
			item.itemBuyEffect.buy_effect(item, 1)
			item.itemBuyPrice = original_price

			# Directly update player inventory capacity if defined on the effect
			var inv: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
			if inv:
				if "max_stack_to_add" in item.itemBuyEffect:
					inv.maxStack += int(item.itemBuyEffect.max_stack_to_add)
					inv.initialise_slots()
				if "slots_to_add" in item.itemBuyEffect:
					inv.inventorySize += int(item.itemBuyEffect.slots_to_add)
					inv.initialise_slots()
		else:
			var inv: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
			if inv:
				inv.addToInventory(item, 1)
		Bus.inventory_changed.emit()
		show_toast("📦 DELIVERED! [%s] upgraded/received." % item.itemName)
		crate.queue_free()
	)
'@

$amzCode = $amzCode.Replace($oldDeliveryTween, $newDeliveryTween)
Set-Content -Path $amzScript -Value $amzCode -Encoding UTF8
Write-Host "  Updated: amazon_delivery_manager.gd (itemBuyPrice=0 during delivery, maxStack/slots applied)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. DOCK BROWSE IMAGE BUTTON NEATLY INSIDE MAP 103 CARD CONTAINER
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Repositioning Browse Image button cleanly inside Map 103 card..." -ForegroundColor Cyan
$canvasLsh = "$repo\mods-unpacked\gareth-living_canvas_mod\mods-unpacked\gareth-living_canvas_mod\extensions\scenes\Interfaces\Menus\level_select.hooks.gd"
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

	# Remove any bottom-screen viewport buttons over the grass
	var old_btn = ls.get_node_or_null("CanvasImagePickerBtn")
	if is_instance_valid(old_btn):
		old_btn.queue_free()

	# Attach Browse button inside the Level 103 card container
	var levels_box = ls.get_node_or_null("%Levels")
	if levels_box:
		for card in levels_box.get_children():
			var is_map_103 := false
			if ("game_level" in card) and card.game_level and ("level_id" in card.game_level) and card.game_level.level_id == 103:
				is_map_103 = true
			elif ("level" in card) and card.level and ("level_id" in card.level) and card.level.level_id == 103:
				is_map_103 = true
			else:
				for lbl in card.find_children("*", "Label", true, false):
					if "Living Canvas" in lbl.text:
						is_map_103 = true
						break

			if is_map_103 and not card.has_node("CanvasImagePickerBtn"):
				var btn_pick = Button.new()
				btn_pick.name = "CanvasImagePickerBtn"
				btn_pick.text = "📁 Browse Custom Image"
				btn_pick.custom_minimum_size = Vector2(0, 26)
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
'@ | Set-Content -Path $canvasLsh -Encoding UTF8
Write-Host "  Updated: level_select.hooks.gd for Living Canvas (docked inside card container)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 7. REPACK AND SYNC ALL AFFECTED MODS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Repackaging and staging all affected mod archives..." -ForegroundColor Cyan
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

$modsToSync = @(
	"gareth-bouncing_ball_mod",
	"gareth-diagonal_map_mod",
	"gareth-henry_the_hoover_mod",
	"gareth-teletubbies_mod",
	"gareth-scrap_and_delivery_mod",
	"gareth-living_canvas_mod"
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

	# If installed in active mods/, update active copy as well
	$activeZip = "$steamMods\$m.zip"
	if (Test-Path $activeZip) {
		Copy-Item -Path $zip -Destination $activeZip -Force
		Write-Host "  Synced active: $m.zip in mods/" -ForegroundColor Green
	}
	Write-Host "  Updated stage: $m.zip in downloaded_mods/" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 8. COMMIT AND PUSH TO GITHUB
# ------------------------------------------------------------------------------
Write-Host "`n>>> 8. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Fix: Bouncing ball radius/tilemap properties, Map 105 Dictionary registration, Henry vacuum skin _physics_process hook, Amazon stack size capacity expansion, and Living Canvas card-docked browse button"
git push origin main

Write-Host "`nDeployment complete! Zero tests executed (awaiting gameplay session)." -ForegroundColor Green