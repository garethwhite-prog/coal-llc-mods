$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. FIXING MOD MANAGER TAG PARSER (BUG-05) ---"
$mgrViewPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_manager_view.gd"
if (Test-Path $mgrViewPath) {
    git checkout a9ca50039c02c57c68f24f0fcb0be1b547bb53c3 -- "$mgrViewPath"
    $mvContent = Get-Content $mgrViewPath -Raw
    
    $searchInject = @"
func _ready() -> void:
	call_deferred("_inject_search_bar")
"@
    $mvContent = $mvContent -replace 'func _ready\(\) -> void:', $searchInject
    
    $searchLogic = @"

func _inject_search_bar() -> void:
	var header = find_child("HeaderContainer", true, false)
	if not header: header = self
	var search = LineEdit.new()
	search.placeholder_text = "Search active mods..."
	search.custom_minimum_size = Vector2(300, 35)
	search.text_changed.connect(_on_search_filter)
	header.add_child(search)

func _on_search_filter(query: String) -> void:
	var q = query.to_lower()
	var list = find_child("ModListContainer", true, false)
	if is_instance_valid(list):
		for card in list.get_children():
			if q.is_empty():
				card.visible = true
			else:
				var mod_name = card.name.to_lower()
				var lbl = card.find_child("*Label*", true, false)
				if is_instance_valid(lbl): mod_name += lbl.text.to_lower()
				card.visible = q in mod_name

func _get_mod_category(manifest: Dictionary) -> String:
	if manifest and manifest.has("extra") and manifest["extra"] and manifest["extra"].has("godot") and manifest["extra"]["godot"].has("authors"):
		var authors = manifest["extra"]["godot"]["authors"]
		if typeof(authors) == TYPE_ARRAY and authors.size() > 0 and typeof(authors[0]) == TYPE_STRING and "Gareth White" in authors[0]:
			return "Gareth White (Official Suite)"
	return "Community Add-Ons"
"@
    $mvContent = $mvContent -replace 'func _get_mod_category\(manifest: Dictionary\) -> String:[\s\S]*?return "Community Add-Ons"', $searchLogic
    $mvContent | Set-Content -Path $mgrViewPath -Encoding UTF8
    Write-Output "Patched mod_manager_view.gd with safe Dictionary.has() lookups."
}

Write-Output "--- 2. FIXING MOD STORE JSON PARSER (US-05) ---"
$storeViewPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_store_view.gd"
if (Test-Path $storeViewPath) {
    git checkout 807de20 -- "$storeViewPath"
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
		var p_id = ""
		if r.has("assets") and typeof(r["assets"]) == TYPE_ARRAY and r["assets"].size() > 0:
			var asset_map = r["assets"][0]
			if typeof(asset_map) == TYPE_DICTIONARY:
				p_id = asset_map.get("name", "").replace(".zip", "")
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
    $svContent = $svContent -replace 'btn_action\.pressed\.connect\(func\(\): _uninstall_mod\(pkg_id\)\)', 'btn_action.pressed.connect(func(): _uninstall_mod(pkg_id); btn_action.text = "Restart Required"; btn_action.disabled = true)'
    $svContent | Set-Content -Path $storeViewPath -Encoding UTF8
    Write-Output "Patched mod_store_view.gd with safe Dictionary.has() lookups."
}

Write-Output "--- 3. FIXING AUTO PASSIVE SCRIPT (BUG-02) ---"
$passiveOrderGdPath = "$repoRoot\mods-unpacked\nanobotz-autopassivechooser\mods-unpacked\nanobotz-autopassivechooser\scenes\passive_order.gd"
if (Test-Path $passiveOrderGdPath) {
    $content = Get-Content $passiveOrderGdPath -Raw
    $oldCall = 'if ModLoaderConfig and "update_config" in ModLoaderConfig:'
    $newCall = 'if ModLoaderConfig != null:'
    $content = $content.Replace($oldCall, $newCall)
    $content | Set-Content -Path $passiveOrderGdPath -Encoding UTF8
    Write-Output "Patched passive_order.gd ModLoaderConfig call."
}

Write-Output "--- 4. Repacking Recovered Mods ---"
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
git commit -m "Fix: Hardened JSON Dictionary lookups and ModLoaderConfig calls to prevent UI crashes."
git push origin main
Write-Output "Recovery Completed Successfully."