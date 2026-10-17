cls
# ==============================================================================
# Coal LLC - Fix Tectonic Faultline Chunk Generation & Tile Allocation
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

Write-Host ">>> 1. Patching tile_map_chunk.hooks.gd with noise & tile_properties signatures..." -ForegroundColor Cyan
@'
extends Object

func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	if Gvars.level == 102:
		var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
		if helper_script:
			var helper = helper_script.new()
			return helper.calculate_faultline_tier(pos)
	return chain.execute_next([pos])

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	chain.execute_next([noise])
	if Gvars.level == 102:
		var chunk = chain.reference_object
		if chunk:
			var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
			if helper_script:
				var helper = helper_script.new()
				helper.tag_seismic_seams(chunk)

func destroy_tile(chain: ModLoaderHookChain, idx: int, tile_properties: Dictionary) -> void:
	if Gvars.level == 102:
		var chunk = chain.reference_object
		if chunk:
			var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
			if helper_script:
				var helper = helper_script.new()
				helper.handle_tile_destroyed(chunk, idx, tile_properties)
	chain.execute_next([idx, tile_properties])

func generate_chests(chain: ModLoaderHookChain, current_locs: Array[Vector2i]) -> Array[Vector2i]:
	var result_locs: Array[Vector2i] = chain.execute_next([current_locs])
	if Gvars.level == 102:
		var chunk = chain.reference_object
		if chunk:
			var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
			if helper_script:
				var helper = helper_script.new()
				result_locs = helper.spawn_magma_siphons(chunk, result_locs)
	return result_locs
'@ | Set-Content -Path "$innerDir\extensions\scenes\tilemaps\tile_map_chunk.hooks.gd" -Encoding UTF8
Write-Host "Updated: $innerDir\extensions\scenes\tilemaps\tile_map_chunk.hooks.gd" -ForegroundColor Green

Write-Host ">>> 2. Flushing mod-hooks.zip to recompile hook chain with correct parameters..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 3. Repackaging mod archive for Steam..." -ForegroundColor Cyan
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

Write-Host ">>> 4. Git committing and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Fix tile_map_chunk hook signature: pass noise to generate_chunk and tile_properties to destroy_tile"
git push origin main

Write-Host "`nDeploy complete! Launch Coal LLC to test." -ForegroundColor Green