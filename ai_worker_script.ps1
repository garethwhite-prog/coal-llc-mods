# ==============================================================================
# Coal LLC - Bouncing Ball 3-Tier Stacking, Vacuum Fix, Amazon Delivery & End Day
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
# 2. IMPLEMENT 3-TIER DAMAGE STACKING IN BOUNCING_BALL_PROJECTILE.GD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Implementing 3-tier stacking damage multipliers in bouncing ball..." -ForegroundColor Cyan
$bbProjPath = "$repo\mods-unpacked\gareth-bouncing_ball_mod\mods-unpacked\gareth-bouncing_ball_mod\scripts\bouncing_ball_projectile.gd"
@'
class_name BouncingBallProjectile
extends CharacterBody2D

const GRAVITY: float = 620.0
const BOUNCE_DAMPING: float = 0.88
var base_damage: float = 95.0
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
Write-Host "  Updated: bouncing_ball_projectile.gd with 3 compounding damage multipliers" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. FIX OBJECT.GET PARSE ERROR IN HENRY & TELETUBBIES HOOKS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Fixing Object.get() argument count parse error in vacuum hooks..." -ForegroundColor Cyan
foreach ($m in @("gareth-henry_the_hoover_mod", "gareth-teletubbies_mod")) {
	$vhPath = "$repo\mods-unpacked\$m\mods-unpacked\$m\extensions\scenes\equipment\vacuum_cleaner.hooks.gd"
	if (Test-Path $vhPath) {
		$code = Get-Content $vhPath -Raw
		# Replace invalid Object.get("vacuum_level", 1) with safe property check
		$code = $code.Replace('lvl = int(Gvars.bonus_equipment_manager.get("vacuum_level", 1))', 'lvl = int(Gvars.bonus_equipment_manager.vacuum_level) if ("vacuum_level" in Gvars.bonus_equipment_manager) else 1')
		Set-Content -Path $vhPath -Value $code -Encoding UTF8
		Write-Host "  Patched: $m\vacuum_cleaner.hooks.gd" -ForegroundColor Green
	}
}

# ------------------------------------------------------------------------------
# 4. FIX AMAZON EMERGENCY DRONE CRATE SPAWN & DIRECT INVENTORY DELIVERY
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Fixing Amazon delivery crate visibility & delivery pipeline..." -ForegroundColor Cyan
$amzPath = "$repo\mods-unpacked\gareth-scrap_and_delivery_mod\mods-unpacked\gareth-scrap_and_delivery_mod\scripts\amazon_delivery_manager.gd"
$amzCode = Get-Content $amzPath -Raw

$oldSpawn = @'
func _spawn_parachute_crate(item: Item, player_node) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return

	var crate = Node2D.new()
	crate.name = "AmazonDeliveryCrate"
	var spawn_x: float = player_node.global_position.x if (is_instance_valid(player_node) and ("global_position" in player_node)) else 0.0
	crate.global_position = Vector2(spawn_x, -60.0)

	var spr = Sprite2D.new()
	spr.texture = item.itemTexture if is_instance_valid(item.itemTexture) else load("res://assets/Equipment/kicks/kick_04_sapphire.png")
	spr.scale = Vector2(1.6, 1.6)
	crate.add_child(spr)
	tree.current_scene.add_child(crate)

	var target_y = player_node.global_position.y if (is_instance_valid(player_node) and ("global_position" in player_node)) else 0.0
	var tween = tree.create_tween()
	tween.tween_property(crate, "global_position:y", target_y, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		if item.itemBuyEffect:
			item.itemBuyEffect.buy_effect(item, 1)
		else:
			var inv: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
			if inv:
				inv.addToInventory(item, 1)
		Bus.inventory_changed.emit()
		show_toast("📦 DELIVERED! [%s] acquired." % item.itemName)
		crate.queue_free()
	)
'@

