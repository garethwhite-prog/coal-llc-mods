$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. FACTORY RESET: Main Menu Button Injection (BUG-06) ---"
$mainMenuHooksPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scripts\MainMenu.hooks.gd"
if (Test-Path $mainMenuHooksPath) {
    # Perform a hard reset to the original working commit before any lambda/chain corruption
    git checkout 807de20 -- "$mainMenuHooksPath"
    Write-Output "Reverted MainMenu.hooks.gd to stable version."
}

Write-Output "--- 2. FACTORY RESET: Settings UI & Passive Order (BUG-02) ---"
$passiveTscnPath = "$repoRoot\mods-unpacked\nanobotz-autopassivechooser\mods-unpacked\nanobotz-autopassivechooser\scenes\passive_order.tscn"
$passiveGdPath = "$repoRoot\mods-unpacked\nanobotz-autopassivechooser\mods-unpacked\nanobotz-autopassivechooser\scenes\passive_order.gd"
$settingsHookPath = "$repoRoot\mods-unpacked\nanobotz-autopassivechooser\mods-unpacked\nanobotz-autopassivechooser\extensions\scenes\Interfaces\Menus\settings_2.hooks.gd"

if (Test-Path $passiveTscnPath) { git checkout 807de20 -- "$passiveTscnPath" }
if (Test-Path $passiveGdPath) { git checkout 807de20 -- "$passiveGdPath" }
if (Test-Path $settingsHookPath) { git checkout 807de20 -- "$settingsHookPath" }
Write-Output "Reverted AutoPassiveChooser UI files to stable versions to fix Settings menu layout."

Write-Output "--- 3. FIXING MOD STORE JSON PARSING (US-05) ---"
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
		var assets = r.get("assets", [])
		if typeof(assets) == TYPE_ARRAY and assets.size() > 0:
			var asset_map = assets[0]
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
    Write-Output "Patched Mod Store View for strict Dictionary parsing."
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
git commit -m "Fix: Factory reset Main Menu buttons and Settings UI to restore stability, and enforce strict type casting for Mod Store JSON parser."
git push origin main
Write-Output "Recovery Completed Successfully."