$repoRoot = "C:\Dev\coal-llc-mods"
$steamMods = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mods"
$downMods = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\downloaded_mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
Set-Location -Path $repoRoot

# Ensure game and Godot are closed
Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- Patching Bouncing Ball Mod ---"
$ballEquipPath = "mods-unpacked\gareth-bouncing_ball_mod\mods-unpacked\gareth-bouncing_ball_mod\scripts\bouncing_ball_equip.gd"
$ballEquipScript = @"
class_name BouncingBallEquipEffect
extends EquipEffect

@export var damage: float = 95.0
@export var radius: float = 3.0

var weapon_visual: Sprite2D = null
var throw_cooldown: float = 0.0
var _is_using: bool = false
var _auto_throw_toggle: bool = false
var held_item = null

func start(player, item):
	held_item = item
	if "tool" in player and player.tool:
		player.tool.visible = false

	weapon_visual = Sprite2D.new()
	weapon_visual.texture = item.itemTexture
	weapon_visual.offset = Vector2(0, -4)
	weapon_visual.position = Vector2(4, 2)
	weapon_visual.visible = true
	player.add_child(weapon_visual)
	_is_using = false
	_auto_throw_toggle = false

func end(player):
	if "tool" in player and player.tool:
		player.tool.visible = true
	if weapon_visual and is_instance_valid(weapon_visual):
		weapon_visual.queue_free()
	_is_using = false
	_auto_throw_toggle = false

func physics_process(player, delta):
	if throw_cooldown > 0.0:
		throw_cooldown -= delta

	if weapon_visual and is_instance_valid(weapon_visual):
		var p_pos: Vector2 = player.global_position
		var pointer_pos: Vector2 = player.pointer_global_pos
		var angle: float = (pointer_pos - p_pos).angle()
		weapon_visual.rotation = angle
		weapon_visual.flip_v = (pointer_pos.x < p_pos.x)

	if Input.is_action_pressed("useItem") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_is_using = true
	elif Input.is_action_just_released("useItem") or (not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not _auto_throw_toggle):
		_is_using = false

	if Input.is_action_just_pressed("toggle_use_item") or Input.is_action_just_pressed("rightMouseClick"):
		_auto_throw_toggle = not _auto_throw_toggle
		_is_using = _auto_throw_toggle

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_is_using = true

	if _is_using and throw_cooldown <= 0.0:
		_throw_bouncing_ball(player)

func _get_passive_stat(stat_name: String) -> float:
	if not Gvars or not ("passives" in Gvars) or not Gvars.passives:
		return 0.0
	var p = Gvars.passives
	if p.has_meta(stat_name):
		return float(p.get_meta(stat_name))
	if stat_name in p:
		return float(p.get(stat_name))
	return 0.0

func _throw_bouncing_ball(player) -> void:
	var fire_rate_mult: float = 1.0 + _get_passive_stat("ball_fire_rate")
	throw_cooldown = max(0.10, 0.44 / fire_rate_mult)

	var p_pos: Vector2 = player.global_position
	var pointer_pos: Vector2 = player.pointer_global_pos
	var dir: Vector2 = (pointer_pos - p_pos).normalized()

	if weapon_visual and is_instance_valid(weapon_visual):
		var orig_pos = weapon_visual.position
		weapon_visual.position -= dir * 3.0
		var tween = player.create_tween()
		if tween:
			tween.tween_property(weapon_visual, "position", orig_pos, 0.08)

	var proj_script = load("res://mods-unpacked/gareth-bouncing_ball_mod/scripts/bouncing_ball_projectile.gd")
	var proj := CharacterBody2D.new()
	proj.set_script(proj_script)

	var dmg_mult: float = 1.0 + _get_passive_stat("ball_blast_damage")
	proj.damage = damage * dmg_mult

	var rad_mult: float = 1.0 + _get_passive_stat("ball_blast_radius")
	proj.radius = radius * rad_mult

	if "tilemap" in player:
		proj.tilemap = player.tilemap

	if held_item and "itemTexture" in held_item:
		proj.ball_texture = held_item.itemTexture

	proj.global_position = p_pos + (dir * 14.0)
	proj.velocity = Vector2(dir.x * 300.0, min(-140.0, dir.y * 300.0 - 110.0))

	var parent = player.get_parent()
	if parent:
		parent.call_deferred("add_child", proj)
	else:
		player.call_deferred("add_child", proj)
'@
$ballEquipScript | Set-Content -Path $ballEquipPath -Encoding UTF8

$ballProjPath = "mods-unpacked\gareth-bouncing_ball_mod\mods-unpacked\gareth-bouncing_ball_mod\scripts\bouncing_ball_projectile.gd"
$ballProjScript = @"
class_name BouncingBallProjectile
extends CharacterBody2D

const GRAVITY: float = 620.0
const BOUNCE_DAMPING: float = 0.76
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
var _fuse_timer: float = 1.4