$newSpawn = @'
func _spawn_parachute_crate(item: Item, player_node) -> void:
	var tree = get_tree()
	if not tree or not tree.root:
		return

	var p = player_node if is_instance_valid(player_node) else tree.root.find_child("Player", true, false)
	if not is_instance_valid(p):
		return

	var crate = Node2D.new()
	crate.name = "AmazonDeliveryCrate"
	crate.z_index = 60
	crate.global_position = Vector2(p.global_position.x, p.global_position.y - 320.0)

	var spr = Sprite2D.new()
	spr.texture = item.itemTexture if is_instance_valid(item.itemTexture) else load("res://assets/Equipment/kicks/kick_04_sapphire.png")
	spr.scale = Vector2(2.0, 2.0)
	crate.add_child(spr)

	p.get_parent().add_child(crate)

	var target_y = p.global_position.y - 12.0
	var tween = tree.create_tween()
	tween.tween_property(crate, "global_position:y", target_y, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
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

$amzCode = $amzCode.Replace($oldSpawn, $newSpawn)
Set-Content -Path $amzPath -Value $amzCode -Encoding UTF8
Write-Host "  Updated: amazon_delivery_manager.gd (z_index=60, guaranteed delivery to PlayerInventory)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. RESTORE "END DAY EARLY" BUTTON IN SPEED_CONTROLLER.GD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Restoring 'End Day Early' button in speed_controller.gd..." -ForegroundColor Cyan
$scPath = "$repo\mods-unpacked\gareth-game_speed_mod\mods-unpacked\gareth-game_speed_mod\scripts\speed_controller.gd"
@'
extends Node

var canvas: CanvasLayer
var panel: PanelContainer
var lbl_speed: Label
var btn_slower: Button
var btn_faster: Button
var btn_end_day: Button

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
	panel.offset_left = -210.0
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
	btn_slower.custom_minimum_size = Vector2(22, 22)
	btn_slower.add_theme_font_size_override("font_size", 10)
	btn_slower.pressed.connect(_decrease_speed)
	hbox.add_child(btn_slower)

	lbl_speed = Label.new()
	lbl_speed.text = "1.00x"
	lbl_speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_speed.custom_minimum_size = Vector2(40, 22)
	lbl_speed.add_theme_font_size_override("font_size", 10)
	hbox.add_child(lbl_speed)

	btn_faster = Button.new()
	btn_faster.text = "▶"
	btn_faster.custom_minimum_size = Vector2(22, 22)
	btn_faster.add_theme_font_size_override("font_size", 10)
	btn_faster.pressed.connect(_increase_speed)
	hbox.add_child(btn_faster)

	btn_end_day = Button.new()
	btn_end_day.text = "⏰ End Day"
	btn_end_day.tooltip_text = "Finish Shift Early / Emergency Exit [Hotkey F8]"
	btn_end_day.custom_minimum_size = Vector2(78, 22)
	btn_end_day.add_theme_font_size_override("font_size", 10)
	btn_end_day.modulate = Color(1.0, 0.5, 0.5)
	btn_end_day.pressed.connect(_finish_shift_early)
	hbox.add_child(btn_end_day)

	canvas.add_child(panel)

func _process(_delta: float) -> void:
	var mining = _is_actively_mining()
	if panel and panel.visible != mining:
		panel.visible = mining

func _unhandled_input(event: InputEvent) -> void:
	if panel and panel.visible and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F8:
			_finish_shift_early()

func _is_actively_mining() -> bool:
	var tree = get_tree()
	if not tree or not tree.root: return false
	var scene = tree.current_scene
	if scene and (scene.name == "MainMenu" or scene.name == "level_select"): return false

	var mgmt = tree.root.find_child("management_screen", true, false)
	if not mgmt: mgmt = tree.root.find_child("ManagementScreen", true, false)
	if mgmt and mgmt.is_visible_in_tree(): return false

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

func _finish_shift_early() -> void:
	Engine.time_scale = 1.0
	current_idx = 3
	_apply_speed()
	var g = Engine.get_main_loop().root.get_node_or_null("/root/Game")
	if g:
		if g.has_method("on_EndDay"):
			g.on_EndDay()
		elif g.has_method("change_stage") and Gconsts and ("Stages" in Gconsts):
			g.change_stage(Gconsts.Stages._END_OF_DAY_OVERLAY, Vector2.ZERO)
'@ | Set-Content -Path $scPath -Encoding UTF8
Write-Host "  Updated: speed_controller.gd (⏰ End Day button & F8 hotkey restored)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. ATTACH NATIVE IMAGE FILE BROWSER TO LIVING CANVAS (MAP 103)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Wiring image browser into level_select.hooks.gd for Living Canvas..." -ForegroundColor Cyan
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

	if is_instance_valid(ls) and not ls.has_node("CanvasImagePickerBtn"):
		var btn_pick = Button.new()
		btn_pick.name = "CanvasImagePickerBtn"
		btn_pick.text = "📁 Browse Custom Image (Map 103)"
		btn_pick.custom_minimum_size = Vector2(250, 34)
		btn_pick.anchor_left = 0.5
		btn_pick.anchor_right = 0.5
		btn_pick.anchor_top = 1.0
		btn_pick.anchor_bottom = 1.0
		btn_pick.offset_left = -125.0
		btn_pick.offset_right = 125.0
		btn_pick.offset_top = -54.0
		btn_pick.offset_bottom = -20.0
		btn_pick.modulate = Color(0.4, 0.9, 1.0)
		btn_pick.pressed.connect(func(): _open_file_dialog(ls))
		ls.add_child(btn_pick)

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
Write-Host "  Updated: level_select.hooks.gd (Native FileDialog image browser mounted)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 7. REPACK AND STAGE ALL TARGETED PACKAGES
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Repackaging and syncing targeted mods..." -ForegroundColor Cyan
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

$modsToSync = @(
	"gareth-bouncing_ball_mod",
	"gareth-scrap_and_delivery_mod",
	"gareth-game_speed_mod",
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

	# If the user has already installed the mod into Steam mods/, keep it synced
	$activeZip = "$steamMods\$m.zip"
	if (Test-Path $activeZip) {
		Copy-Item -Path $zip -Destination $activeZip -Force
		Write-Host "  Synced active mod: $m.zip in mods/" -ForegroundColor Green
	}
	Write-Host "  Updated stage: $m.zip in downloaded_mods/" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 8. STAGE, COMMIT AND PUSH TO GITHUB
# ------------------------------------------------------------------------------
Write-Host "`n>>> 8. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Feature: 3-tier bouncing ball damage stacking, fix vacuum hook parse error, restore End Day button & F8 hotkey, repair Amazon parachute delivery layer, and re-add Living Canvas image picker"
git push origin main

Write-Host "`nDeployment complete! Zero tests executed (awaiting gameplay session)." -ForegroundColor Green