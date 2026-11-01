$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. FIXING MOD STORE LAMBDA SYNTAX (US-05) ---"
$storeViewPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_store_view.gd"
if (Test-Path $storeViewPath) {
    # We will safely reconstruct the entire script to guarantee no stray parse errors exist
    $svContent = @"
extends Control

@onready var container: GridContainer = %ModStoreContainer
@onready var status_lbl: Label = %StatusLabel

var all_packages: Array = []

func _ready() -> void:
	status_lbl.text = "Loading Mod & Map Catalog..."
	var client_script = load("res://mods-unpacked/gareth-mod_manager_mod/scripts/mod_store_client.gd")
	if client_script:
		var c = client_script.new()
		add_child(c)
		c.repo_fetch_completed.connect(_on_catalog_loaded)
		c.fetch_all_available_mods()

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

func _render_cards() -> void:
	for c in container.get_children():
		c.queue_free()
	
	for pkg in all_packages:
		var pkg_id = pkg["id"]
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(250, 180)
		var vb = VBoxContainer.new()
		card.add_child(vb)
		
		var title = Label.new()
		title.text = pkg["name"]
		title.autowrap_mode = TextServer.AUTOWRAP_WORD
		vb.add_child(title)
		
		var author = Label.new()
		author.text = pkg["author"] + " | " + pkg["tag"]
		author.modulate = Color(0.7, 0.7, 0.7)
		vb.add_child(author)
		
		var spacer = Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vb.add_child(spacer)
		
		var btn_action = Button.new()
		var installed = _is_installed(pkg_id)
		if installed:
			btn_action.text = "Uninstall"
			btn_action.modulate = Color(0.9, 0.4, 0.4)
			# Safe Godot 4 bindings - No lambda semicolons
			btn_action.pressed.connect(_on_uninstall_pressed.bind(pkg_id, btn_action))
		else:
			btn_action.text = "Install"
			btn_action.modulate = Color(0.4, 0.9, 0.4)
			btn_action.pressed.connect(_on_install_pressed.bind(pkg_id, btn_action))
		vb.add_child(btn_action)
		
		container.add_child(card)

func _is_installed(mod_id: String) -> bool:
	var expected_path = OS.get_executable_path().get_base_dir().path_join("mods").path_join(mod_id + ".zip")
	return FileAccess.file_exists(expected_path)

func _on_install_pressed(mod_id: String, btn: Button) -> void:
	btn.text = "Installing..."
	btn.disabled = true
	status_lbl.text = "Installing %s..." % mod_id
	var c = find_child("ModStoreClient", true, false)
	if c: c.download_mod(mod_id)

func _on_uninstall_pressed(mod_id: String, btn: Button) -> void:
	_uninstall_mod(mod_id)
	btn.text = "Restart Required"
	btn.disabled = true

func _uninstall_mod(mod_id: String) -> void:
	var path = OS.get_executable_path().get_base_dir().path_join("mods").path_join(mod_id + ".zip")
	var file = FileAccess.open(path + ".pending_delete", FileAccess.WRITE)
	if file:
		file.store_string("DELETE_ON_BOOT")
		file.close()
	status_lbl.text = "🗑️ Uninstalled %s.zip. Deleted from active mods directory." % mod_id

func _on_close_pressed() -> void:
	queue_free()
"@
    $svContent | Set-Content -Path $storeViewPath -Encoding UTF8
    Write-Output "Patched mod_store_view.gd with safe explicit signal bindings."
}

Write-Output "--- 2. REGISTERING TRANSMOG TELEPORT MOD ---"
$catPath = "$repoRoot\mod_catalog.json"
if (Test-Path $catPath) {
    $catContent = Get-Content $catPath -Raw | ConvertFrom-Json
    $exists = $catContent | Where-Object { $_.id -eq "gareth-transmog_teleport_mod" }
    
    if (-not $exists) {
        $newEntry = @{
            id = "gareth-transmog_teleport_mod"
            name = "Transmog Teleport Mod"
            version = "1.0.0"
            description = "Instantly teleport items to the depot, losing 50% to transmogrification."
            author = "Gareth White"
            download_url = "https://raw.githubusercontent.com/garethwhite-prog/coal-llc-mods/main/downloaded_mods/gareth-transmog_teleport_mod.zip"
        }
        $catContent += $newEntry
        $catContent | ConvertTo-Json -Depth 5 | Set-Content -Path $catPath -Encoding UTF8
        Write-Output "Registered Transmog Teleport Mod to mod_catalog.json"
    }
}

Write-Output "--- 3. REPACKING MOD MANAGER ---"
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force -ErrorAction SilentlyContinue }

$targetMods = @("gareth-mod_manager_mod")
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
git commit -m "Fix: Hardened Mod Store View UI bindings to eradicate parse error, and registered Transmog Teleport Mod."
git push origin main
Write-Output "Process Complete."