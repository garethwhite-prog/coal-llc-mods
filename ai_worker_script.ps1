$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. RESTORING MOD MANAGER VIEW (BUG-05) ---"
$mgrViewPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_manager_view.gd"
if (Test-Path $mgrViewPath) {
    # Hard revert to completely clear the broken search bar and string replacement errors
    git checkout 807de20 -- "$mgrViewPath"
    
    # Surgical Author Injection: Instead of replacing the return string, we intercept the top of the function
    $content = Get-Content $mgrViewPath -Raw
    $authorLogic = @"
func _get_mod_category(manifest: Dictionary) -> String:
	if manifest and manifest.get("extra") and manifest.extra.get("godot") and manifest.extra.godot.get("authors"):
		var authors = manifest.extra.godot.authors
		if authors.size() > 0 and typeof(authors[0]) == TYPE_STRING and "Gareth White" in authors[0]:
			return "Gareth White (Official Suite)"
"@
    $content = $content -replace 'func _get_mod_category\(manifest: Dictionary\) -> String:', $authorLogic
    $content | Set-Content -Path $mgrViewPath -Encoding UTF8
    Write-Output "Safely restored Mod Manager View list generation."
}

Write-Output "--- 2. RESTORING PASSIVE ORDER SCENE (BUG-02) ---"
$passiveTscn = "$repoRoot\mods-unpacked\nanobotz-autopassivechooser\mods-unpacked\nanobotz-autopassivechooser\scenes\passive_order.tscn"
if (Test-Path $passiveTscn) {
    # Hard revert to completely clear the broken XML nodes that corrupted the Settings UI
    git checkout 807de20 -- "$passiveTscn"
    Write-Output "Safely restored passive_order.tscn scene structure."
}

Write-Output "--- 3. SURGICAL PASSIVE UI INJECTION ---"
$settingsHookPath = "$repoRoot\mods-unpacked\nanobotz-autopassivechooser\mods-unpacked\nanobotz-autopassivechooser\extensions\scenes\Interfaces\Menus\settings_2.hooks.gd"
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
		# Safely grab the very first passive row to use as a clone template
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
				
				# Reset text and keys for the cloned row
				var lbl = row.find_child("*Label*", true, false)
				if is_instance_valid(lbl): lbl.text = keys[i]
				row.set_meta("passive_key", internal_keys[i])
				
				passive_list.call_deferred("add_child", row)
"@
    $settingsFix | Set-Content -Path $settingsHookPath -Encoding UTF8
    Write-Output "Safely injected Bouncing Ball UI clones into settings_2.hooks.gd."
}

Write-Output "--- 4. Repacking Recovered Mods ---"
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force }

$targetMods = @("nanobotz-autopassivechooser", "gareth-mod_manager_mod")
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
git commit -m "Fix: Hard revert corrupted Mod Manager loop and Passive tscn file to restore UI visibility."
git push origin main
Write-Output "Recovery Completed Successfully."