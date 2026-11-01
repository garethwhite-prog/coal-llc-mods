$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. CLEANING UP LOCKED & PENDING DELETE FILES ---"
Get-ChildItem -Path $steamMods -Filter "*.pending_delete" | ForEach-Object {
    $zipPath = $_.FullName.Replace(".pending_delete", ".zip")
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    Remove-Item $_.FullName -Force
    Write-Output "Purged pending deletion: $($_.Name)"
}

Write-Output "--- 2. FIXING SETTINGS MENU CRASH & PASSIVE UI (BUG-02) ---"
$settingsHookPath = "$repoRoot\mods-unpacked\nanobotz-autopassivechooser\mods-unpacked\nanobotz-autopassivechooser\extensions\scenes\Interfaces\Menus\settings_2.hooks.gd"
if (Test-Path $settingsHookPath) {
    $settingsFix = @"
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	# REMOVED AWAIT - This was crashing the entire Settings screen
	chain.execute_next([])
	var menu = chain.reference_object
	if not is_instance_valid(menu): return
	
	var passive_list = menu.find_child("passive_list", true, false)
	if not is_instance_valid(passive_list):
		passive_list = menu.find_child("VBoxContainer", true, false)
		
	if is_instance_valid(passive_list) and not passive_list.has_node("BouncingBallDamage"):
		var template = null
		if passive_list.get_child_count() > 0:
			template = passive_list.get_child(0)
					
		if is_instance_valid(template):
			var keys = ["Bouncing Ball Damage", "Bouncing Ball Radius", "Bouncing Ball Fire Rate"]
			var internal_keys = ["ball_blast_damage", "ball_blast_radius", "ball_fire_rate"]
			
			for i in range(keys.size()):
				var row = template.duplicate()
				row.name = keys[i].replace(" ", "")
				row.visible = true
				var lbl = row.find_child("*Label*", true, false)
				if is_instance_valid(lbl): lbl.text = keys[i]
				row.set_meta("passive_key", internal_keys[i])
				passive_list.call_deferred("add_child", row)
"@
    $settingsFix | Set-Content -Path $settingsHookPath -Encoding UTF8
}

Write-Output "--- 3. FIXING MOD STORE DYNAMIC JSON CATALOG (US-05) ---"
$storeViewPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_store_view.gd"
if (Test-Path $storeViewPath) {
    git checkout 807de20 -- "$storeViewPath"
    $svContent = Get-Content $storeViewPath -Raw
    
    # 1. Connect the client dynamically in _ready
    $clientInject = @"
	var client_script = load("res://mods-unpacked/gareth-mod_manager_mod/scripts/mod_store_client.gd")
	if client_script:
		var c = client_script.new()
		add_child(c)
		c.repo_fetch_completed.connect(_on_catalog_loaded)
		c.fetch_all_available_mods()
"@
    $svContent = $svContent -replace '_load_catalog_for_selected_repo\(\)', $clientInject
    
    # 2. Add callback to populate all_packages from the JSON data
    $catalogCallback = @"

func _on_catalog_loaded(repo: String, releases: Array) -> void:
	all_packages.clear()
	for r in releases:
		if not (r is Dictionary): continue
		var p_name = r.get("name", "Unknown Mod")
		if p_name == null: p_name = "Update Package"
		var p_id = ""
		var assets = r.get("assets", [])
		if assets.size() > 0:
			p_id = assets[0].get("name", "").replace(".zip", "")
		if p_id == "": continue

		all_packages.append({
			"id": p_id,
			"name": p_name,
			"tag": r.get("tag_name", "v1.0"),
			"desc": r.get("body", "No description available."),
			"cat": "Official Suite",
			"author": "Gareth White"
		})
	status_lbl.text = "Gareth White (Official Suite): %d active packages loaded from catalog." % all_packages.size()
	status_lbl.modulate = Color(0.4, 0.85, 1.0)
	_render_cards()
"@
    $svContent = $svContent -replace 'func _load_catalog_for_selected_repo\(\) -> void:[\s\S]*?_render_cards\(\)', $catalogCallback
    
    # 3. Add visual feedback for uninstalls
    $svContent = $svContent -replace 'status_lbl\.text = "🗑️ Uninstalled %s\.zip\. Deleted from active mods directory\." % mod_id', 'status_lbl.text = "🗑️ Uninstalled %s.zip. Deleted from active mods directory." % mod_id'
    $svContent = $svContent -replace 'btn_action\.pressed\.connect\(func\(\): _uninstall_mod\(pkg_id\)\)', 'btn_action.pressed.connect(func(): _uninstall_mod(pkg_id); btn_action.text = "Restart Required"; btn_action.disabled = true)'
    
    $svContent | Set-Content -Path $storeViewPath -Encoding UTF8
}

Write-Output "--- 4. FIXING MOD MANAGER SEARCH & TAGS (BUG-05 & US-07) ---"
$mgrViewPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_manager_view.gd"
if (Test-Path $mgrViewPath) {
    git checkout 807de20 -- "$mgrViewPath"
    $mvContent = Get-Content $mgrViewPath -Raw
    
    # Inject search bar cleanly into top_bar instead of root
    $searchInject = @"
	var search = LineEdit.new()
	search.placeholder_text = "Search installed mods..."
	search.custom_minimum_size = Vector2(250, 36)
	search.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	search.text_changed.connect(_on_search_filter)
	top_bar.add_child(search)
"@
    $mvContent = $mvContent -replace 'var confirm_btn := Button\.new\(\)', "$searchInject`n`tvar confirm_btn := Button.new()"
    
    $searchLogic = @"
func _on_search_filter(query: String) -> void:
	var q = query.to_lower()
	var scroll = find_child("ScrollContainer", true, false)
	if not scroll: return
	var content = scroll.get_child(0)
	for grid in content.get_children():
		if grid is GridContainer:
			for card in grid.get_children():
				if q.is_empty():
					card.visible = true
				else:
					var mod_name = card.name.to_lower()
					var lbl = card.find_child("*Label*", true, false)
					if is_instance_valid(lbl): mod_name += lbl.text.to_lower()
					card.visible = q in mod_name
"@
    $mvContent = $mvContent + "`n" + $searchLogic
    
    # Fix the community tags safely
    $authorLogic = @"
	if manifest and manifest.get("extra") and manifest.extra.get("godot") and manifest.extra.godot.get("authors"):
		var authors = manifest.extra.godot.authors
		if authors.size() > 0 and typeof(authors[0]) == TYPE_STRING and "Gareth White" in authors[0]:
			return "Gareth White (Official Suite)"
	return "Community Add-Ons"
"@
    $mvContent = $mvContent -replace 'return "Community Add-Ons"', $authorLogic
    $mvContent | Set-Content -Path $mgrViewPath -Encoding UTF8
}

Write-Output "--- 5. REPACKING MOD MANAGER & AUTOPASSIVECHOOSER ---"
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force }

$targetMods = @("gareth-mod_manager_mod", "nanobotz-autopassivechooser")
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
git commit -m "Fix: Remove destructive await in settings UI, wire Mod Store UI to live JSON fetch, and properly dock Mod Manager search."
git push origin main
Write-Output "Recovery Executed."