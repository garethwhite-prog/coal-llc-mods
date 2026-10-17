cls

# ==============================================================================
# Coal LLC - Map 102: Tectonic Faultline / Magma Core Mod Scaffolding & Deploy
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

Write-Host ">>> 1. Creating mod folder structure..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path "$innerDir\assets" -Force | Out-Null
New-Item -ItemType Directory -Path "$innerDir\entities" -Force | Out-Null
New-Item -ItemType Directory -Path "$innerDir\helpers" -Force | Out-Null
New-Item -ItemType Directory -Path "$innerDir\extensions\scenes\Interfaces\Menus" -Force | Out-Null
New-Item -ItemType Directory -Path "$innerDir\extensions\scenes\tilemaps" -Force | Out-Null
New-Item -ItemType Directory -Path "$innerDir\extensions\scenes\Stages" -Force | Out-Null
New-Item -ItemType Directory -Path "$innerDir\extensions\scripts" -Force | Out-Null

Write-Host ">>> 2. Writing mod_manifest.json..." -ForegroundColor Cyan
@'
{
  "name": "gareth-tectonic_faultline_mod",
  "namespace": "gareth",
  "version_number": "1.0.0",
  "description": "Custom Map ID 102: Tectonic Faultline. Superheated strata, brittle seismic fracture seams, and high-pressure Magma Siphons.",
  "dependencies": []
}
'@ | Set-Content -Path "$innerDir\mod_manifest.json" -Encoding UTF8

Write-Host ">>> 3. Generating level select art & Magma Siphon textures..." -ForegroundColor Cyan
# Generate 160x90 volcanic molten card image
Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap 160, 90
$gfx = [System.Drawing.Graphics]::FromImage($bmp)
$brushDark = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 20, 10, 8))
$brushMagma = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 210, 65, 10))
$brushCore = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 170, 20))
$gfx.FillRectangle($brushDark, 0, 0, 160, 90)

# Molten vein patterns
for ($y = 20; $y -lt 90; $y += 6) {
    $xOffset = [Math]::Sin($y * 0.2) * 25 + 80
    $gfx.FillEllipse($brushMagma, [int]($xOffset - 25), $y, 50, 8)
    $gfx.FillEllipse($brushCore, [int]($xOffset - 12), $y + 2, 24, 4)
}
$bmp.Save("$innerDir\assets\tectonic_faultline_card.png", [System.Drawing.Imaging.ImageFormat]::Png)

# Generate Magma Siphon sprites (Active Pressure vs Vented Obsidian)
$podClosed = New-Object System.Drawing.Bitmap 32, 32
$gfxPC = [System.Drawing.Graphics]::FromImage($podClosed)
$penBorder = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 80, 40, 25), 2)
$brushLava = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 90, 10))
$brushGlow = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 215, 60))
$gfxPC.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 45, 20, 15))), 4, 2, 24, 28)
$gfxPC.DrawRectangle($penBorder, 4, 2, 24, 28)
$gfxPC.FillEllipse($brushLava, 8, 8, 16, 16)
$gfxPC.FillEllipse($brushGlow, 12, 12, 8, 8)
$podClosed.Save("$innerDir\assets\magma_siphon_active.png", [System.Drawing.Imaging.ImageFormat]::Png)

$podOpened = New-Object System.Drawing.Bitmap 32, 32
$gfxPO = [System.Drawing.Graphics]::FromImage($podOpened)
$gfxPO.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 25, 22, 25))), 4, 2, 24, 28)
$gfxPO.DrawRectangle((New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 50, 45, 55), 2)), 4, 2, 24, 28)
$gfxPO.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 12, 10, 15))), 8, 8, 16, 16)
$podOpened.Save("$innerDir\assets\magma_siphon_vented.png", [System.Drawing.Imaging.ImageFormat]::Png)
$gfx.Dispose(); $bmp.Dispose(); $gfxPC.Dispose(); $podClosed.Dispose(); $gfxPO.Dispose(); $podOpened.Dispose()

Write-Host ">>> 4. Writing entities/MagmaSiphon.gd..." -ForegroundColor Cyan
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

func _ready() -> void:
	z_index = 5
	
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
	prompt_label.text = "[E] VENT SIPHON"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.position = Vector2(-46, -26)
	prompt_label.add_theme_font_size_override("font_size", 10)
	prompt_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1, 1.0))
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
	if dist <= 38.0:
		if not in_range:
			in_range = true
			prompt_label.visible = true
			if Bus and Bus.has_signal("ShowInputIndicator"):
				Bus.ShowInputIndicator.emit("interact", true, self)
		
		if Input.is_action_just_pressed("interact"):
			vent_pressure()
	else:
		if in_range:
			in_range = false
			prompt_label.visible = false
			if Bus and Bus.has_signal("ShowInputIndicator"):
				Bus.ShowInputIndicator.emit("interact", false, self)

