Clear-Host;

# ==============================================================================
# Coal LLC - Fix Hardware Booster Syntax & Choose Passive Exception Loop
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

$hbInner    = "$repo\mods-unpacked\gareth-hardware_booster_mod\mods-unpacked\gareth-hardware_booster_mod"
$mmInner    = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod"

Set-Location $repo

Write-Host ">>> 1. Fixing clean indentation in hardware_booster_mod..." -ForegroundColor Cyan
$chunkHookPath = "$hbInner\extensions\scenes\tilemaps\tile_map_chunk.hooks.gd"

@'
extends Object

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	var chunk = chain.reference_object
	if not chunk or not ("tiles" in chunk) or not chunk.has_method("array_to_global_pos"):
		chain.execute_next([noise])
		return

	if Gvars and ("level" in Gvars) and Gvars.level >= 100:
		chain.execute_next([noise])
		return

	var total_tiles: int = chunk.tiles.size()
	var temp_tiles = chunk.tiles.duplicate()

	var group_id = WorkerThreadPool.add_group_task(
		func(i: int):
			var pos = Vector2i(chunk.array_to_global_pos(i))
			var val = noise.get_noise_2d(float(pos.x), float(pos.y))
			if val < -0.35 and pos.y > 6:
				temp_tiles[i] = chunk.Tiles.EMPTY
			elif val > 0.28:
				temp_tiles[i] = chunk.Tiles.COAL_STONE
		,
		total_tiles,
		32
	)

	WorkerThreadPool.wait_for_group_task_completion(group_id)
	chunk.tiles = temp_tiles
	chain.execute_next([noise])
'@ | Set-Content -Path $chunkHookPath -Encoding UTF8
Write-Host "Patched: $chunkHookPath" -ForegroundColor Green

Write-Host "`n>>> 2. Adding safety guard to choose_passive.hooks.gd..." -ForegroundColor Cyan
$passiveHookPath = "$mmInner\extensions\scenes\Interfaces\in_game\choose_passive.hooks.gd"
if (Test-Path $passiveHookPath) {
    $code = Get-Content $passiveHookPath -Raw
    # Guard against null/missing custom_passives property
    $fixedCode = $code -replace 'Gvars\.custom_passives\[', 'if not ("custom_passives" in Gvars) or Gvars.custom_passives == null: Gvars.custom_passives = {}`r`n`t`tGvars.custom_passives['
    Set-Content -Path $passiveHookPath -Value $fixedCode -Encoding UTF8
    Write-Host "Patched: $passiveHookPath" -ForegroundColor Green
}

Write-Host "`n>>> 3. Purging mod-hooks.zip to clear cached assemblies..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
    Write-Host "Removed: $hookZip" -ForegroundColor Green
}

Write-Host ">>> 4. Repackaging modified archives..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($m in @("gareth-hardware_booster_mod", "gareth-mod_manager_mod")) {
    $src = "$repo\mods-unpacked\$m"
    $zip = "$steamMods\$m.zip"
    if (Test-Path $zip) { Remove-Item -Path $zip -Force }

    $stream  = [System.IO.File]::Open($zip, [System.IO.FileMode]::CreateNew)
    $archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
    foreach ($f in (Get-ChildItem -Path $src -Recurse -File)) {$entryName = $f.FullName.Substring($src.Length + 1).Replace("\", "/")
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
    }
    $archive.Dispose()
	$stream.Dispose()
    Write-Host "Repacked: $zip" -ForegroundColor Green
}

Write-Host "`n>>> 5. Git staging and committing..." -ForegroundColor Cyan
git add -A
git commit -m "Fix hardware booster indentation parse error and guard Gvars.custom_passives in mod manager"
git push origin main

Write-Host "`nFixes deployed successfully! Launch Coal LLC to test." -ForegroundColor Green