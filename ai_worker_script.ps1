$repoRoot = "C:\Dev\coal-llc-mods"
Set-Location -Path $repoRoot

Write-Output "--- 1. Generating Backlog & Bug Tracker Directories ---"
$storiesDir = Join-Path $repoRoot "docs\user_stories"
$bugsDir = Join-Path $repoRoot "docs\bugs"
if (-not (Test-Path $storiesDir)) { New-Item -Path $storiesDir -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $bugsDir)) { New-Item -Path $bugsDir -ItemType Directory -Force | Out-Null }

Write-Output "--- 2. Updating Bug Tracker & New User Stories ---"
# BUG-04
@"
# BUG-04: Cannot Uninstall Mod via Mod Store
**Status:** Open
**Component:** `gareth-mod_manager_mod` (`mod_store_client.gd` / `mod_store_view.gd`)
**Description:** User was able to install Teletubbies but clicking remove/uninstall on Henry the Hoover failed.
**Theory:** The zip file might be locked by Godot's resource loader, or the deletion script is targeting the wrong directory (`mods/` vs `downloaded_mods/`).
"@ | Set-Content -Path (Join-Path $bugsDir "BUG-04_Uninstall_Failure.md") -Encoding UTF8

# BUG-05
@"
# BUG-05: Mod Manager displays 'By Community' for Official Mods
**Status:** Open
**Component:** `gareth-mod_manager_mod` (`mod_manager_view.gd`)
**Description:** Manifests have 'Gareth White' as the author, but the UI defaults to 'By Community'.
**Theory:** The GDScript parsing the manifest likely has a hardcoded check (e.g. `if author != "Der-Floh"`).
"@ | Set-Content -Path (Join-Path $bugsDir "BUG-05_Author_Tagging.md") -Encoding UTF8

# US-06
@"
# US-06: Deep Layer Bonus Weapons
**Status:** To Do
**Description:** As a player, I want a mod that spawns bonus weapon drops in deeper strata layers to aid in late-game clearing.
**Acceptance Criteria:** 
- Create new mod `gareth-deep_layer_weapons_mod`.
- Hook chest generation or layer transitions to inject high-tier weapons.
"@ | Set-Content -Path (Join-Path $storiesDir "US-06_Deep_Layer_Weapons.md") -Encoding UTF8

# US-07
@"
# US-07: Mod Manager Search & Filter Integration
**Status:** To Do
**Component:** `gareth-mod_manager_mod`
**Description:** As a player, I want the local Mod Manager to have a search bar and category dropdowns matching the Mod Store UX.
"@ | Set-Content -Path (Join-Path $storiesDir "US-07_Mod_Manager_Search.md") -Encoding UTF8

Write-Output "--- 3. Updating SESSION_PROMPT.md ---"
$sessionPromptPath = Join-Path $repoRoot "SESSION_PROMPT.md"
$sessionContent = Get-Content $sessionPromptPath -Raw
if ($sessionContent -notmatch "Deep Layer Bonus Weapons") {
    $sessionContent += "`n### 10. Deep Layer Bonus Weapons (US-06)`n* **Outstanding Task:** Create a new mod that injects high-tier weapon drops into deep strata chests/spawns.`n"
    $sessionContent += "`n### 11. Mod Manager Search & Filter (US-07)`n* **Outstanding Task:** Replicate the Mod Store UI search bar and dropdowns for the local active mods menu.`n"
    $sessionContent | Set-Content -Path $sessionPromptPath -Encoding UTF8
}

Write-Output "--- 4. SURGICAL DISCOVERY ---"
$discoveryScript = @"
`$repoRoot = "C:\Dev\coal-llc-mods"

Write-Output ">>> A. Mod Store Remote Registry URL"
`$storeClient = Join-Path `$repoRoot "mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scripts\mod_store_client.gd"
if (Test-Path `$storeClient) {
    Select-String -Path `$storeClient -Pattern "http|request|url"
}

Write-Output "`n>>> B. Henry Hoover Vanilla Sprite Target"
`$vacDump = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\_dump\scenes\equipment\vacuum_cleaner.tscn"
if (Test-Path `$vacDump) {
    Select-String -Path `$vacDump -Pattern "type=`"Sprite"
}

Write-Output "`n>>> C. Quadcopter Animation Visibility Override"
`$minerGd = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\_dump\scenes\AutoMiners\employee_miner_2.gd"
if (Test-Path `$minerGd) {
    Select-String -Path `$minerGd -Pattern "visible|modulate|Sprites|AnimationPlayer" -Context 1,1
}

Write-Output "`n>>> D. Mod Manager 'By Community' Hardcode"
`$mgrView = Join-Path `$repoRoot "mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_manager_view.gd"
if (Test-Path `$mgrView) {
    Select-String -Path `$mgrView -Pattern "Community" -Context 2,2
}

Write-Output "`n>>> E. Passive Chooser Hardcoded Arrays"
`$passivesMain = Join-Path `$repoRoot "mods-unpacked\nanobotz-autopassivechooser\mods-unpacked\nanobotz-autopassivechooser\mod_main.gd"
if (Test-Path `$passivesMain) {
    Select-String -Path `$passivesMain -Pattern "Axe Damage|player_climb_speed|passive" -Context 1,1
}
"@
$discoveryScript | Set-Content -Path (Join-Path $repoRoot "ai_discovery.ps1") -Encoding UTF8

Write-Output "Executing Surgical Discovery Script..."
& powershell -ExecutionPolicy Bypass -File (Join-Path $repoRoot "ai_discovery.ps1")

Write-Output "--- Committing Repo Architecture Updates ---"
git add docs/ SESSION_PROMPT.md
git commit -m "Docs: Complete Sprint Board sync, log US-06 (Deep Layer Weapons) & US-07 (Mod Manager Search), and track BUG-04 (Uninstall) and BUG-05 (Author Tags)."
git push origin main
Write-Output "Operation Successful. Awaiting Discovery Results to build patches."