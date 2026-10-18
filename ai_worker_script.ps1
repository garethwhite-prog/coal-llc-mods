Clear-Host;

# ==============================================================================
# Coal LLC - Synchronize Master Documentation & Log Map 103 (Living Canvas)
# ==============================================================================

$repo        = "C:\Dev\coal-llc-mods"
$promptPath  = "$repo\SESSION_PROMPT.md"
$readmePath  = "$repo\README.md"

Set-Location $repo

Write-Host ">>> 1. Appending Map 103 contracts to SESSION_PROMPT.md..." -ForegroundColor Cyan
$promptContent = Get-Content -Path $promptPath -Raw

if ($promptContent -notmatch "Map 103 - The Living Canvas") {
    $map103Doc = @'

### Map 103 - The Living Canvas (`gareth-living_canvas_mod`)
* **Level ID**: `103` (Registered in `level_manager.all_levels` and `Gvars.level_info`).
* **Stage Routing**: Hook `Game.gd:change_stage` on `target == 2` and `Gvars.level == 103` to load `res://scenes/Stages/MineRegion.tscn`.
* **Subterranean Generation Hook**: Hook `tile_map_chunk.gd:generate_chunk`. Maintain `pos.y < 0` returning `-2` (sky stratum) in `lvl_from_global_pos`.
* **Strata Mapping**: Map RGB pixels to valid breakable base blocks (`STRATA_BASES`) using Euclidean distance. Infuse 45% coal (`base + 1`), 25% ores (`base + 2..11`), and 30% base stone.
* **Layout Geometry**: Keep rows 0�12 as vanilla surface buffer; generate 8-block-wide breakable side quarries at `abs(x) >= 48` before terminating with outer bedrock walls at `abs(x) >= 56`.
* **Asset Loading**: Read image bytes via `FileAccess.get_file_as_bytes()` to bypass virtual zip boundaries; bundled default is `res://mods-unpacked/gareth-living_canvas_mod/assets/default_canvas.png`.
'@
    $promptContent += $map103Doc
    # Update mod count to 48
    $promptContent = $promptContent -replace '47 mods', '48 mods'
    $promptContent = $promptContent -replace '47-mod', '48-mod'
    Set-Content -Path $promptPath -Value $promptContent -Encoding UTF8
    Write-Host "Updated: $promptPath" -ForegroundColor Green
}

Write-Host "`n>>> 2. Updating root README.md to 48 mods..." -ForegroundColor Cyan
$readmeContent = Get-Content -Path $readmePath -Raw
$readmeContent = $readmeContent -replace '47 mods', '48 mods'
$readmeContent = $readmeContent -replace '47-mod', '48-mod'

if ($readmeContent -notmatch "gareth-living_canvas_mod") {
    $tableEntry = "| `gareth-living_canvas_mod` | Maps & Environments | The Living Canvas (Map 103) - Image-to-strata mosaic quarry with native file picker |"
    $readmeContent = $readmeContent -replace '(\| `gareth-tectonic_faultline_mod`.*)', "`$1`r`n$tableEntry"
    Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
    Write-Host "Updated: $readmePath" -ForegroundColor Green
}

Write-Host "`n>>> 3. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Finalize Map 103 (The Living Canvas): update master README and SESSION_PROMPT to 48 mods"
git push origin main

Write-Host "`nMaster documentation fully synchronized and pushed!" -ForegroundColor Green