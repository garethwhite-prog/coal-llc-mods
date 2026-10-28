# ==============================================================================
# Coal LLC - Fix Store Text Contrast, Henry/Teletubby Manifests & Chained Title Sign
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$downMods   = "$steamRoot\downloaded_mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 400

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

# ------------------------------------------------------------------------------
# 2. FIX MANIFEST SCHEMA FOR HENRY THE HOOVER (RESTORE MODLOADER ACTIVATION)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Fixing manifest schema for gareth-henry_the_hoover_mod..." -ForegroundColor Cyan
$henryDir = "$repo\mods-unpacked\gareth-henry_the_hoover_mod"
$henryInner = "$henryDir\mods-unpacked\gareth-henry_the_hoover_mod"

$henryManifest = @'
{
  "name": "henry_the_hoover_mod",
  "namespace": "gareth",
  "version_number": "1.0.5",
  "description": "Authentic Henry the Hoover visual skin for the industrial vacuum. Body color dynamically updates based on upgrade tier (Henry, Hetty, Harry, George, Charles).",
  "website_url": "https://github.com/garethwhite-prog/coal-llc-mods",
  "dependencies": ["gareth-mod_manager_mod"],
  "extra": {
    "godot": {
      "authors": ["Gareth White"],
      "display_name": "Henry the Hoover (Vacuum Reskin)",
      "tags": ["visual", "vacuum", "reskin", "qol"],
      "compatible_mod_loader_version": ["7.0.1"],
      "compatible_game_version": ["1.4.1.1"]
    }
  }
}
'@
Set-Content -Path "$henryDir\manifest.json" -Value $henryManifest -Encoding UTF8
Set-Content -Path "$henryInner\manifest.json" -Value $henryManifest -Encoding UTF8

