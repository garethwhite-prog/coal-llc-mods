Clear-Host;

# ==============================================================================
# Coal LLC - Silence I/O Print Spam, Fix Parse Errors & Inspect Camera Zoom
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"
$dumpRoot   = "$steamRoot\_dump"

$hbInner    = "$repo\mods-unpacked\gareth-hardware_booster_mod\mods-unpacked\gareth-hardware_booster_mod"
$mmInner    = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod"

Set-Location $repo

Write-Host ">>> 1. Terminating any running Coal LLC / Godot processes..." -ForegroundColor Cyan
# Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
# Start-Sleep -Milliseconds 600

Write-Host ">>> 2. Silencing 'inventory count =' print spam across all mods..." -ForegroundColor Cyan
$allModScripts = Get-ChildItem -Path "$repo\mods-unpacked" -Recurse -Filter "*.gd"
foreach ($script in $allModScripts) {
    $code = Get-Content $script.FullName -Raw
    if ($code -match 'inventory count\s*=') {
        Write-Host "  Found spam print in: $($script.FullName.Replace($repo, ''))" -ForegroundColor Yellow
        $fixedCode = $code -replace '(?m)^\s*print\s*\(\s*["'']inventory count\s*=\s*["''].*?\)', '# silenced inventory count print'
        $fixedCode = $fixedCode -replace '(?m)^\s*print\s*\(\s*["'']max inventory\s*=\s*["''].*?\)', '# silenced max inventory print'
        Set-Content -Path $script.FullName -Value $fixedCode -Encoding UTF8
        Write-Host "  Silenced print loop in $($script.Name)" -ForegroundColor Green
    }
}

Write-Host "`n>>> 3. Writing clean choose_passive.hooks.gd (no backticks)..." -ForegroundColor Cyan
$passiveHookPath = "$mmInner\extensions\scenes\Interfaces\in_game\choose_passive.hooks.gd"
@'
extends Object

func _process(chain: ModLoaderHookChain, delta: float) -> void:
	chain.execute_next([delta])

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])

func _on_button_pressed(chain: ModLoaderHookChain) -> void:
	_handle_selection(chain, 0)

func _on_button_2_pressed(chain: ModLoaderHookChain) -> void:
	_handle_selection(chain, 1)

func _on_button_3_pressed(chain: ModLoaderHookChain) -> void:
	_handle_selection(chain, 2)

func _handle_selection(chain: ModLoaderHookChain, button_idx: int) -> void:
	var screen = chain.reference_object
	if not is_instance_valid(screen):
		chain.execute_next([])
		return

	if "options" in screen and button_idx < screen.options.size():
		var chosen = screen.options[button_idx]
		if chosen and ("stat_name" in chosen):
			_apply_custom_stat(chosen.stat_name, chosen.get("value", 0.0))

	chain.execute_next([])

func _apply_custom_stat(stat_name: String, val: float) -> void:
	if not Gvars:
		return
	if not ("custom_passives" in Gvars) or Gvars.custom_passives == null:
		Gvars.custom_passives = {}

	var passives = Gvars.custom_passives
	if passives is Dictionary:
		passives[stat_name] = passives.get(stat_name, 0.0) + val
'@ | Set-Content -Path $passiveHookPath -Encoding UTF8
Write-Host "Updated: $passiveHookPath" -ForegroundColor Green

Write-Host "`n>>> 4. Writing compile-safe hardware_booster_mod hook..." -ForegroundColor Cyan
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

	var worker_task = Callable(self, "_calc_tile_worker").bind(chunk, noise, temp_tiles)
	var group_id = WorkerThreadPool.add_group_task(worker_task, total_tiles, 32)
	WorkerThreadPool.wait_for_group_task_completion(group_id)

	chunk.tiles = temp_tiles
	chain.execute_next([noise])

func _calc_tile_worker(i: int, chunk: Node, noise: Noise, temp_tiles: Array) -> void:
	var pos = Vector2i(chunk.array_to_global_pos(i))
	var val = noise.get_noise_2d(float(pos.x), float(pos.y))
	if val < -0.35 and pos.y > 6:
		temp_tiles[i] = chunk.Tiles.EMPTY
	elif val > 0.28:
		temp_tiles[i] = chunk.Tiles.COAL_STONE
'@ | Set-Content -Path $chunkHookPath -Encoding UTF8
Write-Host "Updated: $chunkHookPath" -ForegroundColor Green

Write-Host "`n>>> 5. Inspecting CameraMain zoom handling in base dump..." -ForegroundColor Cyan
$cameraFiles = Get-ChildItem -Path $dumpRoot -Recurse -Filter "*Camera*.gd"
foreach ($cam in $cameraFiles) {
    Write-Host "--- Scanning $($cam.Name) for zoom logic ---" -ForegroundColor Yellow
    $lines = Get-Content $cam.FullName
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "zoom|wheel|zoom_in|zoom_out") {
            $start = [Math]::Max(0, $i - 1)
            $end = [Math]::Min($lines.Count - 1, $i + 3)
            for ($k = $start; $k -le $end; $k++) {
                Write-Host ("{0,4}: {1}" -f ($k + 1), $lines[$k])
            }
        }
    }
}

Write-Host "`n>>> 6. Purging mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
    Write-Host "Removed: $hookZip" -ForegroundColor Green
}

Write-Host ">>> 7. Repackaging modified mods..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($m in @("gareth-hardware_booster_mod", "gareth-mod_manager_mod", "gareth-more_inventory_stacks_mod", "gareth-more_inventory_slots_mod")) {
    $src = "$repo\mods-unpacked\$m"
    if (Test-Path $src) {
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
}

Write-Host "`n>>> 8. Git staging and committing..." -ForegroundColor Cyan
git add -A
git commit -m "Silence inventory print spam and clean choose_passive / hardware booster hooks"
git push origin main

Write-Host "`nReady to test! Launch Coal LLC and check the console output from Section 5." -ForegroundColor Green