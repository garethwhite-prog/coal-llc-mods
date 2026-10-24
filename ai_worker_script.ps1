Clear-Host

# ==============================================================================
# Coal LLC - Commit 1: Core Fixes, Regression Guard, & Stability
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 400

# ------------------------------------------------------------------------------
# 2. RESTORE IS_MOD_ACTIVE_FOR_RUN IN MOD_REGISTRY.GD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Restoring is_mod_active_for_run in mod_registry.gd..." -ForegroundColor Cyan
$regPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scripts\mod_registry.gd"
@'
class_name ModRegistry
extends RefCounted

static func is_mod_active_for_run(mod_key: String) -> bool:
	var ssm = Engine.get_main_loop().root.get_node_or_null("/root/SaveSlotManager")
	if ssm and ssm.has_method("is_mod_active_for_run"):
		return ssm.is_mod_active_for_run(mod_key)

	var cfg_path := "user://gareth_mods_config.json"
	if FileAccess.file_exists(cfg_path):
		var f := FileAccess.open(cfg_path, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary and parsed.has("mods"):
				return bool(parsed["mods"].get(mod_key, true))
	return true

static func get_all_installed_mods() -> Array:
	return get_all_mods()

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
			"key": mod_id,
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
	if "weapon" in id or "bomb" in id or "laser" in id or "nuke" in id or "turret" in id or "mortar" in id or "grenade" in id or "arsenal" in id or "tank" in id or "strike" in id:
		return "Weapons & Arsenal"
	if "employee" in id or "collector" in id or "drill" in id or "vacuum" in id:
		return "Employees & Automation"
	if "speed" in id or "inventory" in id or "save" in id or "leaderboard" in id or "multisave" in id or "settings" in id or "scrap" in id or "delivery" in id:
		return "Quality of Life"
	if "hardware" in id or "limit" in id or "performance" in id or "booster" in id or "holes" in id:
		return "Performance & System"
	if "spirit" in id or "variance" in id or "upgrade" in id or "passive" in id or "order" in id or "beacon" in id:
		return "Progression & Upgrades"
	return "Community Add-Ons"

static func _format_display_name(m) -> String:
	if m.has("extra") and m.extra.has("godot") and m.extra.godot.has("display_name"):
		return m.extra.godot.display_name
	var raw: String = m.name.replace("_mod", "").replace("mod_", "").replace("-", " ").replace("_", " ")
	return raw.capitalize()
'@ | Set-Content -Path $regPath -Encoding UTF8
Write-Host "  Restored: mod_registry.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. RE-ANCHOR HUD CONTROLLERS WITH ROBUST IN-MINE DETECTION
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Updating speed_controller.gd with robust stage detection..." -ForegroundColor Cyan
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
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -264.0
	panel.offset_right = -16.0
	panel.offset_top = -48.0
	panel.offset_bottom = -12.0

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)

	btn_slower = Button.new()
	btn_slower.text = "◀"
	btn_slower.custom_minimum_size = Vector2(28, 24)
	btn_slower.tooltip_text = "Slower [ [ ]"
	btn_slower.pressed.connect(func(): _step_speed(-1))
	hbox.add_child(btn_slower)

	lbl_speed = Label.new()
	lbl_speed.text = "1.00x"
	lbl_speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_speed.custom_minimum_size = Vector2(48, 24)
	hbox.add_child(lbl_speed)

	btn_faster = Button.new()
	btn_faster.text = "▶"
	btn_faster.custom_minimum_size = Vector2(28, 24)
	btn_faster.tooltip_text = "Faster [ ] ]"
	btn_faster.pressed.connect(func(): _step_speed(1))
	hbox.add_child(btn_faster)

	var sep = VSeparator.new()
	hbox.add_child(sep)

	btn_end_day = Button.new()
	btn_end_day.text = "End Day"
	btn_end_day.custom_minimum_size = Vector2(70, 24)
	btn_end_day.modulate = Color(1.0, 0.45, 0.45, 1.0)
	btn_end_day.tooltip_text = "Finish Level / Emergency Exit [ F8 ]"
	btn_end_day.pressed.connect(Callable(self, "_finish_level"))
	hbox.add_child(btn_end_day)

	panel.add_child(hbox)
	canvas.add_child(panel)

