clear-host
$repoRoot = "C:\Dev\coal-llc-mods"

Write-Output "--- DISCOVERY: BUG-01 Drone Workforce Node Tree ---"
$dumpMiner = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\_dump\scenes\AutoMiners\employee_miner_2.tscn"
if (Test-Path $dumpMiner) { 
    Write-Output "Scanning vanilla employee_miner_2.tscn for visual nodes:"
    # FIXED: Wrapped pattern in single quotes
    Select-String -Path $dumpMiner -Pattern 'type="Sprite2D"|type="Node2D"|name="Head"|name="Torso"' 
} else { Write-Output "Miner dump not found" }

$dumpUfo = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\_dump\scenes\AutoMiners\LootCollectorUFO.tscn"
if (Test-Path $dumpUfo) { 
    Write-Output "Scanning vanilla LootCollectorUFO.tscn for visual nodes:"
    # FIXED: Wrapped pattern in single quotes
    Select-String -Path $dumpUfo -Pattern 'type="Sprite2D"|type="Node2D"|name="Models"' 
} else { Write-Output "UFO dump not found" }

Write-Output "`n--- DISCOVERY: BUG-02 AutoPassiveChooser UI Architecture ---"
$passiveGd = Join-Path $repoRoot "mods-unpacked\nanobotz-autopassivechooser\mods-unpacked\nanobotz-autopassivechooser\scenes\passive_order.gd"
if (Test-Path $passiveGd) { 
    Write-Output "Scanning passive_order.gd:"
    Get-Content $passiveGd -TotalCount 40 
} else { Write-Output "passive_order.gd not found" }

$passiveTscn = Join-Path $repoRoot "mods-unpacked\nanobotz-autopassivechooser\mods-unpacked\nanobotz-autopassivechooser\scenes\passive_order.tscn"
if (Test-Path $passiveTscn) { 
    Write-Output "Scanning passive_order.tscn for hardcoded nodes:"
    # FIXED: Wrapped pattern in single quotes
    Select-String -Path $passiveTscn -Pattern 'name="passive_list"|type="VBoxContainer"' 
} else { Write-Output "passive_order.tscn not found" }
