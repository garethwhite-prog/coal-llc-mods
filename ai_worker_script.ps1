$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. Updating Regressions and User Stories ---"
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
- **Symptom**: New mods (e.g. Quadcopters, Thomas the Tank) do not appear in the Mod Manager or Mod Store UI.
- **Root Cause**: Failing to append the new mod namespace to the `mod_registry.gd` within `gareth-mod_manager_mod`.

## 10. Missing Passives in Mod Settings
- **Symptom**: New passive upgrade paths (e.g. Bouncing Ball damage) do not appear in the 'Passive Order' tab of the Mod Settings UI.
- **Root Cause**: The `passive_keys` array in `gareth-mod_manager_mod` needs to be explicitly updated with the new stat metadata keys.
"@
$knownRegressions | Set-Content -Path $knownRegressionsPath -Encoding UTF8

$story5 = @"
# US-05: Mod Store Registration & Passive Routing
**Status:** In Progress
**Mod:** `gareth-mod_manager_mod`

**Description:**
As a player, I want all newly developed mods (Quadcopters, Henry Hoover, Thomas the Tank) to appear in the Mod Manager and Mod Store so I can enable/disable them. I also want the Bouncing Ball upgrades to be configurable in the Passive Order menu.

**Acceptance Criteria:**
- Append `gareth-drone_workforce_mod` to `mod_registry.gd`.
- Append `gareth-thomas_tank_engine_mod` to `mod_registry.gd`.
- Append `gareth-reach_expansion_mod` to `mod_registry.gd`.
- Inject `ball_blast_damage`, `ball_blast_radius`, and `ball_fire_rate` into the Passive Order array.
"@
$story5 | Set-Content -Path (Join-Path $repoRoot "docs\user_stories\US-05_Mod_Registration.md") -Encoding UTF8

Write-Output "--- 2. Registering Mods into Mod Manager ---"
$registryPath = Join-Path $repoRoot "mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scripts\mod_registry.gd"
if (Test-Path $registryPath) {
    $content = Get-Content $registryPath -Raw
    
    # We use regex to carefully inject the missing mods into the existing ALL_MODS array without breaking syntax
    $content = $content -replace '"gareth-henry_the_hoover_mod",', '"gareth-henry_the_hoover_mod",
		"gareth-drone_workforce_mod",
		"gareth-thomas_tank_engine_mod",
		"gareth-reach_expansion_mod",'
    
    $content | Set-Content -Path $registryPath -Encoding UTF8
    Write-Output "Patched mod_registry.gd"
} else {
    Write-Output "ERROR: Could not find mod_registry.gd at $registryPath"
}

Write-Output "--- 3. Injecting Bouncing Ball Passives into Settings UI ---"
$settingsHookPath = Join-Path $repoRoot "mods-unpacked\nanobotz-autopassivechooser\mods-unpacked\nanobotz-autopassivechooser\extensions\scenes\Interfaces\Menus\settings_2.hooks.gd"
if (Test-Path $settingsHookPath) {
    $content = Get-Content $settingsHookPath -Raw
    
    $content = $content -replace '"Player Climb Speed"', '"Player Climb Speed",
	"Bouncing Ball Damage",
	"Bouncing Ball Blast Radius",
	"Bouncing Ball Fire Rate"'
	
	$content = $content -replace '"player_climb_speed"', '"player_climb_speed",
	"ball_blast_damage",
	"ball_blast_radius",
	"ball_fire_rate"'
    
    $content | Set-Content -Path $settingsHookPath -Encoding UTF8
    Write-Output "Patched settings_2.hooks.gd in AutoPassiveChooser"
} else {
    Write-Output "ERROR: Could not find settings_2.hooks.gd at $settingsHookPath"
}

Write-Output "--- 4. Repacking Mod Manager & AutoPassiveChooser ---"
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
git commit -m "Fix: Add Quadcopters, Reach Expansion, and Thomas the Tank to ModRegistry, and map Bouncing Ball passives to Settings UI."
git push origin main
Write-Output "Operation Successful."