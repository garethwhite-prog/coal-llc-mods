$repoRoot = "C:\Dev\coal-llc-mods"
$steamMods = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mods"
$downMods = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. Patching Living Canvas UI (Deferred Mount) ---"
$lcHookPath = "$repoRoot\mods-unpacked\gareth-living_canvas_mod\mods-unpacked\gareth-living_canvas_mod\extensions\scenes\Interfaces\Menus\level_select.hooks.gd"
$lcScript = @"
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var ls = chain.reference_object
	if ls and ("LEVEL_ORDER" in ls):
		if not ls.LEVEL_ORDER.has(103):
			ls.LEVEL_ORDER.append(103)
	
	chain.execute_next([])
	
	if is_instance_valid(ls):
		var levels_grid = ls.get_node_or_null("%Levels")
		if levels_grid:
			for card in levels_grid.get_children():
				var is_map_103 := false
				if ("game_level" in card) and card.game_level and ("level" in card.game_level) and card.game_level.level == 103:
					is_map_103 = true
				elif ("level" in card) and card.level and ("level_id" in card.level) and card.level.level_id == 103:
					is_map_103 = true
				else:
					for lbl in card.find_children("*", "Label", true, false):
						if "Living Canvas" in lbl.text:
							is_map_103 = true
							break
							
				if is_map_103:
					var container = card.get_node_or_null("MarginContainer/VBoxContainer")
					if container and not container.has_node("CanvasImagePickerBtn"):
						var btn = Button.new()
						btn.name = "CanvasImagePickerBtn"
						btn.text = "Browse Custom Canvas..."
						btn.custom_minimum_size = Vector2(0, 26)
						btn.modulate = Color(0.4, 0.9, 1.0)
						var helper = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
						if helper:
							btn.pressed.connect(Callable(helper.new(), "_on_browse_pressed"))
						container.call_deferred("add_child", btn)
"@
$lcScript | Set-Content -Path $lcHookPath -Encoding UTF8

Write-Output "--- 2. Rebuilding Bouncing Ball Physics & Collision ---"
$ballProjPath = "$repoRoot\mods-unpacked\gareth-bouncing_ball_mod\mods-unpacked\gareth-bouncing_ball_mod\scripts\bouncing_ball_projectile.gd"
$ballScript = @"
class_name BouncingBallProjectile
extends CharacterBody2D

const GRAVITY: float = 620.0
const BOUNCE_DAMPING: float = 0.76
var base_damage: float = 95.0

var damage: float:
	get: return base_damage
	set(val): base_damage = val

var radius: float = 16.0
var tilemap: Node = null
var ball_texture: Texture2D = null

var _bounces_left: int = 4
var _total_bounces_made: int = 0
var _sprite: Sprite2D = null
var _fuse_timer: float = 1.4

func _ready() -> void:
	z_index = 35
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite2D"
	if ball_texture:
		_sprite.texture = ball_texture
	add_child(_sprite)
	
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	var shape := CollisionShape2D.new()
	shape.shape = circle
	add_child(shape)

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
	call_deferred("_spawn_blast_shockwave")
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
		parent.add_child(ring)
		var tween = parent.create_tween()
		if tween:
			tween.set_parallel(true)
			tween.tween_property(ring, "scale", Vector2(3.5, 3.5), 0.16)
			tween.tween_property(ring, "modulate:a", 0.0, 0.16)
			tween.set_parallel(false)
			tween.tween_callback(ring.queue_free)
"@
$ballScript | Set-Content -Path $ballProjPath -Encoding UTF8

Write-Output "--- 3. Repacking Bouncing Ball & Living Canvas ---"
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force }

$targetMods = @("gareth-living_canvas_mod", "gareth-bouncing_ball_mod")
Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($mod in $targetMods) {
    $srcDir = "$repoRoot\mods-unpacked\$mod"
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
git commit -m "Fix: Re-attach CollisionShape2D to Bouncing Ball to restore physics layer, and safely mount Living Canvas button using call_deferred to prevent tree lock crash."
git push origin main
Write-Output "Completed!"