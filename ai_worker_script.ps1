$repoRoot = "C:\Dev\coal-llc-mods"
$steamMods = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mods"
$downMods = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\downloaded_mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
Set-Location -Path $repoRoot

# Ensure game and Godot are closed
Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- Patching Diagonal Map Game.hooks.gd ---"
$gameHookPath = Join-Path $repoRoot "mods-unpacked\gareth-diagonal_map_mod\mods-unpacked\gareth-diagonal_map_mod\extensions\scripts\Game.hooks.gd"

$gameHookScript = @"
extends Object

func change_stage(chain: ModLoaderHookChain, target, pos: Vector2) -> void:
	var game = chain.reference_object
	if int(target) == 2 and Gvars and Gvars.get("level") == 105:
		if is_instance_valid(game):
			if "MINE_REGION" in game and game.MINE_REGION:
				game.target_stage = game.MINE_REGION
			else:
				game.target_stage = load("res://scenes/Stages/MineRegion.tscn")
	
	await chain.execute_next([target, pos])
"@
$gameHookScript | Set-Content -Path $gameHookPath -Encoding UTF8

Write-Output "--- Repacking and Deploying Diagonal Map ---"
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force }

$mod = "gareth-diagonal_map_mod"
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

if (Test-Path $steamZip) {
    Copy-Item -Path $downZip -Destination $steamZip -Force
    Write-Output "Deployed $mod.zip to runtime mods."
}

Write-Output "`n--- Discovery: Living Canvas Hooks ---"
$canvasDir = Join-Path $repoRoot "mods-unpacked\gareth-living_canvas_mod"
if (Test-Path $canvasDir) {
    Get-ChildItem -Path $canvasDir -Recurse -Filter "*.hooks.gd" | ForEach-Object {
        Write-Output "`nFILE: $($_.FullName)"
        Get-Content $_.FullName
    }
} else {
    Write-Output "Living Canvas mod directory not found at $canvasDir"
}

Write-Output "`n--- Committing to Git ---"
git add -A
git commit -m "Fix: Make change_stage hook async and properly set target_stage to avoid crash on Map 105 load."
git push origin main