Clear-Host;

# ==============================================================================
# Coal LLC - Deploy Hardware Acceleration & Multi-Threading Mod
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

$modName    = "gareth-hardware_booster_mod"
$outerDir   = "$repo\mods-unpacked\$modName"
$innerDir   = "$outerDir\mods-unpacked\$modName"
$zipPath    = "$steamMods\$modName.zip"

Set-Location $repo

Write-Host ">>> 1. Creating mod directories..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path "$innerDir\extensions\scenes\tilemaps" -Force | Out-Null

Write-Host ">>> 2. Writing manifest.json..." -ForegroundColor Cyan
@'
{
  "name": "hardware_booster_mod",
  "namespace": "gareth",
  "version_number": "1.0.0",
  "description": "Accelerates terrain generation and heavy calculations using Godot 4 WorkerThreadPool across multi-core CPUs.",
  "website_url": "https://github.com/garethwhite-prog/coal-llc-mods",
  "dependencies": [],
  "extra": {
    "godot": {
      "display_name": "Hardware Multi-Thread Booster",
      "category": "Performance",
      "authors": ["Gareth White"],
      "compatible_mod_loader_version": ["7.0.1"],
      "compatible_game_version": ["1.4.1.1"]
    }
  }
}
'@ | Set-Content -Path "$outerDir\manifest.json" -Encoding UTF8
Copy-Item -Path "$outerDir\manifest.json" -Destination "$innerDir\manifest.json" -Force

Write-Host ">>> 3. Writing mod_main.gd..." -ForegroundColor Cyan
@'
extends Node

const MOD_ID := "gareth-hardware_booster_mod"
const LOG_NAME := "gareth-hardware_booster_mod"

func _init() -> void:
	ModLoaderLog.info("Hardware Multi-Thread Booster initializing...", LOG_NAME)
	install_hooks()

func _ready() -> void:
	var cpu_count = OS.get_processor_count()
	ModLoaderLog.info("Hardware Multi-Thread Booster active! Detected " + str(cpu_count) + " logical CPU threads.", LOG_NAME)

func install_hooks() -> void:
	var unpacked_dir = ModLoaderMod.get_unpacked_dir().path_join(MOD_ID)
	var ext_dir = unpacked_dir.path_join("extensions")

	ModLoaderMod.install_script_hooks(
		"res://scenes/tilemaps/tile_map_chunk.gd",
		ext_dir.path_join("scenes/tilemaps/tile_map_chunk.hooks.gd")
	)
'@ | Set-Content -Path "$innerDir\mod_main.gd" -Encoding UTF8

Write-Host ">>> 4. Writing parallelized tile_map_chunk.hooks.gd..." -ForegroundColor Cyan
$chunkHookPath = "$innerDir\extensions\scenes\tilemaps\tile_map_chunk.hooks.gd"

@'
extends Object

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	var chunk = chain.reference_object
	if not chunk or not ("tiles" in chunk) or not chunk.has_method("array_to_global_pos"):
		chain.execute_next([noise])
		return

	# If the chunk has a custom map active, allow the map chain to proceed normally
	if Gvars and ("level" in Gvars) and Gvars.level >= 100:
		chain.execute_next([noise])
		return

	# Multi-threaded standard chunk calculation across available CPU threads
	var total_tiles = chunk.tiles.size()
	var temp_tiles = chunk.tiles.duplicate()

	var group_id = WorkerThreadPool.add_group_task(
		func(i: int):
			var pos = Vector2i(chunk.array_to_global_pos(i))
			# Background thread noise sampling
			var val = noise.get_noise_2d(float(pos.x), float(pos.y))
			if val < -0.35 and pos.y > 6:
				temp_tiles[i] = chunk.Tiles.EMPTY
			elif val > 0.28:
				temp_tiles[i] = chunk.Tiles.COAL_STONE
		,
		total_tiles,
		32 # Process in batches of 32 tiles per thread task
	)

	# Await parallel background worker tasks
	WorkerThreadPool.wait_for_group_task_completion(group_id)

	# Commit completed thread data back to the chunk
	chunk.tiles = temp_tiles
	chain.execute_next([noise])
'@ | Set-Content -Path $chunkHookPath -Encoding UTF8
Write-Host "Created: $chunkHookPath" -ForegroundColor Green

Write-Host "`n>>> 5. Removing locked mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 6. Repackaging gareth-hardware_booster_mod.zip..." -ForegroundColor Cyan
if (Test-Path $zipPath) { Remove-Item -Path $zipPath -Force }

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$stream  = [System.IO.File]::Open($zipPath, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $outerDir -Recurse -File)) {$entryName = $f.FullName.Substring($outerDir.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Write-Host "Packed release archive: $zipPath" -ForegroundColor Green

Write-Host "`n>>> 7. Git staging and committing..." -ForegroundColor Cyan
git add -A
git commit -m "Add gareth-hardware_booster_mod for parallel chunk noise dispatch via WorkerThreadPool"
git push origin main

Write-Host "`nDeployment complete! Launch Coal LLC to test." -ForegroundColor Green