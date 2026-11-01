$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. Restoring Mod Manager View Logic (BUG-05) ---"
$mgrViewPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_manager_view.gd"
if (Test-Path $mgrViewPath) {
    # Perform a hard reset to the original golden version of the file
    git checkout a9ca50039c02c57c68f24f0fcb0be1b547bb53c3 -- "$mgrViewPath"
    
    # Safely inject the search bar ONLY into _ready
    $content = Get-Content $mgrViewPath -Raw
    $content = $content -replace 'func _ready\(\) -> void:', "func _ready() -> void:`n`tcall_deferred(`"_inject_search_bar`")"
    
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
"@
    $content = $content + $searchLogic
    
    # Fix the community tags safely
    $authorLogic = @"
	if manifest and manifest.get("extra") and manifest.extra.get("godot") and manifest.extra.godot.get("authors"):
		var authors = manifest.extra.godot.authors
		if authors.size() > 0 and typeof(authors[0]) == TYPE_STRING and "Gareth White" in authors[0]:
			return "Gareth White (Official Suite)"
	return "Community Add-Ons"
"@
    $content = $content -replace 'return "Community Add-Ons"', $authorLogic
    $content | Set-Content -Path $mgrViewPath -Encoding UTF8
    Write-Output "Restored mod_manager_view.gd list iteration and search bar."
}

Write-Output "--- 2. Enforcing Pending Deletions at Boot (BUG-04) ---"
$mainMenuHooksPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scripts\MainMenu.hooks.gd"
if (Test-Path $mainMenuHooksPath) {
    $mmContent = Get-Content $mainMenuHooksPath -Raw
    $purgeLogic = @"
func _ready(chain: ModLoaderHookChain) -> void:
	_process_pending_deletions()
	await chain.execute_next([])

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
    $mmContent = $mmContent -replace 'func _ready\(chain: ModLoaderHookChain\) -> void:\s*await chain\.execute_next\(\[\]\)', $purgeLogic
    $mmContent | Set-Content -Path $mainMenuHooksPath -Encoding UTF8
    Write-Output "Injected pending deletion flush into MainMenu _ready."
}

Write-Output "--- 3. Re-Architecting Mod Store JSON Polling (US-05) ---"
$storeClientPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scripts\mod_store_client.gd"
if (Test-Path $storeClientPath) {
    git checkout a9ca50039c02c57c68f24f0fcb0be1b547bb53c3 -- "$storeClientPath"
    $scContent = Get-Content $storeClientPath -Raw
    
    # Change URL strictly to the static JSON catalog and bypass GitHub API format limits
    $oldUrlLogic = 'var url := "https://api.github.com/repos/%s/releases" % repo'
    $newUrlLogic = 'var url := "https://raw.githubusercontent.com/garethwhite-prog/coal-llc-mods/main/mod_catalog.json?v=" + str(Time.get_unix_time_from_system())'
    $scContent = $scContent.Replace($oldUrlLogic, $newUrlLogic)
    
    # Update parsing to read our flat catalog array directly, bypassing the "assets" nested schema
    $scContent = $scContent -replace 'for asset in release\["assets"\]:', 'if true:'
    $scContent = $scContent -replace 'var asset_name = asset\["name"\]', 'var asset_name = release.get("name", "") + ".zip"'
    $scContent = $scContent -replace 'var download_url = asset\["browser_download_url"\]', 'var download_url = release.get("download_url", "")'
    $scContent = $scContent -replace 'if asset_name\.get_extension\(\) == "zip":', 'if download_url != "":'
    
    $scContent | Set-Content -Path $storeClientPath -Encoding UTF8
    Write-Output "Patched mod_store_client.gd to map custom catalog array."
}

Write-Output "--- 4. Dynamically Injecting Passives via GDScript (BUG-02) ---"
$settingsHookPath = "$repoRoot\mods-unpacked\nanobotz-autopassivechooser\mods-unpacked\nanobotz-autopassivechooser\extensions\scenes\Interfaces\Menus\settings_2.hooks.gd"
if (Test-Path $settingsHookPath) {
    $settingsFix = @"
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	await chain.execute_next([])
	var menu = chain.reference_object
	if not is_instance_valid(menu): return
	
	var passive_list = menu.find_child("passive_list", true, false)
	if not is_instance_valid(passive_list): return
	
	if not passive_list.has_node("BouncingBallDamage"):
		var template = null
		for c in passive_list.get_children():
			if c is Control: 
				template = c
				break
				
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
    Write-Output "Injected UI Nodes dynamically via settings_2.hooks.gd"
}

Write-Output "--- 5. Repacking Modified Mods ---"
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
git commit -m "Fix: Restore Mod Manager UI generation, map Mod Store parser to raw custom JSON array, and flush pending deletion zips at Main Menu boot."
git push origin main
Write-Output "Sprint Executed Successfully!"