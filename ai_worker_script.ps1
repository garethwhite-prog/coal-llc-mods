Clear-Host;

# ==============================================================================
# Coal LLC - Fix Living Canvas Difficulty Enum & Menu Lockout
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

$modName    = "gareth-living_canvas_mod"
$outerDir   = "$repo\mods-unpacked\$modName"
$innerDir   = "$outerDir\mods-unpacked\$modName"
$zipPath    = "$steamMods\$modName.zip"
$helperPath = "$innerDir\helpers\LivingCanvasHelper.gd"
$lsHookPath = "$innerDir\extensions\scenes\Interfaces\Menus\level_select.hooks.gd"

Set-Location $repo

Write-Host ">>> 1. Patching LivingCanvasHelper.gd (changing Difficulty to HARD)..." -ForegroundColor Cyan
$helperContent = Get-Content -Path $helperPath -Raw

# Replace the invalid MEDIUM enum with HARD
$helperContent = $helperContent -replace 'custom_level\.level_difficulty\s*=\s*GameLevel\.Difficulty\.MEDIUM', 'custom_level.level_difficulty = GameLevel.Difficulty.HARD'
Set-Content -Path $helperPath -Value$helperContent -Encoding UTF8
Write-Host "Patched: $helperPath" -ForegroundColor Green

Write-Host "`n>>> 2. Hardening level_select.hooks.gd file dialog call..." -ForegroundColor Cyan
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
	var btn = Button.new()
	btn.text = "??? Choose Image"
	btn.custom_minimum_size = Vector2(130, 26)
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
			var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
			if helper_script and helper_script.has_method("set_active_image"):
				helper_script.set_active_image(path)
				var new_tex = helper_script.get_preview_texture()
				if new_tex and "level_image" in card and card.level_image:
					card.level_image.texture = new_tex
		)

		ls.add_child(dialog)
		dialog.popup_centered(Vector2i(800, 500))
	)
'@ | Set-Content -Path $lsHookPath -Encoding UTF8
Write-Host "Patched: $lsHookPath" -ForegroundColor Green

Write-Host "`n>>> 3. Flushing stale mod-hooks.zip..." -ForegroundColor Cyan
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

Write-Host "`n>>> 5. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Fix Living Canvas Difficulty enum compilation error and safe dialog invocation"
git push origin main

Write-Host "`nFix deployed successfully! Launch Coal LLC to test." -ForegroundColor Green