cls

# ==============================================================================
# Coal LLC - Upgrade Dump-Context & Fix Tectonic Faultline Level Registration
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$modName    = "gareth-tectonic_faultline_mod"
$outerDir   = "$repo\mods-unpacked\$modName"
$innerDir   = "$outerDir\mods-unpacked\$modName"
$zipPath    = "$steamMods\$modName.zip"
$hookZip    = "$steamRoot\mod-hooks.zip"
$helperPath = "$innerDir\helpers\TectonicFaultlineHelper.gd"
$hookPath   = "$innerDir\extensions\scenes\Interfaces\Menus\level_select.hooks.gd"

Set-Location $repo

Write-Host ">>> 1. Upgrading Dump-Context.ps1 with error/warning and active mod extraction..." -ForegroundColor Cyan
@'
cls
$repoRoot = "C:\Dev\coal-llc-mods"
$appDataGodot = [System.IO.Path]::Combine($env:APPDATA, "Godot\app_userdata\Coal LLC")
$outputFile = [System.IO.Path]::Combine($repoRoot, "context.txt")

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("=== GIT STATUS ===")
Push-Location $repoRoot$gitStatus = git status --short
foreach ($line in$gitStatus) { [void]$sb.AppendLine($line) }

[void]$sb.AppendLine("`n=== RECENT COMMITS ===")
$gitLog = git log -n 3 --oneline
foreach ($line in $gitLog) { [void]$sb.AppendLine($line) }
Pop-Location

$logPath = [System.IO.Path]::Combine($appDataGodot, "logs\godot.log")
if (Test-Path $logPath) {
    $allLogLines = Get-Content $logPath
    
    # 1. Capture every error, crash, and warning across the whole session
    $errorLines = $allLogLines | Where-Object { 
        $_ -match "(SCRIPT ERROR|ERROR:|Compile Error|Parse Error|Failed to load script|Invalid call|Invalid access)" 
    }
    
    [void]$sb.AppendLine("`n=== SESSION ERRORS & WARNINGS ($($errorLines.Count) found) ===")
    if ($errorLines.Count -gt 0) {
        foreach ($line in ($errorLines | Select-Object -Last 30)) { [void]$sb.AppendLine($line) }
    } else {
        [void]$sb.AppendLine("None detected.")
    }

    # 2. Capture all log entries matching the mod currently being modified
    $activeModLines = $allLogLines \vert{} Where-Object {$_ -match "tectonic_faultline" }
    [void]$sb.AppendLine("`n=== ACTIVE MOD LOG ENTRIES ($($activeModLines.Count) found) ===")
    if ($activeModLines.Count -gt 0) {
        foreach ($line in ($activeModLines | Select-Object -Last 20)) { [void]$sb.AppendLine($line) }
    } else {
        [void]$sb.AppendLine("None detected.")
    }

    # 3. Trailing log context
    [void]$sb.AppendLine("`n=== LOG TAIL (LAST 30 LINES) ===")
    $tailLines =$allLogLines | Select-Object -Last 30
    foreach ($line in$tailLines) { [void]$sb.AppendLine($line) }
}

[System.IO.File]::WriteAllText($outputFile,$sb.ToString(), [System.Text.Encoding]::UTF8)
Set-Clipboard -Value $sb.ToString()
Write-Host "[+] Enhanced context collected in context.txt AND copied to clipboard!" -ForegroundColor Green
Write-Host "    Press Ctrl+V in the chat to share your project status." -ForegroundColor Yellow
'@ | Set-Content -Path "$repo\Dump-Context.ps1" -Encoding UTF8
Write-Host "Updated: $repo\Dump-Context.ps1" -ForegroundColor Green

Write-Host "`n>>> 2. Rewriting TectonicFaultlineHelper.gd (clean compilation, GameLevel registration)..." -ForegroundColor Cyan
@'
class_name TectonicFaultlineHelper
extends RefCounted

const FAULTLINE_LEVEL_ID: int = 102
const CHUNK_SIZE: int = 16

static func is_faultline_level() -> bool:
	if Gvars and "chosen_level" in Gvars and Gvars.chosen_level == FAULTLINE_LEVEL_ID:
		return true
	if Gvars and "current_level" in Gvars and Gvars.current_level == FAULTLINE_LEVEL_ID:
		return true
	return false

func ensure_level_registered() -> void:
	register_faultline_level()

