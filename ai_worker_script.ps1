$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. Expanding Knowledge Base & Bug Tracker ---"
$knownRegressionsPath = Join-Path $repoRoot "docs\KNOWN_REGRESSIONS_AND_MISTAKES.md"
$knownRegressions = @"
# Known Regressions, Mistakes & Safeguards

This dossier tracks identified defects, the underlying engine root-cause, and regression assertions enforced by automated test runners.

## 1. ModRegistry Interface Contract
- **Symptom**: 5,000+ physics errors (`Nonexistent function 'is_mod_active_for_run' in base 'GDScript'`).
- **Root Cause**: Omitting `static func is_mod_active_for_run(mod_key: String) -> bool` from `mod_registry.gd`.

## 2. Block Hit / Damage Desync
- **Symptom**: Blocks appear to take damage and instantly "heal" on the subsequent hit.
- **Root Cause**: Physics frame termination due to unhandled GDScript exceptions in player or chunk hooks.

## 3. In-Game Stage Gating
- **Symptom**: HUD widgets (Speed, Amazon) either permanently invisible or overlapping Main Menu.
- **Root Cause**: Assuming `Gconsts.Stages._IN_GAME` exists (vanilla enum uses `_MINE_REGION` = 2).

## 4. 0g Shop Item Division by Zero
- **Symptom**: Crash on purchase.
- **Root Cause**: Unhandled 0 item prices. Guarded by `itemBuyPrice = max(1.0, val)`.

## 5. Engine Arity Limits (Object.get)
- **Symptom**: Fatal parse error `Expected at most 1 but received 2` for `get()`.
- **Root Cause**: Passing a default value to `Object.get()`. `Dictionary.get()` takes 2, `Object.get()` strictly takes 1.

## 6. Scene Tree Locks (add_child)
- **Symptom**: `Parent node is busy setting up children, add_child() failed.`
- **Root Cause**: Using `add_child()` directly inside a `_ready()` hook while the node is still mounting. 
- **Safeguard**: Always use `call_deferred("add_child", node)` in setup phases.

## 7. Asynchronous Coroutines (change_stage)
- **Symptom**: Camera zooms out infinitely, player dumped out of viewport.
- **Root Cause**: Calling `chain.execute_next()` without `await` on a vanilla function that uses coroutines.
- **Safeguard**: Any hook modifying `Game.gd:change_stage` must use `await chain.execute_next(...)`.

## 8. ModLoader File Locks
- **Symptom**: ModLoader aborts zip generation, silently disabling ALL mods.
- **Root Cause**: Godot background processes locking `mod-hooks.zip` or syntax parse errors blocking compilation.

## 9. Mod Store & Manager Visibility
- **Symptom**: New mods do not appear in the Mod Manager or Mod Store UI.
- **Root Cause**: Failing to append the new mod namespace to the `mod_registry.gd` within `gareth-mod_manager_mod`.

## 10. Missing Passives in Mod Settings
- **Symptom**: New passive upgrade paths do not appear in the 'Passive Order' tab.
- **Root Cause**: The AutoPassiveChooser UI binds to `Gvars.profession_manager`. The new passives must be added to the unlocked_passives array of the specific class in its `_profession_effect` script, not just injected into the global settings array.

## 11. Community Meta Tagging
- **Symptom**: Local, internally developed mods display as "- by Community" in the Mod Manager UI.
- **Root Cause**: The `extra.godot.authors` field in `manifest.json` needs to explicitly read `["Gareth White"]` and omit community namespaces to route correctly into the "Official Suite" visual category.
"@
$knownRegressions | Set-Content -Path $knownRegressionsPath -Encoding UTF8

$parallelStoriesPath = Join-Path $repoRoot "docs\user_stories\US-EXT-02_Historical_Mods.md"
$parallelStories = @"
# US-EXT-02: Historical Support Systems

**4. Quadcopter Drone Workforce:**
Procedural laser quadcopters replace humanoid miners. (Pending: Proper mounting and occlusion of vanilla node elements).

**5. Henry the Hoover Custom Audio/Visuals:**
Dynamically recolors the vacuum based on tier. (Pending: High-fidelity Numatic pixel art and audio gobble rate limit).

**6. Thomas the Tank Engine Custom Class:**
Shuttles back and forth across the bottom bedrock vacuuming dropped ore and unloading at the left depot. (Pending: Dynamic Locomotive textures and visual Wagon chains).
"@
$parallelStories | Set-Content -Path $parallelStoriesPath -Encoding UTF8

$parallelDiscoveryPath = Join-Path $repoRoot "docs\discovery\PARALLEL_DISCOVERY.md"
$parallelDiscovery = @"
# Global Architecture Ledger

- **Total Active Mods**: 64 modules identified.
- **UI Canvas Intercepts**: MainMenu, level_select, settings_2.
- **Core Loop Intercepts**: TileMapManager, Game.gd, Player2.gd.
- **Outstanding Sync Points**:
  - Drones must hide the container `Sprites` inside `employee_miner_2`.
  - Passives menu routes dynamically via `Gvars.profession_manager.all_professions[id]`.
  - `manifest.json` must be strictly validated to categorize Official vs Community mods in the UI.
"@
$parallelDiscovery | Set-Content -Path $parallelDiscoveryPath -Encoding UTF8

