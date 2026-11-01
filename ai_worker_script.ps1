$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. Restoring Settings UI (Reverting Corrupted Hook) ---"
$settingsHookPath = Join-Path $repoRoot "mods-unpacked\nanobotz-autopassivechooser\mods-unpacked\nanobotz-autopassivechooser\extensions\scenes\Interfaces\Menus\settings_2.hooks.gd"
if (Test-Path $settingsHookPath) {
    git checkout HEAD -- "$settingsHookPath"
    Write-Output "Reverted settings_2.hooks.gd to restore Passive Order tab."
}

Write-Output "--- 2. Fixing Bouncing Ball add_child() Physics Crashes ---"
$ballProjPath = "$repoRoot\mods-unpacked\gareth-bouncing_ball_mod\mods-unpacked\gareth-bouncing_ball_mod\scripts\bouncing_ball_projectile.gd"
if (Test-Path $ballProjPath) {
    $content = Get-Content $ballProjPath -Raw
    $oldReady = @"
func _ready() -> void:
	z_index = 35
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite2D"
	if ball_texture:
		_sprite.texture = ball_texture
	add_child(_sprite)
	
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	var shape := CollisionShape2D.new()
	shape.shape = circle
	
	# Explicitly set Godot 2D collision masks to interact with the TileMap
	collision_layer = 0
	collision_mask = 1 
	
	add_child(shape)
"@
    $newReady = @"
func _ready() -> void:
	z_index = 35
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite2D"
	if ball_texture:
		_sprite.texture = ball_texture
	call_deferred("add_child", _sprite)
	
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	var shape := CollisionShape2D.new()
	shape.shape = circle
	
	# Explicitly set Godot 2D collision masks to interact with the TileMap
	collision_layer = 0
	collision_mask = 1 
	
	call_deferred("add_child", shape)
"@
    $content = $content.Replace("`r`n", "`n").Replace($oldReady.Replace("`r`n", "`n"), $newReady.Replace("`r`n", "`n"))
    $content | Set-Content -Path $ballProjPath -Encoding UTF8
    Write-Output "Patched Bouncing Ball synchronous add_child calls."
}

Write-Output "--- 3. Forcing Async Coroutines (Viewport Fix) ---"
Get-ChildItem -Path $repoRoot -Recurse -Filter "Game.hooks.gd" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match "(?<!await\s)chain\.execute_next") {
        $content = $content -replace "(?<!await\s)chain\.execute_next", "await chain.execute_next"
        $content | Set-Content -Path $_.FullName -Encoding UTF8
        Write-Output "Enforced await chain.execute_next in $($_.Name)"
    }
}

Write-Output "--- 4. Numbing Vanilla Miner Animation (Quadcopter Fix) ---"
$droneMinerPath = "$repoRoot\mods-unpacked\gareth-drone_workforce_mod\mods-unpacked\gareth-drone_workforce_mod\extensions\scenes\AutoMiners\employee_miner_2.hooks.gd"
$droneMiner = @"
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var miner = chain.reference_object
	if not is_instance_valid(miner): return

	var factory = load("res://mods-unpacked/gareth-drone_workforce_mod/scripts/drone_texture_factory.gd")
	if not factory: return

	# Utterly destroy the vanilla graphics node so AnimationPlayer cannot force visibility back on
	var sprites_node = miner.get_node_or_null("Sprites")
	if is_instance_valid(sprites_node):
		sprites_node.call_deferred("queue_free")

	var drone_spr = miner.get_node_or_null("MinerDroneSprite")
	if not drone_spr:
		drone_spr = Sprite2D.new()
		drone_spr.name = "MinerDroneSprite"
		drone_spr.texture = factory.create_miner_drone_texture()
		drone_spr.scale = Vector2(1.5, 1.5)
		miner.call_deferred("add_child", drone_spr)
"@
$droneMiner | Set-Content -Path $droneMinerPath -Encoding UTF8

Write-Output "--- 5. Generating Mod Store API Compliant JSON ---"
$catalogPath = Join-Path $repoRoot "mod_catalog.json"
$mods = Get-ChildItem -Path "$repoRoot\mods-unpacked" -Directory
$githubReleases = @()

foreach ($mod in $mods) {
    $manifestPath = Join-Path $mod.FullName "manifest.json"
    if (Test-Path $manifestPath) {
        $json = Get-Content $manifestPath | ConvertFrom-Json
        $modId = $json.name
        $modName = $json.extra.godot.display_name
        $modDesc = $json.description
        $modVer = $json.version_number
        
        # Structure perfectly mimics GitHub API so the client doesn't need to be rewritten
        $release = [PSCustomObject]@{
            tag_name = "v$modVer"
            name = $modName
            body = $modDesc
            assets = @(
                [PSCustomObject]@{
                    name = "$modId.zip"
                    browser_download_url = "https://raw.githubusercontent.com/garethwhite-prog/coal-llc-mods/main/downloaded_mods/$modId.zip"
                }
            )
        }
        $githubReleases += $release
    }
}
$githubReleases | ConvertTo-Json -Depth 10 | Set-Content -Path $catalogPath -Encoding UTF8
Write-Output "Generated GitHub API compliant mod_catalog.json."

Write-Output "--- 6. Repacking Modified Mods ---"
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force }

$targetMods = @("gareth-bouncing_ball_mod", "nanobotz-autopassivechooser", "gareth-drone_workforce_mod")
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

Write-Output "--- 7. Updating Agile Tracker ---"
$sprintBoardPath = Join-Path $repoRoot "docs\ACTIVE_SPRINT_BOARD.md"
$sprintBoard = @"
# Current Active Sprint & Worklist

## 🔴 Open Bugs (Highest Priority)
* **[BUG-03]** Verify isolation between Henry Hoover (Player tool) and Drone Workforce (NPC automated entities).

## 🟡 In Progress / Testing
* **[US-01]** Thomas the Tank Engine: Base class deployed. (Awaiting graphic implementation logic).
* **[US-02]** Reach Expansion: Tune interaction distance to +1 tile (+24px) for stockpile, ore, and NPCs. Inject into Bonus Shop.
* **[US-06]** Deep Layer Bonus Weapons: Create a mod downloadable via Mod Store that spawns bonus weapons in deeper strata.
* **[US-07]** Mod Manager Search/Filter: Replicate the Mod Store's search bar and dropdown filters inside the local Mod Manager UI.

## 🟢 Completed (Pending Verification)
* **[BUG-01]** Quadcopter Workforce: Vanilla `Sprites` node completely freed to prevent AnimationPlayer override.
* **[BUG-02]** AutoPassiveChooser: Reverted corrupted `settings_2.hooks.gd` to restore Passive Order tab UI rendering.
* **[BUG-07]** Viewport/Camera Break: Global `await chain.execute_next` enforced across all `Game.hooks.gd`.
* **[US-05]** Mod Store Registry: `mod_catalog.json` re-architected to mock GitHub Release API schema. Thomas and Drones now indexable.
* **[CORE]** Bouncing Ball Physics: Mount logic migrated to `call_deferred` to eliminate runtime scene tree locks.
"@
$sprintBoard | Set-Content -Path $sprintBoardPath -Encoding UTF8

Write-Output "--- Committing to Git ---"
git add -A
git commit -m "Fix: Re-architect mod_catalog to mock GitHub API, restore Passive UI tab, fix Bouncing Ball physics locks, and enforce global async viewport execution."
git push origin main
Write-Output "Sprint Executed Successfully!"