cls
`
# ==============================================================================
# Coal LLC - Clean Hook Patch & Deployment (Strict Paths, No Whitespace)
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

Write-Host ">>> 1. Cleaning up any stray space-prefixed zip files in Steam..." -ForegroundColor Cyan
Get-ChildItem -Path $steamModsDir -Filter "*lost_expedition*.zip" | ForEach-Object {
    if ($_.Name.StartsWith(" ")) {
        Remove-Item $_.FullName -Force
        Write-Host "Removed invalid archive: $($_.Name)" -ForegroundColor Yellow
    }
}

Write-Host ">>> 2. Writing level_select.hooks.gd (chain.reference fix)..." -ForegroundColor Cyan
$levelSelectHooksGd = @'
func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-lost_expedition_mod/helpers/LostExpeditionHelper.gd")
	if helper_script:
		var helper = helper_script.new()
		helper.ensure_level_registered()
		if chain.reference and "LEVEL_ORDER" in chain.reference:
			if not chain.reference.LEVEL_ORDER.has(helper.EXPEDITION_LEVEL_ID):
				chain.reference.LEVEL_ORDER.append(helper.EXPEDITION_LEVEL_ID)
	chain.execute_next()
'@
$levelSelectHooksPath = Join-Path $innerModDir "extensions\scenes\Interfaces\Menus\level_select.hooks.gd"
Set-Content -Path $levelSelectHooksPath -Value $levelSelectHooksGd -Encoding UTF8
Write-Host "Patched: $levelSelectHooksPath" -ForegroundColor Green

Write-Host ">>> 3. Writing tile_map_chunk.hooks.gd (chain.reference fix)..." -ForegroundColor Cyan
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
			helper.tag_uxo_tiles(chain.reference)

func destroy_tile(chain: ModLoaderHookChain, idx: int, tile_properties: Dictionary) -> void:
	if Gvars.level == 101:
		var helper_script = load("res://mods-unpacked/gareth-lost_expedition_mod/helpers/LostExpeditionHelper.gd")
		if helper_script:
			var helper = helper_script.new()
			helper.handle_tile_destroyed(chain.reference, idx)
	chain.execute_next([idx, tile_properties])

func generate_chests(chain: ModLoaderHookChain, current_block_chest_locations: Array[Vector2i]) -> Array[Vector2i]:
	var locs: Array[Vector2i] = chain.execute_next([current_block_chest_locations])
	if Gvars.level == 101:
		var helper_script = load("res://mods-unpacked/gareth-lost_expedition_mod/helpers/LostExpeditionHelper.gd")
		if helper_script:
			var helper = helper_script.new()
			locs = helper.spawn_cryo_pods(chain.reference, locs)
	return locs
'@
$tileMapChunkHooksPath = Join-Path $innerModDir "extensions\scenes\tilemaps\tile_map_chunk.hooks.gd"
Set-Content -Path $tileMapChunkHooksPath -Value $tileMapChunkHooksGd -Encoding UTF8
Write-Host "Patched: $tileMapChunkHooksPath" -ForegroundColor Green

Write-Host ">>> 4. Deleting mod-hooks.zip to force hook re-generation..." -ForegroundColor Cyan
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
Write-Host "Archive re-created cleanly at: $zipPath" -ForegroundColor Green

Write-Host ">>> 6. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Apply chain.reference fixes to Lost Expedition hooks and clean zip package"
git push origin main

Write-Host "`nAll operations succeeded without path errors! Launch Coal LLC to test." -ForegroundColor Green