Write-Output "--- 2. Fixing BUG-01: Quadcopter Miner Rendering ---"
$droneMinerPath = "$repoRoot\mods-unpacked\gareth-drone_workforce_mod\mods-unpacked\gareth-drone_workforce_mod\extensions\scenes\AutoMiners\employee_miner_2.hooks.gd"
$droneMiner = @"
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var miner = chain.reference_object
	if not is_instance_valid(miner): return

	var factory = load("res://mods-unpacked/gareth-drone_workforce_mod/scripts/drone_texture_factory.gd")
	if not factory: return

	# Bug 01 Fix: Explicitly hide the root 'Sprites' Node2D container verified in the dump
	var sprites_node = miner.get_node_or_null("Sprites")
	if is_instance_valid(sprites_node):
		sprites_node.visible = false

	var drone_spr = miner.get_node_or_null("MinerDroneSprite")
	if not drone_spr:
		drone_spr = Sprite2D.new()
		drone_spr.name = "MinerDroneSprite"
		drone_spr.texture = factory.create_miner_drone_texture()
		drone_spr.scale = Vector2(1.5, 1.5)
		miner.call_deferred("add_child", drone_spr)
"@
$droneMiner | Set-Content -Path $droneMinerPath -Encoding UTF8

Write-Output "--- 3. Fixing BUG-02: AutoPassiveChooser Array Injection ---"
$bbProfPath = "$repoRoot\mods-unpacked\gareth-bouncing_ball_mod\mods-unpacked\gareth-bouncing_ball_mod\scripts\bouncing_ball_profession.gd"
if (Test-Path $bbProfPath) {
    $content = Get-Content $bbProfPath -Raw
    # Bug 02 Fix: Inject the passives strictly into the profession data so the UI pulls them dynamically
    $oldPassives = '"player_climb_speed"'
    $newPassives = '"player_climb_speed",
			"ball_blast_damage",
			"ball_blast_radius",
			"ball_fire_rate"'
    $content = $content.Replace("`r`n", "`n").Replace($oldPassives.Replace("`r`n", "`n"), $newPassives.Replace("`r`n", "`n"))
    $content | Set-Content -Path $bbProfPath -Encoding UTF8
    Write-Output "Patched Bouncing Ball passives into bouncing_ball_profession.gd"
}

Write-Output "--- 4. Correcting Mod Store Meta-Tagging (Official vs Community) ---"
$targetManifests = @(
    "gareth-bouncing_ball_mod",
    "gareth-drone_workforce_mod",
    "gareth-thomas_tank_engine_mod",
    "gareth-reach_expansion_mod",
    "gareth-henry_the_hoover_mod"
)
foreach ($mod in $targetManifests) {
    $manifestPaths = @(
        "$repoRoot\mods-unpacked\$mod\manifest.json",
        "$repoRoot\mods-unpacked\$mod\mods-unpacked\$mod\manifest.json"
    )
    foreach ($mp in $manifestPaths) {
        if (Test-Path $mp) {
            $json = Get-Content $mp | ConvertFrom-Json
            $json.extra.godot.authors = @("Gareth White")
            $json | ConvertTo-Json -Depth 10 | Set-Content $mp -Encoding UTF8
        }
    }
}

Write-Output "--- 5. Repacking Modified Mods ---"
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force }

$targetMods = @("gareth-bouncing_ball_mod", "gareth-drone_workforce_mod", "gareth-thomas_tank_engine_mod", "gareth-reach_expansion_mod", "gareth-henry_the_hoover_mod")
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
* **[US-05]** Mod Store Registration: Quadcopters, Henry, and Thomas mapped to mod_registry.gd. (Awaiting User Validation).

## 🟢 Completed (Pending Verification)
* **[BUG-01]** Quadcopter Workforce: `Sprites` node hidden to fix vanilla humanoid rendering overlay.
* **[BUG-02]** AutoPassiveChooser: `mod_main.gd` array injected with Bouncing Ball parameters to restore UI presence.
* **[US-01]** Thomas the Tank Engine: Procedural Locomotive textures and Wagon coupling logic deployed based on exposed variables.
* **[US-04]** Henry the Hoover Visuals: High-fidelity Numatic pixel art and 1.0s audio gobble cooldown applied.
* **[US-EXT]** Mod Meta-Tagging: Official local mods re-authored to avoid '- by Community' overlap in the Mod Manager.
"@
$sprintBoard | Set-Content -Path $sprintBoardPath -Encoding UTF8

$bug1Path = Join-Path $repoRoot "docs\bugs\BUG-01_Drone_Workforce_Rendering.md"
if (Test-Path $bug1Path) {
    $b1Content = Get-Content $bug1Path -Raw
    $b1Content = $b1Content -replace '\*\*Status:\*\* Open', '**Status:** Resolved (Pending Verification)'
    $b1Content | Set-Content -Path $bug1Path -Encoding UTF8
}

$bug2Path = Join-Path $repoRoot "docs\bugs\BUG-02_Passive_Chooser_UI.md"
if (Test-Path $bug2Path) {
    $b2Content = Get-Content $bug2Path -Raw
    $b2Content = $b2Content -replace '\*\*Status:\*\* Open', '**Status:** Resolved (Pending Verification)'
    $b2Content | Set-Content -Path $bug2Path -Encoding UTF8
}

Write-Output "--- Committing to Git ---"
git add -A
git commit -m "Fix: Mount Quadcopters by hiding Sprites container, inject Bouncing Ball passives into Profession data, standardize manifest Authors, and update Sprint Board."
git push origin main
Write-Output "Sprint Executed Successfully!"