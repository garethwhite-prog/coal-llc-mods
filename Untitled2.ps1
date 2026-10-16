cls
`
# ==============================================================================
# Coal LLC - Fix Lost Expedition Hooks (extends Object & chain.reference_object)
# ==============================================================================

$repoRoot      = "C:\Dev\coal-llc-mods"
$modName       = "gareth-lost_expedition_mod"
$outerModDir   = Join-Path $repoRoot "mods-unpacked\$modName"
$innerModDir   = Join-Path $outerModDir "mods-unpacked\$modName"
$steamRoot     = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamModsDir  = Join-Path $steamRoot "mods"
$zipPath       = Join-Path $steamModsDir "$modName.zip"
$hookZipPath   = Join-Path $steamRoot "mod-hooks.zip"

Set-Location $repoRoot

Write-Host ">>> 1. Patching level_select.hooks.gd (extends Object & chain.reference_object)..." -ForegroundColor Cyan

$levelSelectHooksGd = @'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-lost_expedition_mod/helpers/LostExpeditionHelper.gd")
	if helper_script:
		var helper = helper_script.new()
		helper.ensure_level_registered()
		var ls = chain.reference_object
		if ls and ("LEVEL_ORDER" in ls):
			if not ls.LEVEL_ORDER.has(helper.EXPEDITION_LEVEL_ID):
				ls.LEVEL_ORDER.append(helper.EXPEDITION_LEVEL_ID)
	chain.execute_next([])
'@

$levelSelectHooksPath = Join-Path $innerModDir "extensions\scenes\Interfaces\Menus\level_select.hooks.gd"
Set-Content -Path $levelSelectHooksPath -Value $levelSelectHooksGd -Encoding UTF8
Write-Host "Updated: $levelSelectHooksPath" -ForegroundColor Green

Write-Host ">>> 2. Patching tile_map_chunk.hooks.gd (extends Object & chain.reference_object)..." -ForegroundColor Cyan

$tileMapChunkHooksGd = @'
extends Object

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
		var chunk = chain.reference_object
		if chunk:
			var helper_script = load("res://mods-unpacked/gareth-lost_expedition_mod/helpers/LostExpeditionHelper.gd")
			if helper_script:
				var helper = helper_script.new()
				helper.tag_uxo_tiles(chunk)

func destroy_tile(chain: ModLoaderHookChain, idx: int, tile_properties: Dictionary) -> void:
	if Gvars.level == 101:
		var chunk = chain.reference_object
		if chunk:
			var helper_script = load("res://mods-unpacked/gareth-lost_expedition_mod/helpers/LostExpeditionHelper.gd")
			if helper_script:
				var helper = helper_script.new()
				helper.handle_tile_destroyed(chunk, idx)
	chain.execute_next([idx, tile_properties])

func generate_chests(chain: ModLoaderHookChain, current_block_chest_locations: Array[Vector2i]) -> Array[Vector2i]:
	var locs: Array[Vector2i] = chain.execute_next([current_block_chest_locations])
	if Gvars.level == 101:
		var chunk = chain.reference_object
		if chunk:
			var helper_script = load("res://mods-unpacked/gareth-lost_expedition_mod/helpers/LostExpeditionHelper.gd")
			if helper_script:
				var helper = helper_script.new()
				locs = helper.spawn_cryo_pods(chunk, locs)
	return locs
'@

$tileMapChunkHooksPath = Join-Path $innerModDir "extensions\scenes\tilemaps\tile_map_chunk.hooks.gd"
Set-Content -Path $tileMapChunkHooksPath -Value $tileMapChunkHooksGd -Encoding UTF8
Write-Host "Updated: $tileMapChunkHooksPath" -ForegroundColor Green

Write-Host ">>> 3. Hardening CryoPod.gd and LostExpeditionHelper.gd..." -ForegroundColor Cyan

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
		if Bus and Bus.has_signal("ShowInputIndicator"):
			Bus.ShowInputIndicator.emit("interact", true, self)

func _on_body_exited(_body: Node2D) -> void:
	in_range = false
	if Bus and Bus.has_signal("ShowInputIndicator"):
		Bus.ShowInputIndicator.emit("interact", false, self)

func rescue_worker() -> void:
	looted = true
	in_range = false
	if Bus and Bus.has_signal("ShowInputIndicator"):
		Bus.ShowInputIndicator.emit("interact", false, self)
	
	var emp_mgr = Gvars.employee_manager
	if emp_mgr and emp_mgr.ALL_EMPLOYEES.size() > 0:
		var chosen_emp = emp_mgr.ALL_EMPLOYEES[randi() % emp_mgr.ALL_EMPLOYEES.size()]
		emp_mgr.purchase_employee_level(chosen_emp)
		Gvars.CashCount += 10000.0
		ModLoaderLog.info("Cryo-Pod opened! Rescued " + chosen_emp.employee_name + "! Salvaged $10,000.", "gareth-lost_expedition_mod")
	
	if sprite:
		sprite.modulate = Color(0.3, 1.0, 0.4, 0.8)
'@
Set-Content -Path (Join-Path $innerModDir "entities\CryoPod.gd") -Value $cryoPodGd -Encoding UTF8

Write-Host ">>> 4. Deleting mod-hooks.zip to trigger bytecode re-instrumentation..." -ForegroundColor Cyan
if (Test-Path $hookZipPath) {
	Remove-Item -Path $hookZipPath -Force
	Write-Host "mod-hooks.zip deleted." -ForegroundColor Green
}

Write-Host ">>> 5. Repackaging $modName.zip for Steam..." -ForegroundColor Cyan
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
Write-Host "Re-packaged cleanly at: $zipPath" -ForegroundColor Green

Write-Host ">>> 6. Updating SESSION_PROMPT.md..." -ForegroundColor Cyan
$sessionPromptPath = Join-Path $repoRoot "SESSION_PROMPT.md"
$sessionContent = Get-Content $sessionPromptPath -Raw

$updatedSection3 = @'
## 3. Godot 4 & ModLoader Engine Quirks
1. Runtime Loose PNG Loading:
   In exported Godot 4 builds, loose .png files placed in mod directories are not imported as .ctex resources. Calling ResourceLoader.load() or load() on loose images returns null. Always use runtime image decoding:
     var img = Image.load_from_file(path)
     if img:
         item.itemTexture = ImageTexture.create_from_image(img)
2. AtlasTexture Overrides:
   Pre-existing .tres item resources with baked AtlasTextures (such as Tactical Nukes and Neutron Bombs) will continue displaying default yellow sprites unless item.itemTexture is explicitly overwritten with an ImageTexture at runtime.
3. Coordinate Transforms (Godot 4.3+):
   TileMapManager extends TileMapLayer. Coordinate inspection methods (e.g. get_cell_atlas_coords, is_tile_breakable) take 1 argument (Vector2i), NOT 2. When raycasting from world coordinates, always transform to map space using:
     var local_pos: Vector2 = tilemap.to_local(world_pos)
     var cell: Vector2i = tilemap.local_to_map(local_pos)
4. Visual Tile Damage vs Silent Damage:
   `tilemap.damageTileCoords(cell, dmg)` applies damage silently to internal block health data without audio, cracks, or debris. For full feedback (breaking sounds, fracture overlays, particle bursts), use:
     tilemap.damageTile(world_pos, dmg)
5. ModLoader Hook Rules:
   - Hook scripts (*.hooks.gd) MUST begin with `extends Object` on line 1. Omitting this triggers a fatal assertion ("Scripts holding mod hooks should always extend Object").
   - Access the hooked vanilla instance via `chain.reference_object` (NEVER `chain.reference`, which calls RefCounted.reference() and evaluates to a Callable).
   - Hook scripts must ONLY contain method names that exist directly on the vanilla target script. Any custom helper functions defined at script root will trigger parse errors. Delegate custom logic to RefCounted helper classes.
   - Register hook scripts via `ModLoaderMod.install_script_hooks(vanilla_script_path: String, hook_script_path: String)`. Both arguments are strictly required.
   - When adding a hook for a vanilla script not previously hooked, delete `mod-hooks.zip` from the Steam game directory to force ModHookPacker to re-instrument the target script on startup.
'@

$sessionContent = $sessionContent -replace "(?s)## 3\. Godot 4 & ModLoader Engine Quirks.*?(?=## 4\. Economy)", $updatedSection3
Set-Content -Path $sessionPromptPath -Value $sessionContent -Encoding UTF8
Write-Host "SESSION_PROMPT.md updated." -ForegroundColor Green

Write-Host ">>> 7. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Fix ModLoader hook inheritance (extends Object) and chain.reference_object scoping"
git push origin main

Write-Host "`nAll tasks completed! Start Coal LLC to test." -ForegroundColor Green