static func register_faultline_level() -> void:
	if not Gvars:
		return
	
	# Register into Gvars.level_manager.all_levels (the primary source of truth for level_select.gd)
	if "level_manager" in Gvars and Gvars.level_manager and ("all_levels" in Gvars.level_manager):
		var lvl_mgr = Gvars.level_manager
		if not lvl_mgr.all_levels.has(FAULTLINE_LEVEL_ID):
			var custom_level = GameLevel.new()
			custom_level.level_name = "Tectonic Faultline"
			custom_level.level = FAULTLINE_LEVEL_ID
			custom_level.mining_scene_path = "res://scenes/Stages/MineRegion.tscn"
			custom_level.level_description = "Seismic faultline with superheated vents, magma fissures, and elemental chambers.\n\nElemental pods contain explosive fluids and geothermal updrafts."
			custom_level.level_difficulty = GameLevel.Difficulty.HARD
			custom_level.unlock_description = ""
			
			var preview_path = "res://mods-unpacked/gareth-tectonic_faultline_mod/assets/magma_siphon_active.png"
			if ResourceLoader.exists(preview_path):
				var img = Image.load_from_file(preview_path)
				if img:
					custom_level.level_image = ImageTexture.create_from_image(img)
			
			lvl_mgr.all_levels[FAULTLINE_LEVEL_ID] = {
				"level": custom_level,
				"is_unlocked": true
			}
	
	# Metadata backups in Gvars
	if "level_info" in Gvars and Gvars.level_info is Dictionary:
		if not Gvars.level_info.has(FAULTLINE_LEVEL_ID):
			Gvars.level_info[FAULTLINE_LEVEL_ID] = {
				"name": "Tectonic Faultline",
				"description": "Seismic faultline with superheated vents, magma fissures, and elemental chambers.",
				"depth": 1400,
				"cost": 0,
				"unlocked": true
			}
	
	if "level_unlocked" in Gvars and Gvars.level_unlocked is Dictionary:
		if not Gvars.level_unlocked.has(FAULTLINE_LEVEL_ID):
			Gvars.level_unlocked[FAULTLINE_LEVEL_ID] = true
	
	if "level_highscores" in Gvars and Gvars.level_highscores is Dictionary:
		if not Gvars.level_highscores.has(FAULTLINE_LEVEL_ID):
			Gvars.level_highscores[FAULTLINE_LEVEL_ID] = 0
	
	if "level_scores" in Gvars and Gvars.level_scores is Dictionary:
		if not Gvars.level_scores.has(FAULTLINE_LEVEL_ID):
			Gvars.level_scores[FAULTLINE_LEVEL_ID] = 0

static func calculate_faultline_tier(global_cell: Vector2i) -> int:
	var y_tile: int = abs(global_cell.y)
	if y_tile < 24:
		return 1
	elif y_tile < 48:
		return 2
	elif y_tile < 80:
		return 3
	elif y_tile < 120:
		return 4
	elif y_tile < 170:
		return 5
	elif y_tile < 230:
		return 6
	elif y_tile < 300:
		return 7
	else:
		return min(12, 8 + int((y_tile - 300) / 80))

static func pick_faultline_block(chunk: Node, global_cell: Vector2i, noise: FastNoiseLite) -> int:
	var tier: int = calculate_faultline_tier(global_cell)
	
	var rift_noise: float = abs(noise.get_noise_2d(float(global_cell.x) * 4.5, float(global_cell.y) * 1.2))
	if rift_noise < 0.09 and global_cell.y > 10:
		return chunk.Tiles.EMPTY
	
	var fissure_noise: float = noise.get_noise_2d(float(global_cell.x) * 2.8 + 50.0, float(global_cell.y) * 2.8)
	if fissure_noise > 0.42 and global_cell.y > 18:
		return chunk.Tiles.HARD_FIRE
	
	var base_tile: int = chunk.chest_block_from_level(tier)
	if base_tile == chunk.Tiles.EMPTY:
		base_tile = chunk.Tiles.HARD_FIRE
	return base_tile

static func spawn_magma_siphons(chunk: Node, current_locs: Array[Vector2i]) -> Array[Vector2i]:
	if randf() > 0.60:
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
	
	# Reinforced vault walls (+2 tier harder rock)
	var pod_tier: int = calculate_faultline_tier(global_cell)
	var wall_tier: int = min(pod_tier + 2, 12)
	var wall_tile: int = chunk.chest_block_from_level(wall_tier)
	if wall_tile == chunk.Tiles.EMPTY:
		if global_cell.y > 50:
			wall_tile = chunk.Tiles.HARD_DARK
		elif global_cell.y > 25:
			wall_tile = chunk.Tiles.HARD_FIRE
		else:
			wall_tile = chunk.Tiles.HARD_ORANGE
	
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
			var local_coord: Vector2i = Vector2i(x, y)
			if x == start_tile.x or x == start_tile.x + width - 1 or y == start_tile.y or y == start_tile.y + height - 1:
				chunk.tiles[chunk.coord_to_array(local_coord)] = wall_tile
			else:
				chunk.tiles[chunk.coord_to_array(local_coord)] = chunk.Tiles.EMPTY
	
	var SiphonScene = load("res://mods-unpacked/gareth-tectonic_faultline_mod/entities/MagmaSiphon.gd")
	if SiphonScene:
		var siphon = SiphonScene.new()
		var center_tile: Vector2i = Vector2i(start_tile.x + 1, start_tile.y + 1)
		siphon.position = chunk.map_to_local(center_tile)
		
		var roll = randf()
		if roll < 0.40:
			siphon.set_element("fire")
		elif roll < 0.70:
			siphon.set_element("water")
		else:
			siphon.set_element("poison")
		
		chunk.add_child(siphon)
	
	return current_locs
'@ | Set-Content -Path $helperPath -Encoding UTF8
Write-Host "Updated: $helperPath" -ForegroundColor Green

Write-Host "`n>>> 3. Rewriting level_select.hooks.gd (matching LostExpedition pattern)..." -ForegroundColor Cyan
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
	if helper_script:
		var helper = helper_script.new()
		helper.ensure_level_registered()
		var ls = chain.reference_object
		if ls and ("LEVEL_ORDER" in ls):
			if not ls.LEVEL_ORDER.has(helper.FAULTLINE_LEVEL_ID):
				ls.LEVEL_ORDER.append(helper.FAULTLINE_LEVEL_ID)
	chain.execute_next([])
'@ | Set-Content -Path $hookPath -Encoding UTF8
Write-Host "Updated: $hookPath" -ForegroundColor Green

Write-Host "`n>>> 4. Flushing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 5. Repackaging mod archive for Steam..." -ForegroundColor Cyan
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

Write-Host ">>> 6. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Upgrade Dump-Context.ps1 log parser and fix Tectonic Faultline level registration"
git push origin main

Write-Host "`nDeploy complete! Launch Coal LLC to test." -ForegroundColor Green