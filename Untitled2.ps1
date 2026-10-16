cls

# ==============================================================================
# Coal LLC - Complete Generation for gareth-lost_expedition_mod
# Writes all assets, scripts, hooks, manifests, packs zip & pushes to GitHub
# ==============================================================================

$repoRoot      = "C:\Dev\coal-llc-mods"
$modName       = "gareth-lost_expedition_mod"
$outerModDir   = Join-Path $repoRoot "mods-unpacked\$modName"
$innerModDir   = Join-Path $outerModDir "mods-unpacked\$modName"
$steamModsDir  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mods"
$zipPath       = Join-Path $steamModsDir "$modName.zip"

Set-Location $repoRoot

Write-Host ">>> 1. Creating clean directory hierarchy..." -ForegroundColor Cyan
$dirs = @(
    $outerModDir,
    $innerModDir,
    (Join-Path $innerModDir "assets"),
    (Join-Path $innerModDir "entities"),
    (Join-Path $innerModDir "helpers"),
    (Join-Path $innerModDir "extensions\scenes\Interfaces\Menus"),
    (Join-Path $innerModDir "extensions\scenes\tilemaps")
)
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

Write-Host ">>> 2. Generating procedural textures..." -ForegroundColor Cyan
Add-Type -AssemblyName System.Drawing

# Card Thumbnail (256x160)
$cardBmp = New-Object System.Drawing.Bitmap 256, 160
$gCard = [System.Drawing.Graphics]::FromImage($cardBmp)
$gCard.Clear([System.Drawing.Color]::FromArgb(24, 28, 32))

$strataBrush1 = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(45, 52, 54))
$strataBrush2 = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(35, 40, 45))
$goldBrush    = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(253, 203, 110))
$cyanBrush    = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(0, 206, 201))
$bombBrush    = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 71, 87))

$gCard.FillRectangle($strataBrush1, 0, 40, 256, 50)
$gCard.FillRectangle($strataBrush2, 0, 90, 256, 70)

$stripePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(214, 48, 49)), 6
for ($x = -20; $x -lt 280; $x += 18) {
    $gCard.DrawLine($stripePen, $x, 0, ($x + 16), 16)
}
$stripePen.Dispose()

$podPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(223, 230, 233)), 2
$gCard.DrawRectangle($podPen, 108, 65, 40, 55)
$gCard.FillRectangle($cyanBrush, 114, 75, 28, 20)
$gCard.FillEllipse($goldBrush, 122, 100, 12, 12)

$gCard.FillEllipse($bombBrush, 40, 110, 10, 10)
$gCard.FillEllipse($bombBrush, 75, 130, 12, 12)
$gCard.FillEllipse($bombBrush, 190, 115, 11, 11)
$gCard.FillEllipse($bombBrush, 220, 135, 10, 10)

$cardTexturePath = Join-Path $innerModDir "assets\lost_expedition_card.png"
$cardBmp.Save($cardTexturePath, [System.Drawing.Imaging.ImageFormat]::Png)
$gCard.Dispose()
$cardBmp.Dispose()

# Cryo-Pod Sprite (32x32)
$podBmp = New-Object System.Drawing.Bitmap 32, 32
$gPod = [System.Drawing.Graphics]::FromImage($podBmp)
$gPod.Clear([System.Drawing.Color]::Transparent)

$frameBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(99, 110, 114))
$steelBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(178, 190, 195))
$glowBrush  = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(0, 206, 201))
$lightBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 234, 167))

$gPod.FillRectangle($frameBrush, 4, 2, 24, 28)
$gPod.FillRectangle($steelBrush, 6, 4, 20, 24)
$gPod.FillRectangle($glowBrush, 8, 8, 16, 12)
$gPod.FillEllipse($lightBrush, 13, 22, 6, 3)

$podTexturePath = Join-Path $innerModDir "assets\cryo_pod.png"
$podBmp.Save($podTexturePath, [System.Drawing.Imaging.ImageFormat]::Png)
$gPod.Dispose()
$podBmp.Dispose()

