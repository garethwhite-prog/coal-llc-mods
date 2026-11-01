$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. FIXING MOD STORE SYNTAX ERROR (US-05) ---"
$storeViewPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_store_view.gd"
if (Test-Path $storeViewPath) {
    git checkout a9ca50039c02c57c68f24f0fcb0be1b547bb53c3 -- "$storeViewPath"
    $svContent = Get-Content $storeViewPath -Raw
    
    $clientInject = @"
	var client_script = load("res://mods-unpacked/gareth-mod_manager_mod/scripts/mod_store_client.gd")
	if client_script:
		var c = client_script.new()
		add_child(c)
		c.repo_fetch_completed.connect(_on_catalog_loaded)
		c.fetch_all_available_mods()
"@
    $svContent = $svContent -replace '_load_catalog_for_selected_repo\(\)', $clientInject
    
    $catalogCallback = @"

func _on_catalog_loaded(repo: String, releases: Array) -> void:
	all_packages.clear()
	for r in releases:
		if typeof(r) != TYPE_DICTIONARY: continue
		var p_name = r.get("name", "Unknown Mod")
		var p_id = r.get("id", "")
		var tag = r.get("version", "1.0.0")
		if not tag.begins_with("v"): tag = "v" + tag
		
		# Fallback checking if it arrived in GitHub API structure
		var assets = r.get("assets", [])
		if typeof(assets) == TYPE_ARRAY and assets.size() > 0:
			var asset_map = assets[0]
			if typeof(asset_map) == TYPE_DICTIONARY:
				if p_id == "": p_id = asset_map.get("name", "").replace(".zip", "")
				tag = r.get("tag_name", "v1.0")
				
		if p_id == "": continue

		all_packages.append({
			"id": p_id,
			"name": p_name,
			"tag": tag,
			"desc": r.get("description", r.get("body", "No description available.")),
			"cat": "Official Suite",
			"author": r.get("author", "Gareth White")
		})
	status_lbl.text = "Gareth White (Official Suite): %d active packages loaded from catalog." % all_packages.size()
	status_lbl.modulate = Color(0.4, 0.85, 1.0)
	_render_cards()
"@
    $svContent = $svContent -replace 'func _load_catalog_for_selected_repo\(\) -> void:[\s\S]*?_render_cards\(\)', $catalogCallback
    $svContent | Set-Content -Path $storeViewPath -Encoding UTF8
    Write-Output "Patched mod_store_view.gd with safe JSON dictionary parsing."
}

Write-Output "--- 2. CREATING TRANSMOG TELEPORT MOD ---"
$newModDir = "$repoRoot\mods-unpacked\gareth-transmog_teleport_mod"
if (-not (Test-Path "$newModDir\extensions\scenes\Interfaces")) {
    New-Item -Path "$newModDir\extensions\scenes\Interfaces" -ItemType Directory -Force | Out-Null
}

$manifest = @"
{
  "name": "Transmog Teleport Mod",
  "id": "gareth-transmog_teleport_mod",
  "version": "1.0.0",
  "authors": ["Gareth White"],
  "description": "Adds a button to the bottom right of the inventory panel to instantly teleport items to the depot, losing 50% to transmogrification.",
  "dependencies": {}
}
"@
$manifest | Set-Content -Path "$newModDir\manifest.json" -Encoding UTF8

$modMain = @"
extends Node

func _init() -> void:
	ModLoaderLog.info("Transmog Teleport Mod initialized", "gareth-transmog_teleport_mod")

func _ready() -> void:
	ModLoaderMod.install_script_extension("res://mods-unpacked/gareth-transmog_teleport_mod/extensions/scenes/Interfaces/InventoryWindow.gd")
"@
$modMain | Set-Content -Path "$newModDir\mod_main.gd" -Encoding UTF8

$invExt = @"
extends "res://scenes/Interfaces/InventoryWindow.gd"

func _ready() -> void:
	super()
	call_deferred("_inject_transmog_button")

func _inject_transmog_button() -> void:
	var btn = Button.new()
	btn.name = "TransmogTeleportBtn"
	btn.text = "Transmog Depot (50% Loss)"
	btn.modulate = Color(0.9, 0.3, 0.9)
	btn.custom_minimum_size = Vector2(220, 40)
	btn.pressed.connect(_on_transmog_teleport)
	
	add_child(btn)
	btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	btn.position = Vector2(size.x - btn.custom_minimum_size.x - 20, size.y - btn.custom_minimum_size.y - 20)

func _on_transmog_teleport() -> void:
	if Gvars != null and "inventory" in Gvars and typeof(Gvars.inventory) == TYPE_DICTIONARY:
		for key in Gvars.inventory.keys():
			if typeof(Gvars.inventory[key]) == TYPE_INT or typeof(Gvars.inventory[key]) == TYPE_FLOAT:
				Gvars.inventory[key] = int(Gvars.inventory[key] / 2.0)
				
	var stockpile = get_tree().get_first_node_in_group("Stockpile")
	if not stockpile:
		var root = get_tree().current_scene
		if root: stockpile = root.find_child("Stockpile", true, false)
		
	if stockpile and stockpile.has_method("drop_off_coal"):
		stockpile.drop_off_coal()
		
	if has_method("load_inventory"):
		load_inventory()
"@
$invExt | Set-Content -Path "$newModDir\extensions\scenes\Interfaces\InventoryWindow.gd" -Encoding UTF8
Write-Output "Generated gareth-transmog_teleport_mod."

Write-Output "--- 3. REPACKING ACTIVE MODS ---"
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force -ErrorAction SilentlyContinue }

$targetMods = @("gareth-mod_manager_mod", "gareth-transmog_teleport_mod")
Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($mod in $targetMods) {
    $srcDir = Join-Path $repoRoot "mods-unpacked\$mod"
    $downZip = Join-Path $downMods "$mod.zip"
    $steamZip = Join-Path $steamMods "$mod.zip"
    
    if (Test-Path $downZip) { Remove-Item $downZip -Force }
    $archive = [System.IO.Compression.ZipFile]::Open($downZip, [System.IO.Compression.ZipArchiveMode]::Create)
    $files = Get-ChildItem -Path $srcDir -Recurse -File
    foreach ($file in $files) {
        $entryName = $file.FullName.Substring($srcDir.Length + 1).Replace("\", "/")
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $entryName)
    }
    $archive.Dispose()
    if (Test-Path $steamZip) { Copy-Item -Path $downZip -Destination $steamZip -Force }
    Write-Output "Deployed $mod.zip"
}

Write-Output "--- Committing to Git ---"
git add -A
git commit -m "Fix: Eradicated lambda parse error blocking Mod Store View compilation, and added new Transmog Teleport Mod."
git push origin main
Write-Output "Process Complete."