$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. Restoring Diagonal Map Preview Icon ---"
$diagHelperPath = "$repoRoot\mods-unpacked\gareth-diagonal_map_mod\mods-unpacked\gareth-diagonal_map_mod\helpers\DiagonalMapHelper.gd"
$diagScript = @"
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
$diagScript | Set-Content -Path $diagHelperPath -Encoding UTF8

Write-Output "--- 2. Restoring Living Canvas Browse Button ---"
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
				if "game_level" in card and card.game_level and card.game_level.level == 103:
					var container = card.get_node_or_null("MarginContainer/VBoxContainer")
					if container and not container.has_node("CanvasImagePickerBtn"):
						var btn = Button.new()
						btn.name = "CanvasImagePickerBtn"
						btn.text = "Browse Custom Canvas..."
						var helper = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
						if helper:
							btn.pressed.connect(Callable(helper.new(), "_on_browse_pressed"))
						container.add_child(btn)
"@
$lcScript | Set-Content -Path $lcHookPath -Encoding UTF8

Write-Output "--- 3. Fixing Coroutines in ALL Map Mods ---"
$mapMods = @("gareth-diagonal_map_mod", "gareth-living_canvas_mod", "gareth-lost_expedition_mod", "gareth-abyssal_trench_mod", "gareth-tectonic_faultline_mod")
foreach ($mod in $mapMods) {
    $ghPath = "$repoRoot\mods-unpacked\$mod\mods-unpacked\$mod\extensions\scripts\Game.hooks.gd"
    if (Test-Path $ghPath) {
        $lines = Get-Content $ghPath
        $inChangeStage = $false
        for ($i=0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "func change_stage") { $inChangeStage = $true }
            elseif ($lines[$i] -match "^func ") { $inChangeStage = $false }
            
            if ($inChangeStage -and $lines[$i] -match "chain\.execute_next" -and $lines[$i] -notmatch "await") {
                $lines[$i] = $lines[$i] -replace "chain\.execute_next", "await chain.execute_next"
            }
        }
        $lines | Set-Content $ghPath -Encoding UTF8
        Write-Output "Patched async Coroutine in Game.hooks.gd for $mod"
    }
}

Write-Output "--- 4. Repacking Map Mods ---"
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force }

Add-Type -AssemblyName System.IO.Compression.FileSystem
foreach ($mod in $mapMods) {
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
git commit -m "Fix: Fully enforce async change_stage across all map mods to prevent camera break, and safely inject Missing Canvas/Diagonal UI."
git push origin main
Write-Output "All complete!"