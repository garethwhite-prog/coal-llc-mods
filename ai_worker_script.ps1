Clear-Host;

# ==============================================================================
# Coal LLC - Fix Mouse Wheel Zoom & Inspect LootCollectorUFO Method
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

Write-Host "`n>>> 2. Inspecting enclosing function around line 126 of LootCollectorUFO.gd..." -ForegroundColor Cyan
$ufoPath = "$dumpRoot\scripts\LootCollectorUFO.gd"
if (Test-Path $ufoPath) {$ufoLines = Get-Content $ufoPath$start = [Math]::Max(0, 110)
    $end   = [Math]::Min($ufoLines.Count - 1, 140)
    for ($i = $start; $i -le $end; $i++) {
        $prefix = if ($i -eq 125) { ">>>" } else { "   " }
        Write-Host ("{0} {1,3}: {2}" -f $prefix, ($i + 1), $ufoLines[$i])
    }
}

Write-Host "`n>>> 3. Injecting high-priority _input zoom handler into mod_manager mod_main.gd..." -ForegroundColor Cyan
$mmContent = Get-Content $mmMain -Raw

# Remove any previous zoom handler if present
$mmContent = $mmContent -replace '(?ms)# === GLOBAL CAMERA ZOOM INTERCEPTOR ===.*# === END GLOBAL CAMERA ZOOM ===\r?\n?', ''

$zoomHandler = @'

# === GLOBAL CAMERA ZOOM INTERCEPTOR ===
func _input(event: InputEvent) -> void:
	if not Gvars or not ("settings" in Gvars) or not Gvars.settings:
		return

	var handled = false
	if event is InputEventMouseButton and event.is_pressed():
		# MOUSE_BUTTON_WHEEL_DOWN = 5 (Zoom OUT -> see more of mine)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			Gvars.settings.zoom_level = clamp(Gvars.settings.zoom_level - 0.2, 0.25, 4.0)
			handled = true
		# MOUSE_BUTTON_WHEEL_UP = 4 (Zoom IN -> see player closer)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			Gvars.settings.zoom_level = clamp(Gvars.settings.zoom_level + 0.2, 0.25, 4.0)
			handled = true

	elif event is InputEventKey and event.is_pressed() and not event.is_echo():
		# Hotkeys: '-' or '[' to zoom out; '=' or ']' to zoom in; '0' or 'Z' to reset to 1.0
		if event.keycode == KEY_MINUS or event.keycode == KEY_BRACKETLEFT:
			Gvars.settings.zoom_level = clamp(Gvars.settings.zoom_level - 0.25, 0.25, 4.0)
			handled = true
		elif event.keycode == KEY_EQUAL or event.keycode == KEY_BRACKETRIGHT:
			Gvars.settings.zoom_level = clamp(Gvars.settings.zoom_level + 0.25, 0.25, 4.0)
			handled = true
		elif event.keycode == KEY_0:
			Gvars.settings.zoom_level = 1.0
			handled = true

	if handled:
		var cam = get_viewport().get_camera_2d()
		if is_instance_valid(cam):
			cam.zoom = Vector2(Gvars.settings.zoom_level, Gvars.settings.zoom_level)
# === END GLOBAL CAMERA ZOOM ===
'@

$mmContent = $mmContent + $zoomHandler
Set-Content -Path $mmMain -Value $mmContent -Encoding UTF8
Write-Host "Injected top-level zoom handler into $mmMain" -ForegroundColor Green

Write-Host "`n>>> 4. Purging mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
    Write-Host "Removed: $hookZip" -ForegroundColor Green
}

Write-Host ">>> 5. Repackaging gareth-mod_manager_mod..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$m   = "gareth-mod_manager_mod"
$src = "$repo\mods-unpacked\$m"
$zip = "$steamMods\$m.zip"
if (Test-Path $zip) { Remove-Item -Path $zip -Force }

$stream  = [System.IO.File]::Open($zip, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $src -Recurse -File)) {$entryName = $f.FullName.Substring($src.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Write-Host "Repacked: $zip" -ForegroundColor Green

Write-Host "`n>>> 6. Git commit and push..." -ForegroundColor Cyan
git add -A
git commit -m "Add global input zoom interceptor and hotkeys"
git push origin main

Write-Host "`nDone! Review Section 2 output above to see the LootCollectorUFO method." -ForegroundColor Green