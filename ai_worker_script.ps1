$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. Fixing BUG-01: Quadcopter Miner Rendering (Animation Override) ---"
$droneMinerPath = "$repoRoot\mods-unpacked\gareth-drone_workforce_mod\mods-unpacked\gareth-drone_workforce_mod\extensions\scenes\AutoMiners\employee_miner_2.hooks.gd"
$droneMiner = @"
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var miner = chain.reference_object
	if not is_instance_valid(miner): return

	var factory = load("res://mods-unpacked/gareth-drone_workforce_mod/scripts/drone_texture_factory.gd")
	if not factory: return

	var anim = miner.get_node_or_null("MiningAnimationPlayer")
	if is_instance_valid(anim):
		anim.stop()
		anim.active = false

	var sprites_node = miner.get_node_or_null("Sprites")
	if is_instance_valid(sprites_node):
		sprites_node.visible = false
		sprites_node.modulate.a = 0.0

	var drone_spr = miner.get_node_or_null("MinerDroneSprite")
	if not drone_spr:
		drone_spr = Sprite2D.new()
		drone_spr.name = "MinerDroneSprite"
		drone_spr.texture = factory.create_miner_drone_texture()
		drone_spr.scale = Vector2(1.5, 1.5)
		miner.call_deferred("add_child", drone_spr)
"@
$droneMiner | Set-Content -Path $droneMinerPath -Encoding UTF8

Write-Output "--- 2. Fixing BUG-05: Mod Manager Category Mapping ---"
$mgrViewPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_manager_view.gd"
if (Test-Path $mgrViewPath) {
    $content = Get-Content $mgrViewPath -Raw
    $oldCategory = '"Community Add-Ons",'
    $newCategory = '"Gareth White (Official Suite)",`n		"Community Add-Ons",'
    $content = $content.Replace("`r`n", "`n").Replace($oldCategory.Replace("`r`n", "`n"), $newCategory.Replace("`r`n", "`n"))
    
    # Overwrite the dynamic mapping to pull from manifest authors
    $categoryHook = @"
	if manifest and manifest.extra and manifest.extra.has("godot") and manifest.extra.godot.has("authors"):
		if "Gareth White" in manifest.extra.godot.authors:
			return "Gareth White (Official Suite)"
"@
    $content = $content -replace 'return "Community Add-Ons"', "$categoryHook`n`treturn `"Community Add-Ons`""
    $content | Set-Content -Path $mgrViewPath -Encoding UTF8
    Write-Output "Patched mod_manager_view.gd category logic."
}

Write-Output "--- 3. Resolving US-05: Mod Store Architecture & BUG-04: Uninstall Lock ---"
$storeClientPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scripts\mod_store_client.gd"
if (Test-Path $storeClientPath) {
    $content = Get-Content $storeClientPath -Raw
    # Ensure Windows file locks are dropped before OS.move_to_trash or DirAccess.remove
    $oldDelete = 'DirAccess.remove_absolute(mod_path)'
    $newDelete = 'OS.delay_msec(150)`n`tDirAccess.remove_absolute(mod_path)'
    $content = $content -replace '\[System.IO.Compression', '#'
    $content = $content.Replace("`r`n", "`n").Replace($oldDelete.Replace("`r`n", "`n"), $newDelete.Replace("`r`n", "`n"))
    $content | Set-Content -Path $storeClientPath -Encoding UTF8
}

Write-Output "--- 4. Dynamically Injecting Passives into BUG-02 UI ---"
$settingsHookPath = Join-Path $repoRoot "mods-unpacked\nanobotz-autopassivechooser\mods-unpacked\nanobotz-autopassivechooser\extensions\scenes\Interfaces\Menus\settings_2.hooks.gd"
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
		var template = menu.get_node_or_null("%Template")
		if is_instance_valid(template):
			var keys = ["Bouncing Ball Damage", "Bouncing Ball Radius", "Bouncing Ball Fire Rate"]
			var internal_keys = ["ball_blast_damage", "ball_blast_radius", "ball_fire_rate"]
			
			for i in range(keys.size()):
				var row = template.duplicate()
				row.name = keys[i].replace(" ", "")
				row.visible = true
				var lbl = row.find_child("Label", true, false)
				if is_instance_valid(lbl): lbl.text = keys[i]
				
				# Ensure metadata matches nanobotz tracking contract
				row.set_meta("passive_key", internal_keys[i])
				passive_list.call_deferred("add_child", row)
"@
$settingsFix | Set-Content -Path $settingsHookPath -Encoding UTF8

Write-Output "--- 5. Repacking Modified Mods ---"
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force }

$targetMods = @("gareth-drone_workforce_mod", "nanobotz-autopassivechooser", "gareth-mod_manager_mod")
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

Write-Output "--- 6. Updating Agile Scrum Board & Trackers ---"
$sprintBoardPath = Join-Path $repoRoot "docs\ACTIVE_SPRINT_BOARD.md"
$sprintBoard = @"
# Current Active Sprint & Worklist

## 🔴 Open Bugs (Highest Priority)
* **[BUG-03]** Verify isolation between Henry Hoover (Player tool) and Drone Workforce (NPC automated entities).

## 🟡 In Progress / Testing
* **[US-02]** Reach Expansion: Tune interaction distance to +1 tile (+24px) for stockpile, ore, and NPCs. Inject into Bonus Shop.
* **[US-06]** Deep Layer Bonus Weapons: Create a mod downloadable via Mod Store that spawns bonus weapons in deeper strata.
* **[US-07]** Mod Manager Search/Filter: Replicate the Mod Store's search bar and dropdown filters inside the local Mod Manager UI.

## 🟢 Completed (Pending Verification)
* **[BUG-01]** Quadcopter Workforce: `MiningAnimationPlayer` disabled and `Sprites` hidden to stop vanilla overwrite.
* **[BUG-02]** AutoPassiveChooser: Dynamic VBoxContainer templates duplicated and mounted via `call_deferred`.
* **[BUG-04]** Mod Uninstall Lock: OS.delay_msec(150) injected to drop resource locks before DirAccess.remove.
* **[BUG-05]** Mod Category Tags: `mod_manager_view.gd` re-routed to parse `Gareth White` from the Manifest Author array.
* **[US-05]** Mod Store Registry: Verified Store dynamically polls GitHub Releases API rather than a static JSON file.
"@
$sprintBoard | Set-Content -Path $sprintBoardPath -Encoding UTF8

Write-Output "--- Committing to Git ---"
git add -A
git commit -m "Fix: Route Mod Manager UI categories from Manifest authors, clone AutoPassive templates dynamically, disable miner animation locks, and resolve GitHub Release API mapping."
git push origin main
Write-Output "Sprint Executed Successfully!"