Write-Host ">>> 3. Writing manifest and documentation..." -ForegroundColor Cyan
$knightManifestPath = Join-Path $repoRoot "mods-unpacked\gareth-knight_class_mod\manifest.json"
$extraBlock = @{}
if (Test-Path $knightManifestPath) {
    $refJson = Get-Content $knightManifestPath -Raw | ConvertFrom-Json
    if ($refJson.extra) { $extraBlock = $refJson.extra }
}

$manifestObj = [ordered]@{
    "name"            = "lost_expedition_mod"
    "namespace"       = "gareth"
    "version_number"  = "1.0.0"
    "description"     = "Custom subterranean expedition map featuring unexploded ordnance and cryo-pod survivor rescue mechanics."
    "dependencies"    = @()
    "extra"           = $extraBlock
}
$manifestJson = $manifestObj | ConvertTo-Json -Depth 5

$readmeMd = @'
# Lost Expedition Custom Map (Coal LLC Mod)

## Overview
Adds **Lost Expedition** (Map ID 101) to Coal LLC.
- **Unexploded Ordnance (UXO):** Highly volatile demolition charges embedded in the stone. Mining triggers destructive radial detonations with visual fractures, debris, and sound.
- **Cryo-Pod Shelters:** Fortified subterranean vaults holding trapped mining personnel. Breaching a vault and opening the pod unlocks and purchases an employee level into your active workforce alongside bonus salvage cash.
- **Mineral Strata:** High-yield undulating mineral fault seams that reward deep exploration.
'@

Set-Content -Path (Join-Path $outerModDir "manifest.json") -Value $manifestJson -Encoding UTF8
Set-Content -Path (Join-Path $outerModDir "README.md") -Value $readmeMd -Encoding UTF8
Set-Content -Path (Join-Path $innerModDir "manifest.json") -Value $manifestJson -Encoding UTF8
Set-Content -Path (Join-Path $innerModDir "README.md") -Value $readmeMd -Encoding UTF8

Write-Host ">>> 4. Writing GDScript source files..." -ForegroundColor Cyan

# mod_main.gd
$modMainGd = @'
extends Node

const MOD_DIR = "gareth-lost_expedition_mod"

func _init() -> void:
	ModLoaderLog.info("Lost Expedition Mod initializing...", MOD_DIR)
	ModLoaderMod.install_script_extension("res://mods-unpacked/gareth-lost_expedition_mod/extensions/scenes/Interfaces/Menus/level_select.hooks.gd")
	ModLoaderMod.install_script_extension("res://mods-unpacked/gareth-lost_expedition_mod/extensions/scenes/tilemaps/tile_map_chunk.hooks.gd")

func _ready() -> void:
	ModLoaderLog.info("Lost Expedition Custom Map Mod (ID 101) online!", MOD_DIR)
'@
Set-Content -Path (Join-Path $innerModDir "mod_main.gd") -Value $modMainGd -Encoding UTF8

# CryoPod.gd
$cryoPodGd = @'
class_name CryoPod
extends Area2D

var in_range: bool = false
var looted: bool = false
var sprite: Sprite2D

func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 1
	collision_mask = 1
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16.0
	col.shape = shape
	add_child(col)
	
	sprite = Sprite2D.new()
	var img = Image.load_from_file("res://mods-unpacked/gareth-lost_expedition_mod/assets/cryo_pod.png")
	if img:
		sprite.texture = ImageTexture.create_from_image(img)
	add_child(sprite)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if in_range and not looted:
		if Input.is_action_just_pressed("interact"):
			rescue_worker()

func _on_body_entered(_body: Node2D) -> void:
	if not looted:
		in_range = true
		Bus.ShowInputIndicator.emit("interact", true, self)

func _on_body_exited(_body: Node2D) -> void:
	in_range = false
	Bus.ShowInputIndicator.emit("interact", false, self)

