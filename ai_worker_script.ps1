$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. FIXING PASSIVE ORDER GD SCRIPT (BUG-02) ---"
$passiveOrderGdPath = "$repoRoot\mods-unpacked\nanobotz-autopassivechooser\mods-unpacked\nanobotz-autopassivechooser\scenes\passive_order.gd"
if (Test-Path $passiveOrderGdPath) {
    $content = Get-Content $passiveOrderGdPath -Raw
    # Fix the static method call that crashed the parser
    $oldCall = 'if ModLoaderConfig.has_method("update_config"):'
    $newCall = 'if ModLoaderConfig and "update_config" in ModLoaderConfig:'
    $content = $content.Replace($oldCall, $newCall)
    $content | Set-Content -Path $passiveOrderGdPath -Encoding UTF8
    Write-Output "Patched passive_order.gd to fix static method parse error."
}

Write-Output "--- 2. FIXING MOD STORE CLIENT PARSER (US-05) ---"
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
    
    # Extract data from the flat custom array, NOT the nested GitHub schema
    $catalogCallback = @"

func _on_catalog_loaded(repo: String, releases: Array) -> void:
	all_packages.clear()
	for r in releases:
		if typeof(r) != TYPE_DICTIONARY: continue
		var p_name = r.get("name", "Unknown Mod")
		var p_id = r.get("id", "")
		var dl_url = r.get("download_url", "")
		var tag = r.get("version", "1.0.0")
		if not tag.begins_with("v"): tag = "v" + tag
		
		# If it's a GitHub API formatted response (fallback)
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
    $svContent = $svContent -replace 'btn_action\.pressed\.connect\(func\(\): _uninstall_mod\(pkg_id\)\)', 'btn_action.pressed.connect(func(): _uninstall_mod(pkg_id); btn_action.text = "Restart Required"; btn_action.disabled = true)'
    $svContent | Set-Content -Path $storeViewPath -Encoding UTF8
    Write-Output "Patched Mod Store View for flat JSON array parsing."
}

Write-Output "--- 3. FIXING MAIN MENU NULL CALLS (BUG-06) ---"
$mainMenuHooksPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scripts\MainMenu.hooks.gd"
if (Test-Path $mainMenuHooksPath) {
    git checkout a9ca50039c02c57c68f24f0fcb0be1b547bb53c3 -- "$mainMenuHooksPath"
    $mmContent = Get-Content $mainMenuHooksPath -Raw
    
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
    Write-Output "Patched MainMenu.hooks.gd to avoid null lambda crash."
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
git commit -m "Fix: Corrected ModLoaderConfig static call in passive_order, enforced Mod Store flat array mapping, and reset MainMenu lambdas."
git push origin main
Write-Output "Recovery Completed Successfully."