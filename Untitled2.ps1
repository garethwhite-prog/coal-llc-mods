cls
`
# ==============================================================================
# Coal LLC - Fix mod_main.gd (2-arg install_script_hooks), Flush Hooks & Deploy
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

Write-Host ">>> 1. Writing corrected mod_main.gd with 2 arguments..." -ForegroundColor Cyan

$modMainGd = @'
extends Node

const MOD_DIR := "gareth-lost_expedition_mod"

func _init() -> void:
	ModLoaderLog.info("Lost Expedition Mod initializing...", MOD_DIR)
	var mod_dir_path: String = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/Menus/level_select.gd",
		mod_dir_path.path_join("extensions/scenes/Interfaces/Menus/level_select.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/tilemaps/tile_map_chunk.gd",
		mod_dir_path.path_join("extensions/scenes/tilemaps/tile_map_chunk.hooks.gd")
	)

func _ready() -> void:
	ModLoaderLog.info("Lost Expedition Custom Map Mod (ID 101) online!", MOD_DIR)
'@

Set-Content -Path (Join-Path $innerModDir "mod_main.gd") -Value $modMainGd -Encoding UTF8
Write-Host "mod_main.gd updated." -ForegroundColor Green

Write-Host ">>> 2. Deleting cached mod-hooks.zip to force ModHookPacker rebuild..." -ForegroundColor Cyan
if (Test-Path $hookZipPath) {
    Remove-Item -Path $hookZipPath -Force
    Write-Host "mod-hooks.zip deleted." -ForegroundColor Green
} else {
    Write-Host "mod-hooks.zip was not present." -ForegroundColor Yellow
}

Write-Host ">>> 3. Re-packaging $modName.zip for Steam..." -ForegroundColor Cyan
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
Write-Host "Re-packaged cleanly to $zipPath" -ForegroundColor Green

Write-Host ">>> 4. Updating SESSION_PROMPT.md with verified signature..." -ForegroundColor Cyan
$sessionPromptPath = Join-Path $repoRoot "SESSION_PROMPT.md"
$sessionContent = Get-Content $sessionPromptPath -Raw

$updatedSection3 = @"
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
5. ModLoader Hook Limitations & install_script_hooks Signature:
   Hook scripts (*.hooks.gd) must be registered via `ModLoaderMod.install_script_hooks(vanilla_script_path: String, hook_script_path: String)`.
   Calling with only 1 argument triggers a GDScript parse error ("Too few arguments for install_script_hooks() call. Expected at least 2 but received 1").
   Hook scripts must ONLY contain method names that exist directly on the vanilla target script. Any custom helper functions defined at script root will trigger parse errors. Delegate custom logic to RefCounted helper classes.
   When registering hooks for a vanilla script not previously hooked, delete `mod-hooks.zip` from the Steam game root so ModHookPacker rebuilds the preprocessor archive on startup.
"@

# Replace section 3 in SESSION_PROMPT.md
$sessionContent = $sessionContent -replace "(?s)## 3\. Godot 4 & ModLoader Engine Quirks.*?(?=## 4\. Economy)", $updatedSection3
Set-Content -Path $sessionPromptPath -Value $sessionContent -Encoding UTF8
Write-Host "SESSION_PROMPT.md updated." -ForegroundColor Green

Write-Host ">>> 5. Git Staging, Commit & Push..." -ForegroundColor Cyan
git add -A
git commit -m "Fix install_script_hooks 2-arg signature for Lost Expedition mod and flush hook cache"
git push origin main

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "All tasks completed! Start Coal LLC to test." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green