Clear-Host;

# ==============================================================================
# Coal LLC - Restore Mod Manager & Register Mouse Wheel in InputMap
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$dumpRoot   = "$steamRoot\_dump"
$hookZip    = "$steamRoot\mod-hooks.zip"

$mmMain     = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\mod_main.gd"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 600

Write-Host "`n>>> 2. Restoring mod_main.gd to pristine working state from commit 9f4ab43..." -ForegroundColor Cyan
git checkout 9f4ab43 -- "$mmMain"
Write-Host "Restored clean mod_main.gd" -ForegroundColor Green

Write-Host "`n>>> 3. Adding native InputMap mouse wheel registration to _ready()..." -ForegroundColor Cyan
# Instead of an _input override, we bind WheelUp and WheelDown directly to the game's zoom actions:
$cleanCode = Get-Content -Path $mmMain -Raw

$inputMapRegistration = @'
	_setup_mouse_wheel_zoom()

func _setup_mouse_wheel_zoom() -> void:
	if not InputMap.has_action("zoomIn"):
		InputMap.add_action("zoomIn")
	if not InputMap.has_action("zoomOut"):
		InputMap.add_action("zoomOut")

	var wheel_up = InputEventMouseButton.new()
	wheel_up.button_index = MOUSE_BUTTON_WHEEL_UP
	InputMap.action_add_event("zoomIn", wheel_up)

	var wheel_down = InputEventMouseButton.new()
	wheel_down.button_index = MOUSE_BUTTON_WHEEL_DOWN
	InputMap.action_add_event("zoomOut", wheel_down)
	print("[ModManager] Registered Mouse Wheel Up/Down to zoomIn/zoomOut InputMap.")
'@

# Insert registration into _ready()
$cleanCode = $cleanCode -replace '(\tModLoaderMod\.install_script_hooks\(self\))', "`$1`r`n$inputMapRegistration"
Set-Content -Path $mmMain -Value $cleanCode -Encoding UTF8
Write-Host "Updated mod_main.gd with native InputMap bindings" -ForegroundColor Green

Write-Host "`n>>> 4. Inspecting enclosing method around line 126 in LootCollectorUFO.gd..." -ForegroundColor Cyan
$ufoPath = "$dumpRoot\scripts\LootCollectorUFO.gd"
if (Test-Path $ufoPath) {
    $ufoLines = Get-Content -Path $ufoPath
    $startIdx = [Math]::Max(0, 110)
    $endIdx   = [Math]::Min($ufoLines.Count - 1, 140)
    for ($i = $startIdx; $i -le $endIdx; $i++) {
        $marker = if ($i -eq 125) { ">>>" } else { "   " }
        Write-Host ("{0} {1,3}: {2}" -f $marker, ($i + 1), $ufoLines[$i])
    }
}

Write-Host "`n>>> 5. Inspecting project.godot zoom bindings..." -ForegroundColor Cyan
$projFile = Get-ChildItem -Path $dumpRoot -Recurse -Filter "project.godot" | Select-Object -First 1
if ($projFile) {
    $pLines = Get-Content -Path $projFile.FullName
    for ($i = 0; $i -lt $pLines.Count; $i++) {
        if ($pLines[$i] -match '^zoom(In|Out)=') {
            Write-Host "--- $($pLines[$i]) ---" -ForegroundColor Yellow
            $limit = [Math]::Min($pLines.Count - 1, $i + 5)
            for ($k = $i + 1; $k -le $limit; $k++) {
                if ($pLines[$k] -match '^\w+=') { break }
                Write-Host "    $($pLines[$k])"
            }
        }
    }
}

Write-Host "`n>>> 6. Purging mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
    Write-Host "Removed: $hookZip" -ForegroundColor Green
}

Write-Host ">>> 7. Repackaging gareth-mod_manager_mod..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$m   = "gareth-mod_manager_mod"
$src = "$repo\mods-unpacked\$m"
$zip = "$steamMods\$m.zip"
if (Test-Path $zip) { Remove-Item -Path $zip -Force }

$stream  = [System.IO.File]::Open($zip, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $src -Recurse -File)) {
    $entryName = $f.FullName.Substring($src.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Write-Host "Repacked: $zip" -ForegroundColor Green

Write-Host "`n>>> 8. Git commit and push..." -ForegroundColor Cyan
git add -A
git commit -m "Restore mod_manager and register mouse wheel into InputMap"
git push origin main

Write-Host "`nReady to launch Coal LLC!" -ForegroundColor Green