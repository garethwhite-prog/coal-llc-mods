Clear-Host;

# ==============================================================================
# Coal LLC - Fix damage_tile_idx Signature & Deferred Shop Filtering
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"
$dumpRoot   = "$steamRoot\_dump"

$lcInnerDir = "$repo\mods-unpacked\gareth-living_canvas_mod\mods-unpacked\gareth-living_canvas_mod"
$mmInnerDir = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod"

Set-Location $repo

Write-Host ">>> 1. Inspecting damage_tile_idx signature in base game dump..." -ForegroundColor Cyan
$chunkDump = Join-Path $dumpRoot "scenes\tilemaps\tile_map_chunk.gd"
if (Test-Path $chunkDump) {
    $lines = Get-Content $chunkDump
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "func\s+damage_tile_idx\b") {
            Write-Host "Found in tile_map_chunk.gd:" -ForegroundColor Yellow
            for ($k = $i; $k -le [Math]::Min($lines.Count - 1, $i + 15); $k++) {
                Write-Host ("{0,4}: {1}" -f ($k + 1), $lines[$k])
            }
            break
        }
    }
}

Write-Host "`n>>> 2. Updating tile_map_chunk.hooks.gd with 2-parameter signature..." -ForegroundColor Cyan
$chunkHookPath = "$lcInnerDir\extensions\scenes\tilemaps\tile_map_chunk.hooks.gd"

@'
extends Object

func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
	if helper_script and helper_script.is_canvas_level():
		if pos.y < 0:
			return -2
		return 1
	return chain.execute_next([pos])

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	chain.execute_next([noise])
	var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
	if helper_script and helper_script.is_canvas_level():
		var chunk = chain.reference_object
		if chunk:
			helper_script.paint_chunk_from_canvas(chunk)

func damage_tile_idx(chain: ModLoaderHookChain, idx: int, damage: float) -> void:
	var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
	if helper_script and helper_script.is_canvas_level():
		var chunk = chain.reference_object
		if chunk and chunk.has_method("array_to_global_pos"):
			var global_pos: Vector2i = Vector2i(chunk.array_to_global_pos(idx))
			# High damage multiplier so starter pickaxe easily carves into canvas art
			if global_pos.y > 12:
				damage *= 5.0
	chain.execute_next([idx, damage])
'@ | Set-Content -Path $chunkHookPath -Encoding UTF8
Write-Host "Patched: $chunkHookPath" -ForegroundColor Green

Write-Host "`n>>> 3. Implementing deferred shop filter in management_screen.hooks.gd..." -ForegroundColor Cyan
$mgmtHook = "$mmInnerDir\extensions\scenes\Stages\management_screen.hooks.gd"

@'
extends Object

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	
	var screen = chain.reference_object
	if screen:
		# Run deferred so all weapon mods have finished adding their buttons
		screen.call_deferred("_filter_class_weapons_living_canvas")

func _filter_class_weapons_living_canvas() -> void:
	var prof = Gvars.profession if ("profession" in Gvars and Gvars.profession) else null
	var prof_name: String = prof.name if (prof and "name" in prof) else ""
	
	if prof_name == "Internship" or prof_name == "":
		var tree = Engine.get_main_loop()
		if not tree:
			return
		var root = tree.root
		var shop_items = root.find_children("*", "EmployeeShopTooltip", true, false)
		
		for card in shop_items:
			if "item" in card and card.item:
				var item_name: String = card.item.itemName if ("itemName" in card.item) else ""
				if item_name.contains("Optical Emitter") or item_name.contains("Tectonic Fracker") or item_name.contains("Broadsword") or item_name.contains("Energy Saber"):
					card.visible = false
					card.process_mode = Node.PROCESS_MODE_DISABLED
'@ | Set-Content -Path $mgmtHook -Encoding UTF8
Write-Host "Patched: $mgmtHook" -ForegroundColor Green

Write-Host "`n>>> 4. Flushing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 5. Repackaging living_canvas_mod.zip and mod_manager_mod.zip..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($mTarget in @("gareth-living_canvas_mod", "gareth-mod_manager_mod")) {
    $mOuter = "$repo\mods-unpacked\$mTarget"
    $mZip   = "$steamMods\$mTarget.zip"
    if (Test-Path $mZip) { Remove-Item -Path $mZip -Force }

    $stream  = [System.IO.File]::Open($mZip, [System.IO.FileMode]::CreateNew)
    $archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
    foreach ($f in (Get-ChildItem -Path $mOuter -Recurse -File)) {$entryName = $f.FullName.Substring($mOuter.Length + 1).Replace("\", "/")
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
    }
    $archive.Dispose()
	$stream.Dispose()
    Write-Host "Repacked: $mZip" -ForegroundColor Green
}

Write-Host "`n>>> 6. Git staging and committing..." -ForegroundColor Cyan
git add -A
git commit -m "Fix damage_tile_idx 2-parameter signature and apply deferred equipment shop filtering"
git push origin main

Write-Host "`nFix deployed successfully! Launch Coal LLC to test." -ForegroundColor Green