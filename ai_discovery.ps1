$repoRoot = "C:\Dev\coal-llc-mods"

Write-Output "--- DISCOVERY: US-01 Thomas the Tank ---"
$thomasDir = Join-Path $repoRoot "mods-unpacked\gareth-thomas_tank_engine_mod\mods-unpacked\gareth-thomas_tank_engine_mod"
Write-Output "Thomas dir: $thomasDir"
if (Test-Path $thomasDir) { Get-ChildItem $thomasDir -Recurse -Filter "*.gd" | ForEach-Object { Write-Output "FILE: $_"; Get-Content $_ -TotalCount 25 } } else { Write-Output "Thomas dir not found" }

Write-Output "
--- DISCOVERY: US-02 Reach Expansion ---"
$reachDir = Join-Path $repoRoot "mods-unpacked\gareth-reach_expansion_mod\mods-unpacked\gareth-reach_expansion_mod"
Write-Output "Reach dir: $reachDir"
if (Test-Path $reachDir) { Get-ChildItem $reachDir -Recurse -Filter "*.gd" | ForEach-Object { Write-Output "FILE: $_"; Get-Content $_ -TotalCount 25 } } else { Write-Output "Reach dir not found" }

Write-Output "
--- DISCOVERY: US-03 Quadcopter Drones ---"
$droneDir = Join-Path $repoRoot "mods-unpacked\gareth-drone_workforce_mod\mods-unpacked\gareth-drone_workforce_mod"
Write-Output "Drone dir: $droneDir"
if (Test-Path $droneDir) { Get-ChildItem $droneDir -Recurse -Filter "*.gd" | ForEach-Object { Write-Output "FILE: $_"; Get-Content $_ -TotalCount 25 } } else { Write-Output "Drone dir not found" }

Write-Output "
--- DISCOVERY: US-04 Henry Hoover ---"
$henryDir = Join-Path $repoRoot "mods-unpacked\gareth-henry_the_hoover_mod\mods-unpacked\gareth-henry_the_hoover_mod"
Write-Output "Henry dir: $henryDir"
if (Test-Path $henryDir) { Get-ChildItem $henryDir -Recurse -Filter "*.gd" | ForEach-Object { Write-Output "FILE: $_"; Get-Content $_ -TotalCount 25 } } else { Write-Output "Henry dir not found" }