func vent_pressure() -> void:
	if vented:
		return
	vented = true
	in_range = false
	prompt_label.visible = false
	
	if Bus and Bus.has_signal("ShowInputIndicator"):
		Bus.ShowInputIndicator.emit("interact", false, self)
	
	# Visual state change to cooled obsidian
	if tex_vented:
		sprite.texture = tex_vented
	else:
		sprite.modulate = Color(0.2, 0.2, 0.25, 0.8)
	
	# Acoustic feedback
	var sfx_stream = load("res://assets/sound/sound effects/chestOpen.wav")
	if sfx_stream:
		var sfx = AudioStreamPlayer2D.new()
		sfx.stream = sfx_stream
		add_child(sfx)
		sfx.play()
	
	# Dispense superheated pyritic loot
	if Bus and Bus.has_signal("drop_loot"):
		Bus.drop_loot.emit(global_position + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0)), "res://resources/Items/Coal.tres", randi_range(6, 12))
	
	# Geothermal energy bounty
	var bounty: float = 12500.0 + (abs(global_position.y) * 8.0)
	Gvars.CashCount += bounty
	if Bus and Bus.has_signal("UpdateUI"):
		Bus.UpdateUI.emit()
	
	# Thermal shockwave fracture on surrounding rock
	var parent_chunk = get_parent()
	if parent_chunk and parent_chunk.get_parent() and parent_chunk.get_parent().has_method("damageTile"):
		var mgr = parent_chunk.get_parent()
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				mgr.damageTile(global_position + Vector2(dx * 16.0, dy * 16.0), 300)
	
	# High-tier thermal passive card selection
	var depth_mult: float = maxf(2.5, minf(7.0, 2.5 + abs(global_position.y) / 200.0))
	if Bus and Bus.has_signal("choose_passive"):
		Bus.choose_passive.emit(depth_mult)
	
	ModLoaderLog.info("Magma Siphon vented! Energy bounty: $" + str(int(bounty)) + " + Thermal cards offered.", "gareth-tectonic_faultline_mod")
'@ | Set-Content -Path "$innerDir\entities\MagmaSiphon.gd" -Encoding UTF8

Write-Host ">>> 5. Writing helpers/TectonicFaultlineHelper.gd..." -ForegroundColor Cyan
@'
class_name TectonicFaultlineHelper
extends RefCounted

const FAULTLINE_LEVEL_ID: int = 102

func ensure_level_registered() -> void:
	var lvl_mgr = Gvars.level_manager
	if not lvl_mgr:
		return
	
	if not lvl_mgr.all_levels.has(FAULTLINE_LEVEL_ID):
		var custom_level = GameLevel.new()
		custom_level.level_name = "Tectonic Faultline"
		custom_level.level = FAULTLINE_LEVEL_ID
		custom_level.mining_scene_path = "res://scenes/Stages/MineRegion.tscn"
		custom_level.level_description = "Unstable geothermal faultline.\nBrittle volcanic basalt and superheated magma strata.\nVent high-pressure Magma Siphons for thermal tech."
		custom_level.level_difficulty = GameLevel.Difficulty.HARD
		custom_level.unlock_description = ""
		
		var img = Image.load_from_file("res://mods-unpacked/gareth-tectonic_faultline_mod/assets/tectonic_faultline_card.png")
		if img:
			custom_level.level_image = ImageTexture.create_from_image(img)
		
		lvl_mgr.all_levels[FAULTLINE_LEVEL_ID] = {
			"level": custom_level,
			"is_unlocked": true
		}

func calculate_faultline_tier(pos: Vector2i) -> int:
	var depth: float = float(pos.y)
	if depth < 0.0:
		return -2
	
	# Dynamic jagged faultline shifts
	var wave: float = sin(float(pos.x) * 0.16) * 7.0 + cos(float(pos.x) * 0.05) * 4.0
	var effective_y: float = depth + wave
	
	if effective_y < 15.0:
		return 1  # Volcanic crust (Hard Clay/Stone)
	elif effective_y < 45.0:
		return 3  # Fractured Basalt (Hard Stone)
	elif effective_y < 120.0:
		return 8  # Shallow Magma Chamber (Hard Fire)
	elif effective_y < 300.0:
		return 9  # Molten Core (Hard Fire / Superheated)
	elif effective_y < 600.0:
		return 12 # Vitrified Obsidian (Hard Dark)
	elif effective_y < 950.0:
		return 14 # Mantle Transition (Hard Orange)
	else:
		return 18 # Abyssal Core (Hard Dark Brown)

