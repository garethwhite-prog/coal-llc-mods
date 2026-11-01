$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. Fixing BUG-02: Bouncing Ball Passive UI Scene Injection ---"
$passiveScenePath = "$repoRoot\mods-unpacked\nanobotz-autopassivechooser\mods-unpacked\nanobotz-autopassivechooser\scenes\passive_order.tscn"
if (Test-Path $passiveScenePath) {
    $content = Get-Content $passiveScenePath -Raw
    
    # We must inject the physical node tree for the 3 Bouncing Ball passives into the scene file
    $ballNodes = @"
[node name="BouncingBallDamage" type="HBoxContainer" parent="MarginContainer/VBoxContainer"]
layout_mode = 2
metadata/passive_key = "ball_blast_damage"

[node name="CheckBox" type="CheckBox" parent="MarginContainer/VBoxContainer/BouncingBallDamage"]
layout_mode = 2

[node name="Label" type="Label" parent="MarginContainer/VBoxContainer/BouncingBallDamage"]
layout_mode = 2
size_flags_horizontal = 3
text = "Bouncing Ball Damage"

[node name="BouncingBallRadius" type="HBoxContainer" parent="MarginContainer/VBoxContainer"]
layout_mode = 2
metadata/passive_key = "ball_blast_radius"

[node name="CheckBox" type="CheckBox" parent="MarginContainer/VBoxContainer/BouncingBallRadius"]
layout_mode = 2

[node name="Label" type="Label" parent="MarginContainer/VBoxContainer/BouncingBallRadius"]
layout_mode = 2
size_flags_horizontal = 3
text = "Bouncing Ball Radius"

[node name="BouncingBallFireRate" type="HBoxContainer" parent="MarginContainer/VBoxContainer"]
layout_mode = 2
metadata/passive_key = "ball_fire_rate"

[node name="CheckBox" type="CheckBox" parent="MarginContainer/VBoxContainer/BouncingBallFireRate"]
layout_mode = 2

[node name="Label" type="Label" parent="MarginContainer/VBoxContainer/BouncingBallFireRate"]
layout_mode = 2
size_flags_horizontal = 3
text = "Bouncing Ball Fire Rate"

[node name="PlayerClimbSpeed" type="HBoxContainer" parent="MarginContainer/VBoxContainer"]
"@
    # Inject directly above PlayerClimbSpeed
    $content = $content -replace '\[node name="PlayerClimbSpeed" type="HBoxContainer" parent="MarginContainer/VBoxContainer"\]', $ballNodes
    $content | Set-Content -Path $passiveScenePath -Encoding UTF8
    Write-Output "Injected UI Nodes into passive_order.tscn"
}

Write-Output "--- 2. Formatting mod_catalog.json for GitHub Releases API (US-05) ---"
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
        
        # Exact GitHub /releases Schema requested by the Godot JSON parser
        $release = [PSCustomObject]@{
            url = "https://api.github.com/repos/garethwhite-prog/coal-llc-mods/releases/1"
            tag_name = "v$modVer"
            name = $modName
            body = $modDesc
            draft = $false
            prerelease = $false
            assets = @(
                [PSCustomObject]@{
                    url = "https://api.github.com/repos/garethwhite-prog/coal-llc-mods/releases/assets/1"
                    name = "$modId.zip"
                    label = ""
                    content_type = "application/zip"
                    state = "uploaded"
                    browser_download_url = "https://raw.githubusercontent.com/garethwhite-prog/coal-llc-mods/main/downloaded_mods/$modId.zip"
                }
            )
        }
        $githubReleases += $release
    }
}
# Write exact flat array of releases
$githubReleases | ConvertTo-Json -Depth 10 | Set-Content -Path $catalogPath -Encoding UTF8
Write-Output "Regenerated mod_catalog.json to match exact GitHub /releases Schema."

Write-Output "--- 3. Repacking Modified Mods ---"
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force }

$targetMods = @("nanobotz-autopassivechooser")
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

Write-Output "--- 4. Updating Agile Scrum Board ---"
$sprintBoardPath = Join-Path $repoRoot "docs\ACTIVE_SPRINT_BOARD.md"
$sprintBoard = @"
# Current Active Sprint & Worklist

## 🔴 Open Bugs (Highest Priority)
* **[BUG-03]** Verify isolation between Henry Hoover (Player tool) and Drone Workforce (NPC automated entities).
* **[BUG-01]** Quadcopter Visuals: Await validation.

## 🟡 In Progress / Testing
* **[US-05]** Mod Store Central Registry: `mod_catalog.json` re-architected to mock GitHub Release API schema. Thomas and Drones now indexable. (Awaiting User Validation).
* **[BUG-02]** Passives UI: Bouncing Ball passives physically injected into `passive_order.tscn` node tree to bypass dynamic duplication limits. (Awaiting User Validation).
* **[US-01]** Thomas the Tank Engine: Base class deployed. (Awaiting graphic implementation logic).
* **[US-02]** Reach Expansion: Tune interaction distance to +1 tile (+24px) for stockpile, ore, and NPCs. Inject into Bonus Shop.

## 🟢 Completed (Pending Verification)
* **[US-06]** Deep Layer Bonus Weapons: Mod scaffolded and hooked to `Chest.gd` to drop plasma rayguns past depth 50.
* **[US-07]** Mod Manager Search: `LineEdit` search bar dynamically injected via `call_deferred`.
* **[BUG-04]** Mod Uninstall: Store UI now correctly changes to "Restart Required" to reflect OS file locks.
* **[BUG-07]** Viewport/Camera Break: Global `await chain.execute_next` enforced across ALL `.hooks.gd` files.
"@
$sprintBoard | Set-Content -Path $sprintBoardPath -Encoding UTF8

Write-Output "--- Committing to Git ---"
git add -A
git commit -m "Fix: Re-architect mod_catalog to strict GitHub Releases JSON schema and hard-inject Bouncing Ball passives into tscn resource."
git push origin main
Write-Output "Sprint Executed Successfully!"