$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Write-Output "--- 1. Enforcing File Locks & Cache Cleanup ---"
Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
Start-Sleep -Seconds 2

$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { 
    Remove-Item $hooksZip -Force -ErrorAction Stop 
    Write-Output "Deleted locked mod-hooks.zip successfully."
}

Write-Output "`n--- 2. Patching Map 105 Transition ---"
$gameHookPath = Join-Path $repoRoot "mods-unpacked\gareth-diagonal_map_mod\mods-unpacked\gareth-diagonal_map_mod\extensions\scripts\Game.hooks.gd"
$gameHookScript = @"
extends Object

func change_stage(chain: ModLoaderHookChain, target, pos: Vector2) -> void:
	var game = chain.reference_object
	if int(target) == 2 and Gvars and Gvars.get("level") == 105:
		if is_instance_valid(game):
			game.target_stage = load("res://scenes/Stages/MineRegion.tscn")
	
	await chain.execute_next([target, pos])
"@
$gameHookScript | Set-Content -Path $gameHookPath -Encoding UTF8
Write-Output "Patched Map 105 Game.hooks.gd"

Write-Output "`n--- 3. Patching Living Canvas (103) UI ---"
$canvasModDir = Join-Path $repoRoot "mods-unpacked\gareth-living_canvas_mod"
$lsHook = Get-ChildItem -Path $canvasModDir -Recurse -Filter "*level_select.hooks.gd" | Select-Object -First 1
if ($lsHook) {
    $lsHookScript = @"
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var ls = chain.reference_object
	if ls and ("LEVEL_ORDER" in ls):
		if not ls.LEVEL_ORDER.has(103):
			ls.LEVEL_ORDER.append(103)
	
	await chain.execute_next([])
	
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
						var helper = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/canvas_helper.gd")
						if helper:
							btn.pressed.connect(Callable(helper.new(), "_on_browse_pressed"))
						container.add_child(btn)
"@
    $lsHookScript | Set-Content -Path $lsHook.FullName -Encoding UTF8
    Write-Output "Injected CanvasImagePickerBtn into $($lsHook.Name)"
}

Write-Output "`n--- 4. Patching Amazon Delivery Null Crash ---"
$scrapModDir = Join-Path $repoRoot "mods-unpacked\gareth-scrap_and_delivery_mod"
$gdFiles = Get-ChildItem -Path $scrapModDir -Recurse -Filter "*.gd"
foreach ($file in $gdFiles) {
    $content = Get-Content $file.FullName
    $modified = $false
    for ($i=0; $i -lt $content.Count; $i++) {
        if ($content[$i] -match "^(\s*)([\w]+)\.itemBuyPrice\s*=") {
            $indent = $matches[1]
            $varName = $matches[2]
            $content[$i] = "${indent}if is_instance_valid(${varName}) and `"itemBuyPrice`" in ${varName}:`n" + $content[$i]
            $modified = $true
        }
    }
    if ($modified) { 
        $content | Set-Content $file.FullName -Encoding UTF8 
        Write-Output "Guarded itemBuyPrice crash in $($file.Name)"
    }
}

Write-Output "`n--- 5. Repacking and Deploying Workstreams ---"
$targetMods = @("gareth-diagonal_map_mod", "gareth-living_canvas_mod", "gareth-scrap_and_delivery_mod")
Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($mod in $targetMods) {
    $srcDir = Join-Path $repoRoot "mods-unpacked\$mod"
    if (!(Test-Path $srcDir)) { continue }
    
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
    
    if (Test-Path $steamZip) {
        Copy-Item -Path $downZip -Destination $steamZip -Force
        Write-Output "Deployed $mod to runtime."
    }
}

Write-Output "`n--- Committing to Git ---"
git add -A
git commit -m "Fix: Concurrent patches for Map 105 crash, Canvas UI button, Amazon Delivery null crash, and ModLoader file lock cleanup (Syntax Fixed)."
git push origin main