func tag_seismic_seams(chunk: Node) -> void:
	var seams: Dictionary = {}
	var total_cells: int = chunk.chunk_size * chunk.chunk_size
	for idx in range(total_cells):
		var tile_id = chunk.tiles[idx]
		if tile_id != chunk.Tiles.EMPTY and chunk.TILE_PROPERTIES[tile_id]["breakable"]:
			# 4.5% chance of brittle seismic stress point
			if randf() < 0.045:
				seams[idx] = true
	chunk.set_meta("seismic_seams", seams)

func handle_tile_destroyed(chunk: Node, idx: int, tile_properties: Dictionary = {}) -> void:
	if chunk.has_meta("seismic_seams"):
		var seams: Dictionary = chunk.get_meta("seismic_seams")
		if seams.has(idx):
			seams.erase(idx)
			trigger_micro_tremor(chunk, idx)
	
	if tile_properties and tile_properties.get("loot", "none") != "none":
		var global_pos = chunk.to_global(chunk.map_to_local(chunk.array_to_pos(idx)))
		if randf() < 0.40:
			Bus.drop_loot.emit(global_pos + Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0)), "res://resources/Items/Coal.tres", randi_range(2, 5))

func trigger_micro_tremor(chunk: Node, idx: int) -> void:
	var world_center: Vector2 = chunk.to_global(chunk.map_to_local(chunk.array_to_pos(idx)))
	var manager = chunk.get_parent()
	if manager and manager.has_method("damageTile"):
		# Shatter adjacent brittle rock along the fault line
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				if dx != 0 or dy != 0:
					manager.damageTile(world_center + Vector2(dx * 16.0, dy * 16.0), 250)

func spawn_magma_siphons(chunk: Node, current_locs: Array[Vector2i]) -> Array[Vector2i]:
	if randf() > 0.55:
		return current_locs
	
	if "chunk_pos" in chunk and chunk.chunk_pos.y < 1:
		return current_locs
	
	var width: int = 3
	var height: int = 3
	var start_tile: Vector2i = Vector2i(
		randi_range(0, chunk.chunk_size - width),
		randi_range(0, chunk.chunk_size - height)
	)
	
	var global_cell: Vector2i = Vector2i(chunk.to_global(chunk.map_to_local(start_tile)) / 16.0)
	if global_cell.y < 16:
		return current_locs
	
	var pod_tier: int = calculate_faultline_tier(global_cell)
	var wall_tile: int = chunk.chest_block_from_level(pod_tier)
	if wall_tile == chunk.Tiles.EMPTY:
		wall_tile = chunk.Tiles.HARD_FIRE
	
	for n in range(5):
		if start_tile in current_locs:
			start_tile = Vector2i(
				randi_range(0, chunk.chunk_size - width),
				randi_range(0, chunk.chunk_size - height)
			)
	
	for x in range(start_tile.x - width, start_tile.x + width):
		for y in range(start_tile.y - height, start_tile.y + height):
			current_locs.append(Vector2i(x, y))
	
	for x in range(start_tile.x, start_tile.x + width):
		for y in range(start_tile.y, start_tile.y + height):
			var c_idx: int = chunk.pos_to_array(Vector2i(x, y))
			if (x == start_tile.x + 1) and (y == start_tile.y + 1):
				chunk.tiles[c_idx] = chunk.Tiles.EMPTY
				chunk.build_tile(c_idx)
				var siphon_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/entities/MagmaSiphon.gd")
				if siphon_script:
					var siphon = siphon_script.new()
					siphon.position = chunk.map_to_local(Vector2i(x, y))
					chunk.add_child.call_deferred(siphon)
			else:
				chunk.tiles[c_idx] = wall_tile
				chunk.build_tile(c_idx)
	
	return current_locs
'@ | Set-Content -Path "$innerDir\helpers\TectonicFaultlineHelper.gd" -Encoding UTF8

Write-Host ">>> 6. Writing hooks (level_select, tile_map_chunk, Game, management_screen)..." -ForegroundColor Cyan
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
	if helper_script:
		var helper = helper_script.new()
		helper.ensure_level_registered()
	chain.execute_next([])
'@ | Set-Content -Path "$innerDir\extensions\scenes\Interfaces\Menus\level_select.hooks.gd" -Encoding UTF8

@'
extends Object

func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	if Gvars.level == 102:
		var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
		if helper_script:
			var helper = helper_script.new()
			return helper.calculate_faultline_tier(pos)
	return chain.execute_next([pos])

