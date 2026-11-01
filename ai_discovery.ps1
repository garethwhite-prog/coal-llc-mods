clear-host
$repoRoot = "C:\Dev\coal-llc-mods"

Write-Output ">>> A. Mod Store Remote Registry URL"
$storeClient = Join-Path $repoRoot "mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scripts\mod_store_client.gd"
if (Test-Path $storeClient) {
    Select-String -Path $storeClient -Pattern "http|request|url"
}

Write-Output "`n>>> B. Henry Hoover Vanilla Sprite Target"
$vacDump = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\_dump\scenes\equipment\vacuum_cleaner.tscn"
if (Test-Path $vacDump) {
    # FIXED: Swapped to single quotes and added missing closing double quote for Sprite
    Select-String -Path $vacDump -Pattern 'type="Sprite"'
}

Write-Output "`n>>> C. Quadcopter Animation Visibility Override"
$minerGd = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\_dump\scenes\AutoMiners\employee_miner_2.gd"
if (Test-Path $minerGd) {
    Select-String -Path $minerGd -Pattern "visible|modulate|Sprites|AnimationPlayer" -Context 1,1
}

Write-Output "`n>>> D. Mod Manager 'By Community' Hardcode"
$mgrView = Join-Path $repoRoot "mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_manager_view.gd"
if (Test-Path $mgrView) {
    Select-String -Path $mgrView -Pattern "Community" -Context 2,2
}

Write-Output "`n>>> E. Passive Chooser Hardcoded Arrays"
$passivesMain = Join-Path $repoRoot "mods-unpacked\nanobotz-autopassivechooser\mods-unpacked\nanobotz-autopassivechooser\mod_main.gd"
if (Test-Path $passivesMain) {
    Select-String -Path $passivesMain -Pattern "Axe Damage|player_climb_speed|passive" -Context 1,1
}