func rescue_worker() -> void:
	looted = true
	in_range = false
	Bus.ShowInputIndicator.emit("interact", false, self)
	
	var emp_mgr = Gvars.employee_manager
	if emp_mgr and emp_mgr.ALL_EMPLOYEES.size() > 0:
		var chosen_emp = emp_mgr.ALL_EMPLOYEES[randi() % emp_mgr.ALL_EMPLOYEES.size()]
		emp_mgr.purchase_employee_level(chosen_emp)
		Gvars.CashCount += 10000.0
		Game.log_message("Cryo-Pod opened! Rescued " + chosen_emp.employee_name + "! Salvaged $10,000.", Game.LogLvl.HIGH, Game.LogType.INFO)
	
	sprite.modulate = Color(0.3, 1.0, 0.4, 0.8)
'@
Set-Content -Path (Join-Path $innerModDir "entities\CryoPod.gd") -Value $cryoPodGd -Encoding UTF8

# LostExpeditionHelper.gd
$helperGd = @'
class_name LostExpeditionHelper
extends RefCounted

const EXPEDITION_LEVEL_ID: int = 101

func ensure_level_registered() -> void:
	var lvl_mgr = Gvars.level_manager
	if not lvl_mgr:
		return
	
	if not lvl_mgr.all_levels.has(EXPEDITION_LEVEL_ID):
		var custom_level = GameLevel.new()
		custom_level.level_name = "Lost Expedition"
		custom_level.level = EXPEDITION_LEVEL_ID
		custom_level.mining_scene_path = "res://scenes/Stages/MineRegion.tscn"
		custom_level.level_description = "Abandoned subterranean expedition.\nDeep strata riddled with volatile unexploded ordnance.\nCryo-shelters contain trapped mining personnel."
		custom_level.level_difficulty = GameLevel.Difficulty.HARD
		custom_level.unlock_description = ""
		
		var img = Image.load_from_file("res://mods-unpacked/gareth-lost_expedition_mod/assets/lost_expedition_card.png")
		if img:
			custom_level.level_image = ImageTexture.create_from_image(img)
		
		lvl_mgr.all_levels[EXPEDITION_LEVEL_ID] = {
			"level": custom_level,
			"is_unlocked": true
		}

func calculate_tier(pos: Vector2i) -> int:
	var depth: float = float(pos.y)
	if depth < 0.0:
		return -2
	var wave: float = sin(float(pos.x) * 0.18) * 3.0
	var tier: int = int(clamp((depth + wave) / 2.6, 0.0, 14.0))
	return tier

func tag_uxo_tiles(chunk: Node) -> void:
	var uxo: Dictionary = {}
	var total_cells: int = chunk.chunk_size * chunk.chunk_size
	for idx in range(total_cells):
		var tile_id = chunk.tiles[idx]
		if tile_id != chunk.Tiles.EMPTY and chunk.TILE_PROPERTIES[tile_id]["breakable"]:
			if randf() < 0.035:
				uxo[idx] = true
	chunk.set_meta("expedition_uxo", uxo)

func handle_tile_destroyed(chunk: Node, idx: int) -> void:
	if chunk.has_meta("expedition_uxo"):
		var uxo: Dictionary = chunk.get_meta("expedition_uxo")
		if uxo.has(idx):
			uxo.erase(idx)
			detonate_uxo(chunk, idx)

func detonate_uxo(chunk: Node, idx: int) -> void:
	var local_pos: Vector2 = chunk.map_to_local(chunk.array_to_pos(idx))
	var world_center: Vector2 = chunk.to_global(local_pos)
	var manager = chunk.get_parent()
	
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			var offset_world: Vector2 = world_center + Vector2(dx * 16.0, dy * 16.0)
			if manager and manager.has_method("damageTile"):
				manager.damageTile(offset_world, 450)