func generate_chunk(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	if Gvars.level == 102:
		var chunk = chain.reference_object
		var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
		if helper_script and chunk:
			var helper = helper_script.new()
			helper.tag_seismic_seams(chunk)

func destroy_tile(chain: ModLoaderHookChain, idx: int) -> void:
	var chunk = chain.reference_object
	var tile_props: Dictionary = {}
	if chunk and idx >= 0 and idx < chunk.tiles.size():
		var tile_id = chunk.tiles[idx]
		if chunk.TILE_PROPERTIES.has(tile_id):
			tile_props = chunk.TILE_PROPERTIES[tile_id]
	
	chain.execute_next([idx])
	
	if Gvars.level == 102 and chunk:
		var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
		if helper_script:
			var helper = helper_script.new()
			helper.handle_tile_destroyed(chunk, idx, tile_props)

func generate_chests(chain: ModLoaderHookChain, current_locs: Array[Vector2i]) -> Array[Vector2i]:
	var result_locs: Array[Vector2i] = chain.execute_next([current_locs])
	if Gvars.level == 102:
		var chunk = chain.reference_object
		var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
		if helper_script and chunk:
			var helper = helper_script.new()
			result_locs = helper.spawn_magma_siphons(chunk, result_locs)
	return result_locs
'@ | Set-Content -Path "$innerDir\extensions\scenes\tilemaps\tile_map_chunk.hooks.gd" -Encoding UTF8

@'
extends Object

func change_stage(chain: ModLoaderHookChain, target: int, targetPosition: Vector2) -> void:
	var game = chain.reference_object
	var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
	if helper_script:
		var helper = helper_script.new()
		helper.ensure_level_registered()

	if target == 2 and Gvars.level == 102:
		if game and "MINE_REGION" in game:
			game.target_stage = game.MINE_REGION

	chain.execute_next([target, targetPosition])

	if game:
		if game.has_node("ColorRect"):
			game.get_node("ColorRect").mouse_filter = Control.MOUSE_FILTER_IGNORE
		game.visible = false
		if Gvars.profession:
			if not ("player" in game) or game.player == null:
				var player_node = game.get_tree().get_first_node_in_group("player")
				if player_node:
					game.player = player_node
			if "player" in game and game.player:
				game.player.set("profession", Gvars.profession)
'@ | Set-Content -Path "$innerDir\extensions\scripts\Game.hooks.gd" -Encoding UTF8

@'
extends Object

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	if Gvars.level == 102:
		var ms = chain.reference_object
		if ms and "equipment_shop" in ms and ms.equipment_shop:
			# Allows pickaxes, heavy drills, and tectonic equipment; filters out delicate cold/water items
			var allowed := ["pickaxe", "drill", "tectonic_fracker", "item_filter", "increase_stack_size", "ladder", "whistle", "collector_whistle", "mining_whistle"]
			for card in ms.equipment_shop.get_children():
				if "item" in card and card.item:
					var itype: String = str(card.item.itemType).to_lower()
					if not allowed.has(itype):
						card.visible = false
'@ | Set-Content -Path "$innerDir\extensions\scenes\Stages\management_screen.hooks.gd" -Encoding UTF8

Write-Host ">>> 7. Writing mod_main.gd..." -ForegroundColor Cyan
@'
extends Node

const MOD_DIR := "gareth-tectonic_faultline_mod"

func _init() -> void:
	ModLoaderLog.info("Tectonic Faultline Mod initializing...", MOD_DIR)
	var mod_dir_path: String = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/Menus/level_select.gd",
		mod_dir_path.path_join("extensions/scenes/Interfaces/Menus/level_select.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/tilemaps/tile_map_chunk.gd",
		mod_dir_path.path_join("extensions/scenes/tilemaps/tile_map_chunk.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/Game.gd",
		mod_dir_path.path_join("extensions/scripts/Game.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Stages/management_screen.gd",
		mod_dir_path.path_join("extensions/scenes/Stages/management_screen.hooks.gd")
	)

func _ready() -> void:
	var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
	if helper_script:
		var helper = helper_script.new()
		helper.ensure_level_registered()
	ModLoaderLog.info("Tectonic Faultline Custom Map Mod (ID 102) online!", MOD_DIR)
'@ | Set-Content -Path "$innerDir\mod_main.gd" -Encoding UTF8

Write-Host ">>> 8. Flushing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 9. Packaging mod archive for Steam..." -ForegroundColor Cyan
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

Write-Host ">>> 10. Git committing and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Create and deploy Map ID 102: Tectonic Faultline with Magma Siphons and volcanic strata"
git push origin main

Write-Host "`nMap 102 deployed cleanly! Launch Coal LLC to test." -ForegroundColor Green