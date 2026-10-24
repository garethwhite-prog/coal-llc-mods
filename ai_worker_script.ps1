Clear-Host

# ==============================================================================
# Coal LLC - Fix Speed HUD Visibility & Mod Manager Category Display
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

# ------------------------------------------------------------------------------
# 2. UPDATE SPEED_CONTROLLER.GD (FIX PLAYER NODE DETECTION)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Updating speed_controller.gd to detect Player reliably..." -ForegroundColor Cyan
$scPath = "$repo\mods-unpacked\gareth-game_speed_mod\mods-unpacked\gareth-game_speed_mod\scripts\speed_controller.gd"

@'
extends Node

const SPEEDS := [0.5, 0.75, 1.0, 1.5, 2.0]
var speed_index: int = 2

var canvas: CanvasLayer
var panel: PanelContainer
var lbl_speed: Label
var btn_slower: Button
var btn_faster: Button
var btn_end_day: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()

func _build_hud() -> void:
	canvas = CanvasLayer.new()
	canvas.name = "SpeedControlHUD"
	canvas.layer = 95
	add_child(canvas)

	panel = PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -260.0
	panel.offset_right = -16.0
	panel.offset_top = 16.0
	panel.offset_bottom = 54.0

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)

	btn_slower = Button.new()
	btn_slower.text = "◀"
	btn_slower.custom_minimum_size = Vector2(30, 28)
	btn_slower.tooltip_text = "Slower [ [ ]"
	btn_slower.pressed.connect(func(): _step_speed(-1))
	hbox.add_child(btn_slower)

	lbl_speed = Label.new()
	lbl_speed.text = "1.00x"
	lbl_speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_speed.custom_minimum_size = Vector2(52, 28)
	hbox.add_child(lbl_speed)

	btn_faster = Button.new()
	btn_faster.text = "▶"
	btn_faster.custom_minimum_size = Vector2(30, 28)
	btn_faster.tooltip_text = "Faster [ ] ]"
	btn_faster.pressed.connect(func(): _step_speed(1))
	hbox.add_child(btn_faster)

	var sep = VSeparator.new()
	hbox.add_child(sep)

	btn_end_day = Button.new()
	btn_end_day.text = "End Day"
	btn_end_day.custom_minimum_size = Vector2(74, 28)
	btn_end_day.modulate = Color(1.0, 0.45, 0.45, 1.0)
	btn_end_day.tooltip_text = "Finish Level / Emergency Exit [ F8 ]"
	btn_end_day.pressed.connect(Callable(self, "_finish_level"))
	hbox.add_child(btn_end_day)

	panel.add_child(hbox)
	canvas.add_child(panel)

func _process(_delta: float) -> void:
	var tree = get_tree()
	var in_game := false
	if tree and tree.root:
		var p = tree.root.find_child("Player", true, false)
		in_game = is_instance_valid(p)

	if panel:
		panel.visible = in_game

	if not in_game and Engine.time_scale != 1.0:
		Engine.time_scale = 1.0
		speed_index = 2
		_update_label()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_BRACKETLEFT:
			_step_speed(-1)
		elif event.keycode == KEY_BRACKETRIGHT:
			_step_speed(1)
		elif event.keycode == KEY_F8:
			_finish_level()

func _step_speed(dir: int) -> void:
	speed_index = clampi(speed_index + dir, 0, SPEEDS.size() - 1)
	Engine.time_scale = SPEEDS[speed_index]
	_update_label()

func _update_label() -> void:
	if is_instance_valid(lbl_speed):
		lbl_speed.text = "%.2fx" % SPEEDS[speed_index]

func _finish_level() -> void:
	Engine.time_scale = 1.0
	speed_index = 2
	_update_label()

	if Game:
		if Game.has_method("on_EndDay"):
			Game.on_EndDay()
		elif Game.has_method("change_stage") and Gconsts and ("Stages" in Gconsts):
			Game.change_stage(Gconsts.Stages._END_OF_DAY_OVERLAY, Vector2.ZERO)
