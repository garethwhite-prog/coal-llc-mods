cls

# ==============================================================================
# Coal LLC - Add Magma Siphon Eruption FX, Pickaxe Detonation & Steam Updraft
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$modName    = "gareth-tectonic_faultline_mod"
$outerDir   = "$repo\mods-unpacked\$modName"
$innerDir   = "$outerDir\mods-unpacked\$modName"
$zipPath    = "$steamMods\$modName.zip"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Patching entities/MagmaSiphon.gd with FX, pickaxe strike, and steam updraft..." -ForegroundColor Cyan
@'
class_name MagmaSiphon
extends Node2D

var in_range: bool = false
var vented: bool = false
var sprite: Sprite2D
var prompt_label: Label
var tex_active: Texture2D
var tex_vented: Texture2D
var cached_player: Node2D = null

# Visual shockwave ring parameters
var fx_radius: float = 0.0
var fx_alpha: float = 0.0

func _ready() -> void:
	z_index = 6
	
	var img_active = Image.load_from_file("res://mods-unpacked/gareth-tectonic_faultline_mod/assets/magma_siphon_active.png")
	if img_active:
		tex_active = ImageTexture.create_from_image(img_active)
	
	var img_vented = Image.load_from_file("res://mods-unpacked/gareth-tectonic_faultline_mod/assets/magma_siphon_vented.png")
	if img_vented:
		tex_vented = ImageTexture.create_from_image(img_vented)
	
	sprite = Sprite2D.new()
	sprite.texture = tex_active
	add_child(sprite)
	
	prompt_label = Label.new()
	prompt_label.text = "[E] VENT (FLY)  |  [HIT] DETONATE"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.position = Vector2(-75, -28)
	prompt_label.add_theme_font_size_override("font_size", 9)
	prompt_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.1, 1.0))
	prompt_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	prompt_label.add_theme_constant_override("outline_size", 3)
	prompt_label.visible = false
	add_child(prompt_label)

func _get_player() -> Node2D:
	if cached_player and is_instance_valid(cached_player):
		return cached_player
	if Game and "player" in Game and is_instance_valid(Game.player):
		cached_player = Game.player
		return cached_player
	var tree = get_tree()
	if not tree:
		return null
	var p2 = tree.root.find_child("Player2", true, false)
	if p2 and is_instance_valid(p2) and p2 is Node2D:
		cached_player = p2
		return cached_player
	var p = tree.root.find_child("Player", true, false)
	if p and is_instance_valid(p) and p is Node2D:
		cached_player = p
		return cached_player
	return null

func _process(_delta: float) -> void:
	if vented:
		return
	
	var player = _get_player()
	if not player:
		return
	
	var dist: float = global_position.distance_to(player.global_position)
	if dist <= 42.0:
		if not in_range:
			in_range = true
			prompt_label.visible = true
			if Bus and Bus.has_signal("ShowInputIndicator"):
				Bus.ShowInputIndicator.emit("interact", true, self)
		
		# 1. Controlled Safe Venting via [E]
		if Input.is_action_just_pressed("interact"):
			vent_controlled(player)
		
		# 2. Volatile Breach via Pickaxe / Drill strike
		elif Input.is_action_just_pressed("mine") or (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and dist <= 32.0):
			breach_volatile()
	else:
		if in_range:
			in_range = false
			prompt_label.visible = false
			if Bus and Bus.has_signal("ShowInputIndicator"):
				Bus.ShowInputIndicator.emit("interact", false, self)

func vent_controlled(player: Node2D) -> void:
	if vented:
		return
	vented = true
	in_range = false
	prompt_label.visible = false
	if Bus and Bus.has_signal("ShowInputIndicator"):
		Bus.ShowInputIndicator.emit("interact", false, self)
	
	_trigger_visual_eruption(false)
	
	# High-Velocity Geothermal Steam Updraft: Launches miner upward toward surface
	if player and ("velocity" in player):
		player.velocity.y = -720.0
	
	# Full energy bounty + coal loot
	var bounty: float = 15000.0 + (abs(global_position.y) * 10.0)
	Gvars.CashCount += bounty
	if Bus and Bus.has_signal("UpdateUI"):
		Bus.UpdateUI.emit()
	
	if Bus and Bus.has_signal("drop_loot"):
		Bus.drop_loot.emit(global_position + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0)), "res://resources/Items/Coal.tres", randi_range(6, 12))
	
	# Thermal shockwave on surrounding rock (3x3 tiles)
	_damage_surrounding_tiles(2, 350)
	
	# Perk offer
	var depth_mult: float = maxf(2.5, minf(7.0, 2.5 + abs(global_position.y) / 200.0))
	if Bus and Bus.has_signal("choose_passive"):
		Bus.choose_passive.emit(depth_mult)
	
	ModLoaderLog.info("Magma Siphon vented! Updraft engaged + Bounty: $" + str(int(bounty)), "gareth-tectonic_faultline_mod")

