$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. GLOBAL STABILITY: Enforcing 'await' on all ModLoader Hooks ---"
Get-ChildItem -Path "$repoRoot\mods-unpacked" -Recurse -Filter "*.hooks.gd" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match "(?<!await\s)chain\.execute_next") {
        $content = $content -replace "(?<!await\s)chain\.execute_next", "await chain.execute_next"
        $content | Set-Content -Path $_.FullName -Encoding UTF8
        Write-Output "Patched async coroutine safety in $($_.Name)"
    }
}

Write-Output "--- 2. US-05 / BUG-04: Mod Store Cache Busting & Uninstall Feedback ---"
$storeClientPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scripts\mod_store_client.gd"
if (Test-Path $storeClientPath) {
    $scContent = Get-Content $storeClientPath -Raw
    # Bypass GitHub cache by appending timestamp
    $oldUrl = 'var url := "https://raw.githubusercontent.com/garethwhite-prog/coal-llc-mods/main/mod_catalog.json"'
    $newUrl = 'var url := "https://raw.githubusercontent.com/garethwhite-prog/coal-llc-mods/main/mod_catalog.json?v=" + str(Time.get_unix_time_from_system())'
    $scContent = $scContent.Replace($oldUrl, $newUrl)
    $scContent | Set-Content -Path $storeClientPath -Encoding UTF8
}

$storeViewPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_store_view.gd"
if (Test-Path $storeViewPath) {
    $svContent = Get-Content $storeViewPath -Raw
    # Update UI to reflect pending deletion
    $oldUninstall = 'client.uninstall_mod(mod.id)'
    $newUninstall = @"
			client.uninstall_mod(mod.id)
			btn.text = "Restart Required"
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5, 1.0)
"@
    $svContent = $svContent.Replace($oldUninstall, $newUninstall)
    $svContent | Set-Content -Path $storeViewPath -Encoding UTF8
}

Write-Output "--- 3. US-07 / BUG-05: Mod Manager Search Bar & Official Tags ---"
$mgrViewPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_manager_view.gd"
if (Test-Path $mgrViewPath) {
    $mvContent = Get-Content $mgrViewPath -Raw
    $tagFix = @"
	if manifest and manifest.get("extra") and manifest.extra.get("godot") and manifest.extra.godot.get("authors"):
		var authors = manifest.extra.godot.authors
		if authors.size() > 0 and typeof(authors[0]) == TYPE_STRING and "Gareth White" in authors[0]:
			return "Gareth White (Official Suite)"
"@
    $mvContent = $mvContent -replace 'if manifest and manifest\.extra and manifest\.extra\.has\("godot"\).*?return "Gareth White \(Official Suite\)"', $tagFix
    
    # Inject dynamic search bar into Mod Manager
    $searchInject = @"
func _ready() -> void:
	call_deferred("_inject_search_bar")
	
func _inject_search_bar() -> void:
	var header = find_child("HeaderContainer", true, false)
	if not header: header = self
	var search = LineEdit.new()
	search.placeholder_text = "Search installed mods..."
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
				var lbl = card.find_child("TitleLabel", true, false)
				if lbl: mod_name += lbl.text.to_lower()
				card.visible = q in mod_name
"@
    $mvContent = $mvContent -replace 'func _ready\(\) -> void:', $searchInject
    $mvContent | Set-Content -Path $mgrViewPath -Encoding UTF8
}

Write-Output "--- 4. BUG-02: Bouncing Ball Passive UI Injection ---"
$settingsHookPath = Join-Path $repoRoot "mods-unpacked\nanobotz-autopassivechooser\mods-unpacked\nanobotz-autopassivechooser\extensions\scenes\Interfaces\Menus\settings_2.hooks.gd"
if (Test-Path $settingsHookPath) {
    $settingsFix = @"
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	await chain.execute_next([])
	var menu = chain.reference_object
	if not is_instance_valid(menu): return
	
	var passive_list = menu.find_child("passive_list", true, false)
	if not is_instance_valid(passive_list):
		passive_list = menu.find_child("VBoxContainer", true, false)
		
	if is_instance_valid(passive_list) and not passive_list.has_node("BouncingBallDamage"):
		var template = menu.get_node_or_null("%Template")
		if not is_instance_valid(template) and passive_list.get_child_count() > 0:
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
}

Write-Output "--- 5. US-06: Bootstrapping Deep Layer Weapons Mod ---"
$deepWeaponsDir = Join-Path $repoRoot "mods-unpacked\gareth-deep_layer_weapons_mod\mods-unpacked\gareth-deep_layer_weapons_mod"
New-Item -Path "$deepWeaponsDir\extensions\scripts" -ItemType Directory -Force | Out-Null