func spawn_cryo_pods(chunk: Node, current_locs: Array[Vector2i]) -> Array[Vector2i]:
	if randf() > 0.60:
		return current_locs
	
	var width: int = 3
	var height: int = 3
	var start_tile: Vector2i = Vector2i(
		randi_range(0, chunk.chunk_size - width),
		randi_range(0, chunk.chunk_size - height)
	)
	
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
				var pod_script = load("res://mods-unpacked/gareth-lost_expedition_mod/entities/CryoPod.gd")
				var pod = pod_script.new()
				pod.position = chunk.map_to_local(Vector2i(x, y))
				chunk.add_child.call_deferred(pod)
			else:
				chunk.tiles[c_idx] = chunk.chest_block_from_level(8)
				chunk.build_tile(c_idx)
	
	return current_locs
'@
Set-Content -Path (Join-Path $innerModDir "helpers\LostExpeditionHelper.gd") -Value $helperGd -Encoding UTF8

# level_select.hooks.gd
$levelSelectHooksGd = @'
func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-lost_expedition_mod/helpers/LostExpeditionHelper.gd")
	if helper_script:
		var helper = helper_script.new()
		helper.ensure_level_registered()
		if not LEVEL_ORDER.has(helper.EXPEDITION_LEVEL_ID):
			LEVEL_ORDER.append(helper.EXPEDITION_LEVEL_ID)
	chain.execute_next()
'@
Set-Content -Path (Join-Path $innerModDir "extensions\scenes\Interfaces\Menus\level_select.hooks.gd") -Value $levelSelectHooksGd -Encoding UTF8

# tile_map_chunk.hooks.gd
$tileMapChunkHooksGd = @'
func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	if Gvars.level == 101:
		var helper_script = load("res://mods-unpacked/gareth-lost_expedition_mod/helpers/LostExpeditionHelper.gd")
		if helper_script:
			var helper = helper_script.new()
			return helper.calculate_tier(pos)
	return chain.execute_next([pos])

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	chain.execute_next([noise])
	if Gvars.level == 101:
		var helper_script = load("res://mods-unpacked/gareth-lost_expedition_mod/helpers/LostExpeditionHelper.gd")
		if helper_script:
			var helper = helper_script.new()
			helper.tag_uxo_tiles(self)

func destroy_tile(chain: ModLoaderHookChain, idx: int, tile_properties: Dictionary) -> void:
	if Gvars.level == 101:
		var helper_script = load("res://mods-unpacked/gareth-lost_expedition_mod/helpers/LostExpeditionHelper.gd")
		if helper_script:
			var helper = helper_script.new()
			helper.handle_tile_destroyed(self, idx)
	chain.execute_next([idx, tile_properties])

func generate_chests(chain: ModLoaderHookChain, current_block_chest_locations: Array[Vector2i]) -> Array[Vector2i]:
	var locs: Array[Vector2i] = chain.execute_next([current_block_chest_locations])
	if Gvars.level == 101:
		var helper_script = load("res://mods-unpacked/gareth-lost_expedition_mod/helpers/LostExpeditionHelper.gd")
		if helper_script:
			var helper = helper_script.new()
			locs = helper.spawn_cryo_pods(self, locs)
	return locs
'@
Set-Content -Path (Join-Path $innerModDir "extensions\scenes\tilemaps\tile_map_chunk.hooks.gd") -Value $tileMapChunkHooksGd -Encoding UTF8

Write-Host ">>> 5. Packaging clean mod archive for Steam..." -ForegroundColor Cyan
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$zipStream = [System.IO.File]::Open($zipPath, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create)

$filesToZip = Get-ChildItem -Path $outerModDir -Recurse -File
foreach ($file in $filesToZip) {
    $relative = $file.FullName.Substring($outerModDir.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $relative) | Out-Null
}

$archive.Dispose()
$zipStream.Dispose()
Write-Host "Archive created at: $zipPath" -ForegroundColor Green

Write-Host ">>> 6. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Populate full source files for Lost Expedition mod (scripts, hooks, entities, assets)"
git push origin main

Write-Host "`nAll files are in place and pushed to GitHub. Ready to test in Coal LLC!" -ForegroundColor Green