func breach_volatile() -> void:
	if vented:
		return
	vented = true
	in_range = false
	prompt_label.visible = false
	if Bus and Bus.has_signal("ShowInputIndicator"):
		Bus.ShowInputIndicator.emit("interact", false, self)
	
	_trigger_visual_eruption(true)
	
	# Violent demolition rupture (Large 7x7 tile clearing blast)
	_damage_surrounding_tiles(3, 600)
	
	# Partial salvage cash + massive slag eruption
	var bounty: float = 7500.0 + (abs(global_position.y) * 5.0)
	Gvars.CashCount += bounty
	if Bus and Bus.has_signal("UpdateUI"):
		Bus.UpdateUI.emit()
	
	if Bus and Bus.has_signal("drop_loot"):
		Bus.drop_loot.emit(global_position + Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0)), "res://resources/Items/Coal.tres", randi_range(14, 24))
	
	# Passive selection
	var depth_mult: float = maxf(2.0, minf(5.5, 2.0 + abs(global_position.y) / 250.0))
	if Bus and Bus.has_signal("choose_passive"):
		Bus.choose_passive.emit(depth_mult)
	
	ModLoaderLog.info("Magma Siphon ruptured by pickaxe! Massive 7x7 seismic demolition blast!", "gareth-tectonic_faultline_mod")

func _damage_surrounding_tiles(tile_radius: int, dmg: int) -> void:
	var parent_chunk = get_parent()
	if parent_chunk and parent_chunk.get_parent() and parent_chunk.get_parent().has_method("damageTile"):
		var mgr = parent_chunk.get_parent()
		for dx in range(-tile_radius, tile_radius + 1):
			for dy in range(-tile_radius, tile_radius + 1):
				mgr.damageTile(global_position + Vector2(dx * 16.0, dy * 16.0), dmg)

func _trigger_visual_eruption(is_explosion: bool) -> void:
	# 1. Texture swap to cooled dark obsidian
	if tex_vented:
		sprite.texture = tex_vented
	else:
		sprite.modulate = Color(0.2, 0.2, 0.25, 0.8)
	
	# 2. Audio playback
	var sfx_stream = load("res://assets/sound/sound effects/chestOpen.wav")
	if sfx_stream:
		var sfx = AudioStreamPlayer2D.new()
		sfx.stream = sfx_stream
		sfx.pitch_scale = 0.7 if is_explosion else 1.3
		add_child(sfx)
		sfx.play()
	
	# 3. Fiery Magma Particle Burst
	var p_magma = CPUParticles2D.new()
	p_magma.emitting = true
	p_magma.one_shot = true
	p_magma.explosiveness = 0.95
	p_magma.amount = 45 if is_explosion else 25
	p_magma.lifetime = 0.75
	p_magma.direction = Vector2(0, -1)
	p_magma.spread = 180.0 if is_explosion else 60.0
	p_magma.gravity = Vector2(0, 350)
	p_magma.initial_velocity_min = 160.0 if is_explosion else 220.0
	p_magma.initial_velocity_max = 300.0 if is_explosion else 380.0
	p_magma.color = Color(1.0, 0.55, 0.05, 1.0)
	p_magma.scale_amount_min = 3.5
	p_magma.scale_amount_max = 7.0
	add_child(p_magma)
	
	# 4. Superheated Steam Column
	var p_steam = CPUParticles2D.new()
	p_steam.emitting = true
	p_steam.one_shot = true
	p_steam.explosiveness = 0.85
	p_steam.amount = 30
	p_steam.lifetime = 1.0
	p_steam.direction = Vector2(0, -1)
	p_steam.spread = 35.0
	p_steam.gravity = Vector2(0, -100)
	p_steam.initial_velocity_min = 200.0
	p_steam.initial_velocity_max = 360.0
	p_steam.color = Color(1.0, 0.9, 0.8, 0.6)
	p_steam.scale_amount_min = 4.0
	p_steam.scale_amount_max = 8.5
	add_child(p_steam)
	
	# 5. Animated Expanding Shockwave Ring
	var tw = create_tween()
	fx_radius = 6.0
	fx_alpha = 1.0
	var target_radius = 80.0 if is_explosion else 55.0
	tw.tween_property(self, "fx_radius", target_radius, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "fx_alpha", 0.0, 0.45)
	tw.tween_callback(func(): queue_redraw())

func _draw() -> void:
	if fx_alpha > 0.01:
		draw_arc(Vector2.ZERO, fx_radius, 0.0, TAU, 36, Color(1.0, 0.55, 0.1, fx_alpha), 4.5)
		draw_arc(Vector2.ZERO, fx_radius * 0.7, 0.0, TAU, 36, Color(1.0, 0.9, 0.3, fx_alpha), 2.5)
		queue_redraw()
'@ | Set-Content -Path "$innerDir\entities\MagmaSiphon.gd" -Encoding UTF8
Write-Host "Updated: $innerDir\entities\MagmaSiphon.gd" -ForegroundColor Green

Write-Host ">>> 2. Flushing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 3. Repackaging mod archive for Steam..." -ForegroundColor Cyan
if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force
}
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$zipStream = [System.IO.File]::Open($zipPath, [System.IO.FileMode]::CreateNew)
$archive   = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create)
$allFiles  = Get-ChildItem -Path $outerDir -Recurse -File

foreach ($f in $allFiles) {
    $entryName = $f.FullName.Substring($outerDir.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$zipStream.Dispose()
Write-Host "Packed archive at: $zipPath" -ForegroundColor Green

Write-Host ">>> 4. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Add MagmaSiphon particle eruptions, shockwave rings, pickaxe detonation, and thermal updraft launch"
git push origin main

Write-Host "`nDeploy complete! Restart Coal LLC to test." -ForegroundColor Green