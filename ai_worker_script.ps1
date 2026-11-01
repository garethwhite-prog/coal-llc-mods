$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. FIXING MOD MANAGER PARSE ERRORS (BUG-05) ---"
$mgrViewPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_manager_view.gd"
if (Test-Path $mgrViewPath) {
    git checkout 807de20 -- "$mgrViewPath"
    $mvContent = Get-Content $mgrViewPath -Raw
    
    # 1A. Safely inject the search bar into the _ready() block with strict Godot indentation
    $searchInject = @"
func _ready() -> void:
	call_deferred("_inject_search_bar")
"@
    $mvContent = $mvContent -replace 'func _ready\(\) -> void:', $searchInject
    
    # 1B. Append the search bar logic and Custom Tag override
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
	if manifest and manifest.get("extra") and manifest.extra.get("godot") and manifest.extra.godot.get("authors"):
		var authors = manifest.extra.godot.authors
		if authors.size() > 0 and typeof(authors[0]) == TYPE_STRING and "Gareth White" in authors[0]:
			return "Gareth White (Official Suite)"
	return "Community Add-Ons"
"@
    $mvContent = $mvContent -replace 'func _get_mod_category\(manifest: Dictionary\) -> String:[\s\S]*?return "Community Add-Ons"', $searchLogic
    $mvContent | Set-Content -Path $mgrViewPath -Encoding UTF8
    Write-Output "Patched mod_manager_view.gd to remove Parse Errors and install Search."
}

Write-Output "--- 2. FIXING MAIN MENU NULL INSTANCE (BUG-06) ---"
$mainMenuHooksPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scripts\MainMenu.hooks.gd"
if (Test-Path $mainMenuHooksPath) {
    git checkout a9ca50039c02c57c68f24f0fcb0be1b547bb53c3 -- "$mainMenuHooksPath"
    $mmContent = Get-Content $mainMenuHooksPath -Raw
    
    # Safely clear pending deletions without crashing GDScript lambdas
    $purgeLogic = @"
func _ready(chain: ModLoaderHookChain) -> void:
	_process_pending_deletions()
	chain.execute_next([])

func _process_pending_deletions() -> void:
	var base_dir = OS.get_executable_path().get_base_dir()
	var mods_dir = base_dir.path_join("mods")
	var dir = DirAccess.open(mods_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if "pending_delete" in file_name:
				var target_zip = file_name.replace(".pending_delete", ".zip")
				if FileAccess.file_exists(mods_dir.path_join(target_zip)):
					DirAccess.remove_absolute(mods_dir.path_join(target_zip))
				DirAccess.remove_absolute(mods_dir.path_join(file_name))
			file_name = dir.get_next()
"@
    $mmContent = $mmContent -replace 'func _ready\(chain: ModLoaderHookChain\) -> void:\s*chain\.execute_next\(\[\]\)', $purgeLogic
    $mmContent | Set-Content -Path $mainMenuHooksPath -Encoding UTF8
    Write-Output "Patched MainMenu.hooks.gd to prevent null lambda execution."
}

Write-Output "--- 3. FIXING MOD STORE JSON FETCHING (US-05) ---"
$storeClientPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scripts\mod_store_client.gd"
if (Test-Path $storeClientPath) {
    $scContent = Get-Content $storeClientPath -Raw
    $oldUrlLogic = 'var url := "https://api.github.com/repos/%s/releases" % repo'
    $newUrlLogic = 'var url := "https://raw.githubusercontent.com/garethwhite-prog/coal-llc-mods/main/mod_catalog.json?v=" + str(Time.get_unix_time_from_system())'
    $scContent = $scContent.Replace($oldUrlLogic, $newUrlLogic)
    $scContent | Set-Content -Path $storeClientPath -Encoding UTF8
    Write-Output "Forced Mod Store Client to use raw JSON."
}

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
    $svContent | Set-Content -Path $storeViewPath -Encoding UTF8
    Write-Output "Patched Mod Store View to digest Custom JSON Array."
}

Write-Output "--- 4. RESTORING BOUNCING BALL PASSIVE UI (BUG-02) ---"
$settingsHookPath = "$repoRoot\mods-unpacked\nanobotz-autopassivechooser\mods-unpacked\nanobotz-autopassivechooser\extensions\scenes\Interfaces\Menus\settings_2.hooks.gd"
if (Test-Path $settingsHookPath) {
    $settingsFix = @"
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
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
    Write-Output "Safely injected Bouncing Ball UI clones without await."
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
git commit -m "Fix: Eradicate Parse Errors in Mod Manager UI and properly map Mod Store URL to static JSON catalog."
git push origin main
Write-Output "Recovery Completed Successfully."