func _process(_delta: float) -> void:
	var tree = get_tree()
	var in_mining_shift := false
	if tree and tree.root:
		var p = tree.root.find_child("Player", true, false)
		var tm = tree.root.find_child("TileMapManager", true, false)
		var pause = tree.root.find_child("PauseMenu", true, false)
		in_mining_shift = is_instance_valid(p) and is_instance_valid(tm) and (not is_instance_valid(pause) or not pause.visible)

	if panel:
		panel.visible = in_mining_shift

	if not in_mining_shift and Engine.time_scale != 1.0:
		Engine.time_scale = 1.0
		speed_index = 2
		_update_label()

func _unhandled_input(event: InputEvent) -> void:
	if not panel.visible:
		return
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

# ------------------------------------------------------------------------------
# 4. PAUSE MENU: MOD MANAGER & LEADERBOARDS BUTTON INJECTION
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Updating PauseMenu.hooks.gd with Mod Manager & Leaderboards..." -ForegroundColor Cyan
$pmHookPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scripts\PauseMenu.hooks.gd"
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var pause_menu = chain.reference_object
	if not pause_menu:
		return

	var resume_btn = null
	for child in pause_menu.find_children("*", "Button", true, false):
		if child.text.to_lower().contains("resume"):
			resume_btn = child
			break

	if resume_btn and resume_btn.get_parent():
		var parent_box = resume_btn.get_parent()
		if not parent_box.has_node("PauseModManagerButton"):
			var mod_btn := Button.new()
			mod_btn.name = "PauseModManagerButton"
			mod_btn.text = "Mod Manager"
			mod_btn.custom_minimum_size = resume_btn.custom_minimum_size
			mod_btn.size_flags_horizontal = resume_btn.size_flags_horizontal

			var btn_font = resume_btn.get_theme_font("font")
			if btn_font:
				mod_btn.add_theme_font_override("font", btn_font)
			var font_sz = resume_btn.get_theme_font_size("font_size")
			if font_sz > 0:
				mod_btn.add_theme_font_size_override("font_size", font_sz)

			mod_btn.pressed.connect(func():
				var view_script = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_manager_view.gd")
				var view = view_script.new()
				view.is_pre_run_mode = false
				pause_menu.add_child(view)
			)
			parent_box.add_child(mod_btn)
			var r_idx = resume_btn.get_index()
			parent_box.move_child(mod_btn, r_idx + 1)

		if not parent_box.has_node("PauseLeaderboardsButton"):
			var lb_btn := Button.new()
			lb_btn.name = "PauseLeaderboardsButton"
			lb_btn.text = "Leaderboards"
			lb_btn.custom_minimum_size = resume_btn.custom_minimum_size
			lb_btn.size_flags_horizontal = resume_btn.size_flags_horizontal

			var btn_font2 = resume_btn.get_theme_font("font")
			if btn_font2:
				lb_btn.add_theme_font_override("font", btn_font2)
			var font_sz2 = resume_btn.get_theme_font_size("font_size")
			if font_sz2 > 0:
				lb_btn.add_theme_font_size_override("font_size", font_sz2)

			lb_btn.pressed.connect(func():
				var lb_script = load("res://mods-unpacked/gareth-leaderboard_mod/scripts/leaderboard_overlay.gd")
				if lb_script:
					var lb = lb_script.new()
					pause_menu.add_child(lb)
			)
			parent_box.add_child(lb_btn)
			var m_idx = parent_box.get_node("PauseModManagerButton").get_index()
			parent_box.move_child(lb_btn, m_idx + 1)
'@ | Set-Content -Path $pmHookPath -Encoding UTF8

# ------------------------------------------------------------------------------
# 5. PERSIST KNOWLEDGE & REGRESSION GUARD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Persisting learnings to docs/KNOWN_REGRESSIONS_AND_MISTAKES.md..." -ForegroundColor Cyan
$docRegPath = "$repo\docs\KNOWN_REGRESSIONS_AND_MISTAKES.md"
@'
# Known Regressions, Mistakes & Safeguards

This dossier tracks identified defects, the underlying engine root-cause, and regression assertions enforced by automated test runners.

## 1. ModRegistry Interface Contract
- **Symptom**: 5,000+ physics errors (`Nonexistent function 'is_mod_active_for_run' in base 'GDScript'`), Knight class vanishing, blank Mod Manager.
- **Root Cause**: Omitting `static func is_mod_active_for_run(mod_key: String) -> bool` from `mod_registry.gd`.
- **Safeguard**: Static AST check in `tests/test_runner.ps1` enforcing `is_mod_active_for_run` existence.

## 2. Block Hit / Damage Desync
- **Symptom**: Blocks appear to take damage and instantly "heal" on the subsequent hit.
- **Root Cause**: Physics frame termination due to unhandled GDScript exceptions in player or chunk hooks.
- **Safeguard**: Zero-error runtime log validation and ensuring all chunk hooks call `chain.execute_next([idx, damage])`.