$dlwManifest = @"
{
  "name": "gareth-deep_layer_weapons_mod",
  "namespace": "gareth",
  "version_number": "1.0.0",
  "description": "Injects extreme high-tier weapons into chests spawned deep in the earth (Stratum 50+).",
  "website_url": "https://github.com/garethwhite-prog/coal-llc-mods",
  "dependencies": ["gareth-mod_manager_mod"],
  "extra": {
    "godot": {
      "authors": ["Gareth White"],
      "display_name": "Deep Layer Bonus Weapons",
      "tags": ["gameplay", "loot"],
      "compatible_mod_loader_version": ["7.0.1"],
      "compatible_game_version": ["1.4.1.1"]
    }
  }
}
"@
$dlwManifest | Set-Content -Path "$deepWeaponsDir\manifest.json" -Encoding UTF8
$dlwManifest | Set-Content -Path (Join-Path $repoRoot "mods-unpacked\gareth-deep_layer_weapons_mod\manifest.json") -Encoding UTF8

$dlwMain = @"
extends Node
func _init() -> void:
	ModLoaderMod.install_script_hooks("res://scripts/Chest.gd", "res://mods-unpacked/gareth-deep_layer_weapons_mod/extensions/scripts/Chest.hooks.gd")
	ModLoaderLog.info("Deep Layer Weapons Mod active!", "gareth-deep_layer_weapons_mod")
"@
$dlwMain | Set-Content -Path "$deepWeaponsDir\mod_main.gd" -Encoding UTF8

$dlwChestHook = @"
extends Object
func roll_loot(chain: ModLoaderHookChain) -> void:
	await chain.execute_next([])
	var chest = chain.reference_object
	if is_instance_valid(chest) and Gvars and Gvars.get("level") >= 50:
		if randf() < 0.15: # 15% chance for bonus endgame weapon
			var wep = load("res://scenes/equipment/plasma_raygun.tscn")
			if wep: chest.item_contents = wep
"@
$dlwChestHook | Set-Content -Path "$deepWeaponsDir\extensions\scripts\Chest.hooks.gd" -Encoding UTF8

Write-Output "--- 6. Generating Central Mod Catalog & Repacking ---"
$catalogPath = Join-Path $repoRoot "mod_catalog.json"
$mods = Get-ChildItem -Path "$repoRoot\mods-unpacked" -Directory
$githubReleases = @()

foreach ($mod in $mods) {
    $manifestPath = Join-Path $mod.FullName "manifest.json"
    if (Test-Path $manifestPath) {
        $json = Get-Content $manifestPath | ConvertFrom-Json
        $release = [PSCustomObject]@{
            tag_name = "v$($json.version_number)"
            name = $json.extra.godot.display_name
            body = $json.description
            assets = @( [PSCustomObject]@{ name = "$($json.name).zip"; browser_download_url = "https://raw.githubusercontent.com/garethwhite-prog/coal-llc-mods/main/downloaded_mods/$($json.name).zip" } )
        }
        $githubReleases += $release
    }
}
$githubReleases | ConvertTo-Json -Depth 10 | Set-Content -Path $catalogPath -Encoding UTF8

$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force }

$targetMods = @("gareth-mod_manager_mod", "nanobotz-autopassivechooser", "gareth-deep_layer_weapons_mod")
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

Write-Output "--- 7. Updating Agile Scrum Board ---"
$sprintBoardPath = Join-Path $repoRoot "docs\ACTIVE_SPRINT_BOARD.md"
$sprintBoard = @"
# Current Active Sprint & Worklist

## 🔴 Open Bugs (Highest Priority)
* **[BUG-03]** Verify isolation between Henry Hoover (Player tool) and Drone Workforce (NPC automated entities).

## 🟡 In Progress / Testing
* **[US-01]** Thomas the Tank Engine: Base class deployed. (Awaiting graphic implementation logic).
* **[US-02]** Reach Expansion: Tune interaction distance to +1 tile (+24px) for stockpile, ore, and NPCs. Inject into Bonus Shop.

## 🟢 Completed (Pending Verification)
* **[US-06]** Deep Layer Bonus Weapons: Mod scaffolded and hooked to `Chest.gd` to drop plasma rayguns past depth 50.
* **[US-07]** Mod Manager Search: `LineEdit` search bar dynamically injected via `call_deferred`.
* **[US-05]** Mod Store Cache: Cache-buster timestamp appended to GitHub raw JSON url.
* **[BUG-04]** Mod Uninstall: Store UI now correctly changes to "Restart Required" to reflect OS file locks.
* **[BUG-02]** Passives UI: Bouncing Ball passives forcibly duplicated from VBox templates and added to Settings tree.
* **[BUG-07]** Viewport/Camera Break: Global `await chain.execute_next` enforced across ALL `.hooks.gd` files.
"@
$sprintBoard | Set-Content -Path $sprintBoardPath -Encoding UTF8

Write-Output "--- Committing to Git ---"
git add -A
git commit -m "Feature & Fixes: Enforce global async awaits, deploy Deep Layer Weapons, inject Mod Manager search, and break GitHub raw cache."
git push origin main
Write-Output "Sprint Executed Successfully!"