func _ready() -> void:
	z_index = 35
	_sprite = get_node_or_null("Sprite2D")
	if not _sprite:
		_sprite = Sprite2D.new()
		_sprite.name = "Sprite2D"
		add_child(_sprite)
	if ball_texture:
		_sprite.texture = ball_texture
		
	var shape := CircleShape2D.new()
	shape.radius = 7.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)

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
		
	_fuse_timer -= delta
	if _fuse_timer <= 0.0:
		_detonate_final(global_position, base_damage)
		queue_free()
		return

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
	_spawn_blast_shockwave()
	var tm = tilemap
	if not is_instance_valid(tm):
		var tree = get_tree()
		if tree and tree.root:
			tm = tree.root.find_child("TileMapManager", true, false)
	if tm and tm.has_method("damageTileCoords"):
		var center_cell = tm.local_to_map(pos)
		var r_int: int = int(ceil(radius))
		for dx in range(-r_int, r_int + 1):
			for dy in range(-r_int, r_int + 1):
				if Vector2(dx, dy).length() <= radius:
					tm.damageTileCoords(center_cell + Vector2i(dx, dy), float(dmg))

func _spawn_blast_shockwave() -> void:
	var ring := Line2D.new()
	ring.width = 3.0
	ring.default_color = Color(1.0, 0.65, 0.15, 0.95)
	var segs: int = 16
	for i in range(segs + 1):
		var ang: float = float(i) * TAU / float(segs)
		ring.add_point(global_position + Vector2(cos(ang), sin(ang)) * 5.0)
	
	var parent = get_parent()
	if parent:
		parent.call_deferred("add_child", ring)
		
		var tween = parent.create_tween()
		if tween:
			tween.set_parallel(true)
			tween.tween_property(ring, "scale", Vector2(3.5, 3.5), 0.16)
			tween.tween_property(ring, "modulate:a", 0.0, 0.16)
			tween.set_parallel(false)
			tween.tween_callback(ring.queue_free)
'@
$ballProjScript | Set-Content -Path $ballProjPath -Encoding UTF8

Write-Output "--- Patching Diagonal Map Helper ---"
$diagHelperPath = "mods-unpacked\gareth-diagonal_map_mod\mods-unpacked\gareth-diagonal_map_mod\helpers\DiagonalMapHelper.gd"
$diagHelperScript = @"
class_name DiagonalMapHelper
extends RefCounted

const DIAGONAL_LEVEL_ID: int = 105
const PREVIEW_PATH: String = "res://mods-unpacked/gareth-diagonal_map_mod/assets/diagonal_preview.png"

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
		custom_level.level_image = _get_or_create_preview()
		
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

static func _get_or_create_preview() -> ImageTexture:
	if FileAccess.file_exists(PREVIEW_PATH):
		var bytes = FileAccess.get_file_as_bytes(PREVIEW_PATH)
		if bytes and bytes.size() > 0:
			var img = Image.new()
			if img.load_png_from_buffer(bytes) == OK:
				return ImageTexture.create_from_image(img)

	# Generate procedural diagonal preview card
	var img = Image.create(96, 64, false, Image.FORMAT_RGBA8)
	var col1 = Color(0.18, 0.22, 0.30, 1.0)
	var col2 = Color(0.85, 0.55, 0.20, 1.0)
	var col3 = Color(0.30, 0.65, 0.85, 1.0)
	for x in range(96):
		for y in range(64):
			var diag = (x + y) % 24
			if diag < 10:
				img.set_pixel(x, y, col1)
			elif diag < 16:
				img.set_pixel(x, y, col2)
			else:
				img.set_pixel(x, y, col3)
	return ImageTexture.create_from_image(img)
"@
$diagHelperScript | Set-Content -Path $diagHelperPath -Encoding UTF8

Write-Output "--- Repacking and Deploying Mods ---"

# Delete ModLoader hooks cache
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force }

$targetMods = @("gareth-bouncing_ball_mod", "gareth-diagonal_map_mod")

foreach ($mod in $targetMods) {
    $srcDir = Join-Path $repoRoot "mods-unpacked\$mod"
    $downZip = Join-Path $downMods "$mod.zip"
    $steamZip = Join-Path $steamMods "$mod.zip"
    
    if (Test-Path $downZip) { Remove-Item $downZip -Force }
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::Open($downZip, [System.IO.Compression.ZipArchiveMode]::Create)
    $files = Get-ChildItem -Path $srcDir -Recurse -File
    
    foreach ($file in $files) {
        $entryName = $file.FullName.Substring($srcDir.Length + 1).Replace("\", "/")
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $entryName)
    }
    $archive.Dispose()
    
    # Sync to runtime directory if it exists
    if (Test-Path $steamZip) {
        Copy-Item -Path $downZip -Destination $steamZip -Force
        Write-Output "Deployed $mod.zip to runtime mods."
    }
}

Write-Output "--- Committing to Git ---"
git add -A
git commit -m "Fix: Restore Diagonal Map procedural preview generation and Bouncing Ball physics, collision, and blast shockwave."
git push origin main
Write-Output "All complete!"