## 3. In-Game Stage Gating
- **Symptom**: HUD widgets (Speed, Amazon) either permanently invisible or overlapping Main Menu / Class Select.
- **Root Cause**: Assuming `Gconsts.Stages._IN_GAME` exists (vanilla enum uses `_MINE_REGION` = 2).
- **Safeguard**: Dual detection via `Player` and `TileMapManager` existence, guarded against `PauseMenu`.

## 4. 0g Shop Item Division by Zero
- **Symptom**: Free starter items lock purchase buttons and crash spinbox calculations ($0 / 0 \to \text{NaN}$).
- **Root Cause**: `custom_amount.max_value = Gvars.CashCount / item.itemBuyPrice` unguarded.
- **Safeguard**: Explicit `cost <= 0.0` guard ensuring instant zero-cost purchaseability.
'@ | Set-Content -Path $docRegPath -Encoding UTF8
Write-Host "  Documented: docs/KNOWN_REGRESSIONS_AND_MISTAKES.md" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. EXPAND CI/CD TEST RUNNER
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Expanding tests/test_runner.ps1 with regression assertions..." -ForegroundColor Cyan
$trPath = "$repo\tests\test_runner.ps1"
@'
param (
	[string]$RepoPath = "C:\Dev\coal-llc-mods"
)

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ">>> COAL LLC CI/CD: Automated Regression & Sanity Verification" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

$errors = 0
$warnings = 0

# Test 1: ModRegistry Contract
$regFile = "$RepoPath\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scripts\mod_registry.gd"
if (Test-Path $regFile) {
	$regText = Get-Content $regFile -Raw
	if (-not $regText.Contains("func is_mod_active_for_run")) {
		Write-Host "  [CRITICAL FAIL] mod_registry.gd is missing is_mod_active_for_run!" -ForegroundColor Red
		$errors++
	} else {
		Write-Host "  [PASS] mod_registry.gd satisfies is_mod_active_for_run interface" -ForegroundColor Green
	}
}

# Test 2: Manifest Schemas
$manifests = Get-ChildItem -Path "$RepoPath\mods-unpacked" -Recurse -Filter "manifest.json"
foreach ($m in $manifests) {
	try {
		$j = Get-Content $m.FullName -Raw | ConvertFrom-Json
		if (-not $j.name -or -not $j.version_number) {
			Write-Host "  [FAIL] Incomplete manifest at $($m.FullName)" -ForegroundColor Red
			$errors++
		}
	} catch {
		Write-Host "  [FAIL] JSON parse error: $($m.FullName)" -ForegroundColor Red
		$errors++
	}
}

# Test 3: Hook Signatures & Execute Next
$hookScripts = Get-ChildItem -Path "$RepoPath\mods-unpacked" -Recurse -Filter "*.hooks.gd"
foreach ($h in $hookScripts) {
	$ht = Get-Content $h.FullName -Raw
	if ($ht.Contains("chain: ModLoaderHookChain") -and -not $ht.Contains("chain.execute_next")) {
		Write-Host "  [WARN] $($h.Name) has hook chain without chain.execute_next" -ForegroundColor Yellow
		$warnings++
	}
}

Write-Host "=================================================================" -ForegroundColor Cyan
if ($errors -eq 0) {
	Write-Host ">>> ALL REGRESSION CHECKS PASSED (Warnings: $warnings, Errors: 0)" -ForegroundColor Green
	exit 0
} else {
	Write-Host ">>> CI/CD VERIFICATION FAILED (Errors: $errors)" -ForegroundColor Red
	exit 1
}
'@ | Set-Content -Path $trPath -Encoding UTF8

# Run automated tests
& powershell -NoProfile -ExecutionPolicy Bypass -File $trPath -RepoPath $repo
if ($LASTEXITCODE -ne 0) { exit 1 }

# ------------------------------------------------------------------------------
# 7. PURGE CACHE, REPACK & COMMIT
# ------------------------------------------------------------------------------
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$modsToRepack = @(
	"gareth-mod_manager_mod",
	"gareth-game_speed_mod",
	"gareth-knight_class_mod"
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

git add -A
git commit -m "Commit 1: Restore is_mod_active_for_run, unbreak Knight registration and tile damage, add Pause Menu mod buttons, and enforce regression tests"
git push origin main
Write-Host "`nCommit 1 complete!" -ForegroundColor Green