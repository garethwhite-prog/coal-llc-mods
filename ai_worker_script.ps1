Clear-Host;

# ==============================================================================
# Coal LLC - Fix Living Canvas UI & Diagnose reset_resources Crash
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$dumpRoot   = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\_dump"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

$modName    = "gareth-living_canvas_mod"
$outerDir   = "$repo\mods-unpacked\$modName"
$innerDir   = "$outerDir\mods-unpacked\$modName"
$zipPath    = "$steamMods\$modName.zip"
$lsHookPath = "$innerDir\extensions\scenes\Interfaces\Menus\level_select.hooks.gd"

Set-Location $repo

Write-Host ">>> 1. Inspecting Gvars.gd around line 499 to isolate itemBuyPrice null..." -ForegroundColor Cyan
$gvarsPath = Join-Path $dumpRoot "scripts\Gvars.gd"
if (Test-Path $gvarsPath) {$lines = Get-Content $gvarsPath$start = [Math]::Max(0, 485)
    $end   = [Math]::Min($lines.Count - 1, 515)
    Write-Host "--- Gvars.gd (Lines $($start + 1) to $($end + 1)) ---" -ForegroundColor Yellow
    for ($i = $start; $i -le $end; $i++) {
        Write-Host ("{0,4}: {1}" -f ($i + 1), $lines[$i])
    }
}

Write-Host "`n>>> 2. Updating level_select.hooks.gd (ASCII button + instant load feedback)..." -ForegroundColor Cyan
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
	if helper_script and helper_script.has_method("ensure_level_registered"):
		helper_script.ensure_level_registered()
		var ls = chain.reference_object
		if ls and ("LEVEL_ORDER" in ls):
			if not ls.LEVEL_ORDER.has(helper_script.CANVAS_LEVEL_ID):
				ls.LEVEL_ORDER.append(helper_script.CANVAS_LEVEL_ID)

	chain.execute_next([])

	var ls = chain.reference_object
	if ls and "levels" in ls and ls.levels:
		for card in ls.levels.get_children():
			if "game_level" in card and card.game_level and card.game_level.level == 103:
				_inject_canvas_button(ls, card)

func _inject_canvas_button(ls: Control, card: Control) -> void:
	var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
	var active_path = helper_script.get_saved_image_path() if helper_script else ""
	var initial_label = "[ Choose Image ]"
	if active_path != "":
		initial_label = "[ " + active_path.get_file() + " ]"

	var btn = Button.new()
	btn.text = initial_label
	btn.custom_minimum_size = Vector2(140, 26)
	btn.add_theme_font_size_override("font_size", 9)
	btn.focus_mode = Control.FOCUS_NONE
	card.add_child(btn)
	btn.position = Vector2(10, 180)

	btn.pressed.connect(func():
		var dialog = FileDialog.new()
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.filters = PackedStringArray(["*.jpg, *.jpeg, *.png ; Image Files"])
		dialog.current_dir = "C:/Dev"
		dialog.title = "Select Image for The Living Canvas"
		if "use_native_dialog" in dialog:
			dialog.set("use_native_dialog", true)

		dialog.file_selected.connect(func(path: String):
			if helper_script and helper_script.has_method("set_active_image"):
				helper_script.set_active_image(path)
				btn.text = "[ " + path.get_file() + " ]"
				
				var new_tex = helper_script.get_preview_texture()
				if new_tex:
					card.game_level.level_image = new_tex
					# Find and update any TextureRect on the card
					for child in card.find_children("*", "TextureRect", true, false):
						if child.name != "Lock":
							child.texture = new_tex
							break
		)

		ls.add_child(dialog)
		dialog.popup_centered(Vector2i(800, 500))
	)
'@ | Set-Content -Path $lsHookPath -Encoding UTF8
Write-Host "Updated: $lsHookPath" -ForegroundColor Green

Write-Host "`n>>> 3. Flushing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 4. Repackaging gareth-living_canvas_mod.zip..." -ForegroundColor Cyan
if (Test-Path $zipPath) { Remove-Item -Path $zipPath -Force }

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$stream  = [System.IO.File]::Open($zipPath, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $outerDir -Recurse -File)) {$entryName = $f.FullName.Substring($outerDir.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Write-Host "Repacked: $zipPath" -ForegroundColor Green

Write-Host "`n>>> 5. Git staging and committing..." -ForegroundColor Cyan
git add -A
git commit -m "Fix Living Canvas UI button ASCII rendering and add active image label feedback"
git push origin main

Write-Host "`nScript complete! Check console output above for lines 485-515 of Gvars.gd." -ForegroundColor Green