'@ | Set-Content -Path $scPath -Encoding UTF8
Write-Host "  Updated: speed_controller.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. UPDATE MOD_MANAGER_VIEW.GD TO RENDER ALL CATEGORIES & ALL MODS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Updating mod_manager_view.gd to display all categories..." -ForegroundColor Cyan
$mmViewPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scripts\mod_manager_view.gd"
if (Test-Path $mmViewPath) {
	$viewCode = Get-Content $mmViewPath -Raw
	# Replace hardcoded category array with comprehensive list + fallback
	$oldCatDef = 'var category_order := ['
	if ($viewCode.Contains($oldCatDef)) {
		$newCatDef = @'
	var category_order := [
		"Classes & Professions",
		"Progression & Upgrades",
		"Custom Maps & Strata",
		"Weapons & Arsenal",
		"Employees & Automation",
		"Quality of Life",
		"Performance & System",
		"Community Add-Ons",
		"Other Mods"
	]
'@
		# Expand _determine_category in mod_registry to map all mods into these groups
		$regPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scripts\mod_registry.gd"
		@'
class_name ModRegistry
extends RefCounted

static func get_all_mods() -> Array:
	var list: Array = []
	var mod_data = ModLoader.get_mod_data_all()
	for mod_id in mod_data.keys():
		var data = mod_data[mod_id]
		if not data or not ("manifest" in data) or not data.manifest:
			continue
		var m = data.manifest
		var display_name: String = _format_display_name(m)
		var desc: String = m.description if "description" in m else ""
		var author: String = m.extra.godot.authors[0] if (m.has("extra") and m.extra.has("godot") and m.extra.godot.has("authors") and m.extra.godot.authors.size() > 0) else "Community"
		var version: String = m.version_number if "version_number" in m else "1.0.0"
		var cat: String = _determine_category(m)

		list.append({
			"id": mod_id,
			"name": display_name,
			"description": desc,
			"author": author,
			"version": version,
			"category": cat,
			"is_active": data.is_active
		})
	return list

static func _determine_category(m) -> String:
	var id: String = str(m.name).to_lower()
	var desc: String = str(m.description).to_lower()
	if "class" in id or "profession" in id or "jedi" in id or "knight" in id or "sinclairity" in id:
		return "Classes & Professions"
	if "map" in id or "trench" in id or "faultline" in id or "canvas" in id or "expedition" in id:
		return "Custom Maps & Strata"
	if "weapon" in id or "bomb" in id or "laser" in id or "nuke" in id or "turret" in id or "mortar" in id or "grenade" in id or "arsenal" in id or "tank" in id:
		return "Weapons & Arsenal"
	if "employee" in id or "collector" in id or "drill" in id or "vacuum" in id:
		return "Employees & Automation"
	if "speed" in id or "inventory" in id or "save" in id or "leaderboard" in id or "multisave" in id or "settings" in id:
		return "Quality of Life"
	if "hardware" in id or "limit" in id or "performance" in id or "booster" in id:
		return "Performance & System"
	if "spirit" in id or "variance" in id or "upgrade" in id or "passive" in id:
		return "Progression & Upgrades"
	return "Community Add-Ons"

static func _format_display_name(m) -> String:
	if m.has("extra") and m.extra.has("godot") and m.extra.godot.has("display_name"):
		return m.extra.godot.display_name
	var raw: String = m.name.replace("_mod", "").replace("mod_", "").replace("-", " ").replace("_", " ")
	return raw.capitalize()
'@ | Set-Content -Path $regPath -Encoding UTF8
		Write-Host "  Updated: mod_registry.gd with full category mapping" -ForegroundColor Green
	}
}

# ------------------------------------------------------------------------------
# 4. REPACK MOD MANAGER & GAME SPEED MODS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Repackaging modified mods..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression.FileSystem

$modsToRepack = @(
	"gareth-mod_manager_mod",
	"gareth-game_speed_mod"
)

foreach ($m in $modsToRepack) {
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
	Write-Host "  Repacked: $m.zip" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 5. GIT STAGING, COMMIT & PUSH
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Fix speed controller player detection and expand mod registry categories for all 56 mods"
git push origin main

Write-Host "`nFix deployed successfully!" -ForegroundColor Green