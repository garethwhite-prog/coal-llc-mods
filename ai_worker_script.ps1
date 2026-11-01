$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. Reverting the Corrupted AutoPassiveChooser UI Scene ---"
$passiveScenePath = "$repoRoot\mods-unpacked\nanobotz-autopassivechooser\mods-unpacked\nanobotz-autopassivechooser\scenes\passive_order.tscn"
if (Test-Path $passiveScenePath) {
    # Restore the tscn file back to its native state to remove the hardcoded ball nodes that crashed Godot
    git checkout a9ca50039c02c57c68f24f0fcb0be1b547bb53c3 -- "$passiveScenePath"
    Write-Output "Restored passive_order.tscn to clear parse errors."
}

Write-Output "--- 2. Injecting Bouncing Ball Passives Safely via Script ---"
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
    Write-Output "Patched settings_2.hooks.gd with safe dynamic duplication."
}

Write-Output "--- 3. Fixing Quadcopter Drones Rendering Pipeline ---"
$droneMinerPath = "$repoRoot\mods-unpacked\gareth-drone_workforce_mod\mods-unpacked\gareth-drone_workforce_mod\extensions\scenes\AutoMiners\employee_miner_2.hooks.gd"
if (Test-Path $droneMinerPath) {
    $droneMiner = @"
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	await chain.execute_next([])
	var miner = chain.reference_object
	if not is_instance_valid(miner): return

	var factory = load("res://mods-unpacked/gareth-drone_workforce_mod/scripts/drone_texture_factory.gd")
	if not factory: return

	# Instead of just hiding, fully delete the Sprites container so the vanilla AnimationPlayer cannot restore visibility
	var sprites_node = miner.get_node_or_null("Sprites")
	if is_instance_valid(sprites_node):
		sprites_node.queue_free()

	var drone_spr = miner.get_node_or_null("MinerDroneSprite")
	if not drone_spr:
		drone_spr = Sprite2D.new()
		drone_spr.name = "MinerDroneSprite"
		drone_spr.texture = factory.create_miner_drone_texture()
		drone_spr.scale = Vector2(1.5, 1.5)
		miner.call_deferred("add_child", drone_spr)
"@
    $droneMiner | Set-Content -Path $droneMinerPath -Encoding UTF8
    Write-Output "Patched Drone Workforce to forcefully free vanilla Sprites."
}

Write-Output "--- 4. Repacking Mod Files ---"
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force }

$targetMods = @("nanobotz-autopassivechooser", "gareth-drone_workforce_mod")
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
git commit -m "Fix: Revert corrupted AutoPassiveChooser tscn file, shift passive injection to dynamic GDScript, and force delete vanilla miner sprites for Drones."
git push origin main
Write-Output "Operation Successful."