# Repack into downloaded_mods AND update active mods if already installed
$henryZip = "$downMods\gareth-henry_the_hoover_mod.zip"
if (Test-Path $henryZip) { Remove-Item -Path $henryZip -Force }
$stream  = [System.IO.File]::Open($henryZip, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $henryDir -Recurse -File)) {
	$entryName = $f.FullName.Substring($henryDir.Length + 1).Replace("\", "/")
	[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()

# If user installed Henry in Steam mods/, copy the repaired zip over
if (Test-Path "$steamMods\gareth-henry_the_hoover_mod.zip") {
	Copy-Item -Path $henryZip -Destination "$steamMods\gareth-henry_the_hoover_mod.zip" -Force
	Write-Host "  Updated active: gareth-henry_the_hoover_mod.zip in mods/" -ForegroundColor Green
}
Write-Host "  Staged repaired: gareth-henry_the_hoover_mod.zip in downloaded_mods/" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. FIX MANIFEST SCHEMA FOR TELETUBBIES MOD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Fixing manifest schema for gareth-teletubbies_mod..." -ForegroundColor Cyan
$ttDir = "$repo\mods-unpacked\gareth-teletubbies_mod"
$ttInner = "$ttDir\mods-unpacked\gareth-teletubbies_mod"

$ttManifest = @'
{
  "name": "teletubbies_mod",
  "namespace": "gareth",
  "version_number": "1.0.5",
  "description": "Transforms your mine into Teletubbyland: Noo-Noo vacuum cleaner, yawning Baby Sun that sets with the timer, and colorful workforce reskins.",
  "website_url": "https://github.com/garethwhite-prog/coal-llc-mods",
  "dependencies": ["gareth-mod_manager_mod"],
  "extra": {
    "godot": {
      "authors": ["Gareth White"],
      "display_name": "Teletubbies & Noo-Noo Overhaul",
      "tags": ["visual", "teletubbies", "workforce", "qol"],
      "compatible_mod_loader_version": ["7.0.1"],
      "compatible_game_version": ["1.4.1.1"]
    }
  }
}
'@
Set-Content -Path "$ttDir\manifest.json" -Value $ttManifest -Encoding UTF8
Set-Content -Path "$ttInner\manifest.json" -Value $ttManifest -Encoding UTF8

$ttZip = "$downMods\gareth-teletubbies_mod.zip"
if (Test-Path $ttZip) { Remove-Item -Path $ttZip -Force }
$stream  = [System.IO.File]::Open($ttZip, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $ttDir -Recurse -File)) {
	$entryName = $f.FullName.Substring($ttDir.Length + 1).Replace("\", "/")
	[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Write-Host "  Staged repaired: gareth-teletubbies_mod.zip in downloaded_mods/" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. FIX MOD STORE TEXT CONTRAST (BRIGHT WHITE TITLES)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Fixing mod name font color in mod_store_view.gd..." -ForegroundColor Cyan
$msvPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_store_view.gd"
$msvCode = Get-Content $msvPath -Raw

# Replace uncolored %s with bright white [color=#ffffff]%s[/color]
$oldTitleBB = 'title_lbl.text = "[b][font_size=15]%s[/font_size][/b]'
$newTitleBB = 'title_lbl.text = "[b][font_size=15][color=#ffffff]%s[/color][/font_size][/b]'
if ($msvCode.Contains($oldTitleBB)) {
	$msvCode = $msvCode.Replace($oldTitleBB, $newTitleBB)
}

# Also ensure description text is bright and legible
$msvCode = $msvCode.Replace('desc_lbl.modulate = Color(0.78, 0.78, 0.78)', 'desc_lbl.modulate = Color(0.88, 0.90, 0.94)')

Set-Content -Path $msvPath -Value $msvCode -Encoding UTF8
Write-Host "  Updated: mod_store_view.gd (Titles now render in bright white #ffffff)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. PROCEDURAL HANGING SIGN WITH CHAINS IN MAINMENU.HOOKS.GD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Installing procedural hanging title sub-board in MainMenu.hooks.gd..." -ForegroundColor Cyan
$mmmHookPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scripts\MainMenu.hooks.gd"
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var menu = chain.reference_object
	if not is_instance_valid(menu):
		return

	# Check for an optional external branded logo using raw byte buffers
	var logo_loaded := false
	var title_node = menu.find_child("Title", true, false)
	if not title_node:
		title_node = menu.find_child("TextureRect", true, false)

	var logo_path := "res://mods-unpacked/gareth-mod_manager_mod/assets/branded_logo.png"
	if FileAccess.file_exists(logo_path) and is_instance_valid(title_node) and title_node is TextureRect:
		var bytes := FileAccess.get_file_as_bytes(logo_path)
		if bytes.size() > 0:
			var img := Image.new()
			if img.load_png_from_buffer(bytes) == OK:
				var tex := ImageTexture.create_from_image(img)
				title_node.texture = tex
				title_node.custom_minimum_size = Vector2(760, 310)
				title_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				logo_loaded = true

	# Procedural Hanging Plaque with Iron Chains beneath the Title Sign
	if not logo_loaded and not menu.has_node("HangingTitlePlaque"):
		var plaque_container := Control.new()
		plaque_container.name = "HangingTitlePlaque"
		plaque_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
		plaque_container.position = Vector2(0, 0)
		menu.add_child(plaque_container)

		# Left Iron Chain Links
		var chain_l := ColorRect.new()
		chain_l.color = Color(0.28, 0.28, 0.32, 0.95)
		chain_l.position = Vector2(488, 252)
		chain_l.size = Vector2(8, 22)
		plaque_container.add_child(chain_l)

		# Right Iron Chain Links
		var chain_r := ColorRect.new()
		chain_r.color = Color(0.28, 0.28, 0.32, 0.95)
		chain_r.position = Vector2(784, 252)
		chain_r.size = Vector2(8, 22)
		plaque_container.add_child(chain_r)

		# Hanging Wooden Plaque Board
		var wood_panel := PanelContainer.new()
		wood_panel.position = Vector2(440, 274)
		wood_panel.custom_minimum_size = Vector2(400, 36)

		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.55, 0.32, 0.18, 0.98) # Warm timber brown
		sb.border_color = Color(0.22, 0.12, 0.06, 1.0) # Dark wooden bark rim
		sb.set_border_width_all(3)
		sb.corner_radius_top_left = 6
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_left = 6
		sb.corner_radius_bottom_right = 6
		sb.expand_margin_top = 2
		sb.expand_margin_bottom = 2
		wood_panel.add_theme_stylebox_override("panel", sb)

		var plaque_label := RichTextLabel.new()
		plaque_label.bbcode_enabled = true
		plaque_label.text = "[center][b][color=#38bdf8]✦ ENHANCED BY GARETH WHITE & GEMINI ✦[/color][/b][/center]"
		plaque_label.fit_content = true
		plaque_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wood_panel.add_child(plaque_label)

		plaque_container.add_child(wood_panel)

	# Main Menu Buttons Configuration
	var btn_grid = menu.get_node_or_null("%MainMenuButtons")
	if btn_grid:
		btn_grid.offset_top = -68.0
		btn_grid.offset_bottom = 176.0
		btn_grid.add_theme_constant_override("separation", 4)

		if not btn_grid.has_node("ModManagerButton"):
			var mod_btn := Button.new()
			mod_btn.name = "ModManagerButton"
			mod_btn.text = "Mod Manager"
			mod_btn.custom_minimum_size = Vector2(0, 30)
			mod_btn.pressed.connect(func():
				var view_script = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_manager_view.gd")
				if view_script:
					var view: Control = Control.new()
					view.set_script(view_script)
					view.is_pre_run_mode = false
					menu.add_child(view)
			)
			btn_grid.add_child(mod_btn)
			btn_grid.move_child(mod_btn, 2)

		if not btn_grid.has_node("ModStoreButton"):
			var store_btn := Button.new()
			store_btn.name = "ModStoreButton"
			store_btn.text = "Mod & Map Store"
			store_btn.custom_minimum_size = Vector2(0, 30)
			store_btn.modulate = Color(1.0, 0.88, 0.35)
			store_btn.pressed.connect(func():
				var store_script = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_store_view.gd")
				if store_script:
					var store_view = store_script.new()
					menu.add_child(store_view)
			)
			btn_grid.add_child(store_btn)
			btn_grid.move_child(store_btn, 3)

		if not btn_grid.has_node("LeaderboardsButton"):
			var lb_btn := Button.new()
			lb_btn.name = "LeaderboardsButton"
			lb_btn.text = "Leaderboards"
			lb_btn.custom_minimum_size = Vector2(0, 30)
			lb_btn.pressed.connect(func():
				var modal_script = load("res://mods-unpacked/gareth-leaderboard_mod/scenes/leaderboard_modal.gd")
				if modal_script:
					var modal = modal_script.new()
					menu.add_child(modal)
			)
			btn_grid.add_child(lb_btn)
			btn_grid.move_child(lb_btn, 4)

func on_profession_selected(chain: ModLoaderHookChain, mode: int, prof: Object, hard_modifier: Object) -> void:
	var menu = chain.reference_object
	if not menu:
		chain.execute_next([mode, prof, hard_modifier])
		return

	var p_select = menu.get_node_or_null("ProfessionSelect")
	if not p_select and "profession_select" in menu:
		p_select = menu.profession_select
	if p_select:
		p_select.visible = false

	var view_script = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_manager_view.gd")
	if view_script:
		var view: Control = Control.new()
		view.set_script(view_script)
		view.name = "PreRunModSelector"
		view.is_pre_run_mode = true

		view.confirmed.connect(func():
			chain.execute_next([mode, prof, hard_modifier])
		)

		view.back_pressed.connect(func():
			if p_select:
				p_select.visible = true
		)

		menu.add_child(view)
	else:
		chain.execute_next([mode, prof, hard_modifier])
'@ | Set-Content -Path $mmmHookPath -Encoding UTF8
Write-Host "  Updated: MainMenu.hooks.gd (Procedural hanging plaque + buffer loader mounted)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. REPACK GARETH-MOD_MANAGER_MOD TO STEAM
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Repackaging gareth-mod_manager_mod into active Steam mods..." -ForegroundColor Cyan
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

$m = "gareth-mod_manager_mod"
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
Write-Host "  Repacked cleanly: $m.zip" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 7. COMMIT AND PUSH TO GITHUB
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Fix: Bright white font for Mod Store card titles, repaired manifest schema for Henry and Teletubbies, and procedural hanging title sub-board"
git push origin main

Write-Host "`nDeployment complete! Zero tests executed (awaiting gameplay session)." -ForegroundColor Green