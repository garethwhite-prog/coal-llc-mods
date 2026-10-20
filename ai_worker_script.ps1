Clear-Host;

# ==============================================================================
# Coal LLC - Fix Custom Map Selection & Restore TileMapChunk Hooks
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

$modName    = "gareth-abyssal_trench_mod"
$outerDir   = "$repo\mods-unpacked\$modName"
$innerDir   = "$outerDir\mods-unpacked\$modName"
$zipPath    = "$steamMods\$modName.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 600

Write-Host "`n>>> 2. Quarantining third-party mods causing parse aborts..." -ForegroundColor Cyan
$brokenThirdParty = "$steamMods\der_floh-performance_mod.zip"
if (Test-Path $brokenThirdParty) {
    Rename-Item -Path $brokenThirdParty -NewName "der_floh-performance_mod.zip.disabled" -Force
    Write-Host "Disabled: der_floh-performance_mod.zip (variant type parse failure)" -ForegroundColor Yellow
}
$unpackedThirdParty = "$steamRoot\mods-unpacked\der_floh-performance_mod"
if (Test-Path $unpackedThirdParty) {
    Rename-Item -Path $unpackedThirdParty -NewName "der_floh-performance_mod.disabled" -Force
    Write-Host "Disabled: unpacked der_floh-performance_mod directory" -ForegroundColor Yellow
}

Write-Host "`n>>> 3. Correcting tile_map_chunk.hooks.gd in $modName..." -ForegroundColor Cyan
$chunkHookPath = "$innerDir\extensions\scenes\tilemaps\tile_map_chunk.hooks.gd"

@'
extends Object

func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	var helper_script = load("res://mods-unpacked/gareth-abyssal_trench_mod/helpers/AbyssalTrenchHelper.gd")
	if helper_script and helper_script.is_abyssal_level():
		if pos.y < 0:
			return -2
		return 1
	return chain.execute_next([pos])

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	chain.execute_next([noise])
	var helper_script = load("res://mods-unpacked/gareth-abyssal_trench_mod/helpers/AbyssalTrenchHelper.gd")
	if helper_script and helper_script.is_abyssal_level():
		var chunk = chain.reference_object
		if chunk:
			helper_script.generate_abyssal_strata(chunk, noise)

func damage_tile_idx(chain: ModLoaderHookChain, idx: int, damage: float) -> void:
	var helper_script = load("res://mods-unpacked/gareth-abyssal_trench_mod/helpers/AbyssalTrenchHelper.gd")
	if helper_script and helper_script.is_abyssal_level():
		var chunk = chain.reference_object
		if chunk and ("tiles" in chunk) and ("TILE_PROPERTIES" in chunk):
			if idx >= 0 and idx < chunk.tiles.size():
				var t_id = chunk.tiles[idx]
				if not chunk.TILE_PROPERTIES.has(t_id):
					var fallback_id = 211 if chunk.TILE_PROPERTIES.has(211) else (24 if chunk.TILE_PROPERTIES.has(24) else 41)
					if chunk.TILE_PROPERTIES.has(fallback_id):
						chunk.TILE_PROPERTIES[t_id] = chunk.TILE_PROPERTIES[fallback_id].duplicate(true)
		# Enforce starter pickaxe damage floor for Hadal stone carving
		damage = max(damage * 6.0, 35.0)

	chain.execute_next([idx, damage])

func destroy_tile(chain: ModLoaderHookChain, idx: int, tile_properties: Dictionary) -> void:
	var helper_script = load("res://mods-unpacked/gareth-abyssal_trench_mod/helpers/AbyssalTrenchHelper.gd")
	if helper_script and helper_script.is_abyssal_level():
		var chunk = chain.reference_object
		if chunk and ("tiles" in chunk) and idx >= 0 and idx < chunk.tiles.size():
			var t_id = chunk.tiles[idx]
			# 50% bonus coal nugget drop for filler ocean stone
			if (t_id == 211 or t_id == 92) and randf() < 0.50:
				if "coal_resource" in chunk and chunk.coal_resource:
					if chunk.has_method("spawn_item_drop"):
						var local_coords = Vector2i(idx % chunk.chunk_size, idx / chunk.chunk_size)
						chunk.spawn_item_drop(chunk.coal_resource, chunk.map_to_local(local_coords))

	# Strictly preserve 2-argument signature: (idx: int, tile_properties: Dictionary)
	chain.execute_next([idx, tile_properties])
'@ | Set-Content -Path $chunkHookPath -Encoding UTF8
Write-Host "Updated hook file: $chunkHookPath" -ForegroundColor Green

Write-Host "`n>>> 4. Purging mod-hooks.zip to trigger clean rebuild..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
    Write-Host "Removed stale mod-hooks.zip" -ForegroundColor Green
}

Write-Host "`n>>> 5. Repackaging $modName.zip..." -ForegroundColor Cyan
if (Test-Path $zipPath) { Remove-Item -Path$zipPath -Force }

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$stream  = [System.IO.File]::Open($zipPath, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $outerDir -Recurse -File)) {$entryName = $f.FullName.Substring($outerDir.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Write-Host "Repacked release archive: $zipPath" -ForegroundColor Green

Write-Host "`n>>> 6. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Restore 2-arg destroy_tile hook signature and isolate incompatible third-party hooks"
git push origin main

Write-Host "`nEnvironment patched successfully! Launch Coal LLC to verify level selection." -ForegroundColor Green