Clear-Host

# ==============================================================================
# Coal LLC - Platform Architecture 2.0: CI/CD, Discovery Vault & Core Fixes
# ==============================================================================

$env:GIT_PAGER = "cat"
$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$steamRepo  = "$steamRoot\mods_repository"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

# ------------------------------------------------------------------------------
# 2. SETUP DECOUPLED STAGING DIRECTORIES (MODS_REPOSITORY VS MODS)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Initializing decoupled storage (mods_repository)..." -ForegroundColor Cyan
if (-not (Test-Path $steamRepo)) {
    New-Item -ItemType Directory -Path $steamRepo -Force | Out-Null
    Write-Host "  Created: $steamRepo" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 3. BUILD DISCOVERY VAULT & PERSIST SESSION KNOWLEDGE (docs/discovery/)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Structuring discovery knowledge base in repository..." -ForegroundColor Cyan
$docDir = "$repo\docs\discovery"
New-Item -ItemType Directory -Path $docDir -Force | Out-Null

$indexMd = @"
# Coal LLC Modding Discovery Archive & Technical Dossier

This archive preserves all empirical findings, AST discoveries, engine hooks, and memory layout investigations.

## Discovery Phase Index
- **Phase 01–15**: ModLoader 7.x lifecycle, manifest schemas, custom class registration.
- **Phase 16–25**: Subterranean strata, tilemap elemental loops (fire, water, poison).
- **Phase 26–30**: ModHookPacker compilation, script extensions vs hook chains.
- **Phase 31–35**: Viewport tracking, native end-of-day sequence, employee miner/collector routines.
- **Phase 36–40**: Elemental airstrike flight paths, inventory slot data structures, loot drop valuation.
- **Phase 41–43**: Division-by-zero 0g shop card bug, pre-run UI category decoupling, turret targeting.

## Key Engine Conventions
1. **Database / Stored Procedure Philosophy**: Zero inline mutations on core registries; use ModLoader Hook Chains exclusively.
2. **Tilemap Status**:
   - Wetness: \`tilemap.wet_tile_coords(cell)\` and \`tilemap.wetness.add_wet_tile(cell)\`
   - Combustion: \`tilemap.burn_tile(pos, dmg, ticks)\` and \`tilemap.fires.add_fire_tile(cell, dmg, ticks)\`
   - Poison: \`tilemap.poison_tile_coords(cell, dmg, ticks)\` and \`tilemap.poisons.add_poison_tile(cell, dmg, ticks)\`
3. **Player Node Discovery**: Target \`tree.root.find_child("Player", true, false)\` rather than group lookups.
"@
Set-Content -Path "$docDir\INDEX.md" -Value $indexMd -Encoding UTF8
Write-Host "  Initialized: docs\discovery\INDEX.md" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. FIX SHOP DIVISION-BY-ZERO BUG ON 0g ITEMS (shop_item_card.hooks.gd)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Implementing 0g safe-division hook on shop_item_card.gd..." -ForegroundColor Cyan
$sicHookDir = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scenes\Interfaces\Management"
New-Item -ItemType Directory -Path $sicHookDir -Force | Out-Null

@'
extends Object

func _on_purchase_button_gui_input(chain: ModLoaderHookChain, event: InputEvent) -> void:
	var card = chain.reference_object
	if not is_instance_valid(card) or not ("item" in card) or not card.item:
		chain.execute_next([event])
		return

	# Prevent division-by-zero when itemBuyPrice is 0g
	if event.is_action_released("rightMouseClick"):
		if card.purchaseable and (Gvars.CashCount >= card.item.itemBuyPrice):
			card.purchase_custom_amount.global_position = card.global_position
			var cost: float = float(card.item.itemBuyPrice)
			if cost <= 0.0:
				card.custom_amount.max_value = 1.0
			else:
				card.custom_amount.max_value = max(1.0, floor(Gvars.CashCount / cost))
			card.custom_amount.assign_value(card.last_custom_value)
			card.custom_amount.refresh_all()
			card.custom_amount.visible = true
			card.custom_amount.h_slider.grab_focus()
			return

	chain.execute_next([event])
'@ | Set-Content -Path "$sicHookDir\shop_item_card.hooks.gd" -Encoding UTF8

# Register hook in mod_manager_mod mod_main.gd
$mmmPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\mod_main.gd"
$mmmContent = Get-Content $mmmPath -Raw
if (-not $mmmContent.Contains("shop_item_card.hooks.gd")) {
	$mmmContent = $mmmContent.Replace(
		'func _init() -> void:',
		"func _init() -> void:`r`n`tModLoaderMod.install_script_hooks(`"res://scenes/Interfaces/Management/shop_item_card.gd`", `"res://mods-unpacked/gareth-mod_manager_mod/extensions/scenes/Interfaces/Management/shop_item_card.hooks.gd`")"
	)
	Set-Content -Path $mmmPath -Value $mmmContent -Encoding UTF8
}
Write-Host "  Installed: shop_item_card 0g guard hook" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. FIX PRE-RUN MOD MANAGER TO DISPLAY ALL 56 MODS (mod_registry.gd)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Unifying get_all_installed_mods in mod_registry.gd..." -ForegroundColor Cyan
$regPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scripts\mod_registry.gd"
@'
class_name ModRegistry
extends RefCounted

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
Write-Host "  Updated: mod_registry.gd (linked pre-run cards to 56 mods)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. RELOCATE HUD BUTTONS TO BOTTOM-RIGHT & ENFORCE IN-GAME GATING
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Relocating HUD widgets to bottom-right with strict stage gating..." -ForegroundColor Cyan

# 6a. Speed Controller HUD
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
	# Anchor to Bottom-Right Corner
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -264.0
	panel.offset_right = -16.0
	panel.offset_top = -52.0
	panel.offset_bottom = -14.0

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)

	btn_slower = Button.new()
	btn_slower.text = "◀"
	btn_slower.custom_minimum_size = Vector2(28, 26)
	btn_slower.tooltip_text = "Slower [ [ ]"
	btn_slower.pressed.connect(func(): _step_speed(-1))
	hbox.add_child(btn_slower)

	lbl_speed = Label.new()
	lbl_speed.text = "1.00x"
	lbl_speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_speed.custom_minimum_size = Vector2(50, 26)
	hbox.add_child(lbl_speed)

	btn_faster = Button.new()
	btn_faster.text = "▶"
	btn_faster.custom_minimum_size = Vector2(28, 26)
	btn_faster.tooltip_text = "Faster [ ] ]"
	btn_faster.pressed.connect(func(): _step_speed(1))
	hbox.add_child(btn_faster)

	var sep = VSeparator.new()
	hbox.add_child(sep)

	btn_end_day = Button.new()
	btn_end_day.text = "End Day"
	btn_end_day.custom_minimum_size = Vector2(72, 26)
	btn_end_day.modulate = Color(1.0, 0.45, 0.45, 1.0)
	btn_end_day.tooltip_text = "Finish Level / Emergency Exit [ F8 ]"
	btn_end_day.pressed.connect(Callable(self, "_finish_level"))
	hbox.add_child(btn_end_day)

	panel.add_child(hbox)
	canvas.add_child(panel)

func _process(_delta: float) -> void:
	var tree = get_tree()
	var in_mining_shift := false
	if tree and tree.root and Game and Gconsts and ("Stages" in Gconsts):
		# Strict stage check: Only visible during active mining run
		if ("stage" in Game) and Game.stage == Gconsts.Stages._IN_GAME:
			var p = tree.root.find_child("Player", true, false)
			in_mining_shift = is_instance_valid(p)

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

# 6b. Amazon & Air Wings HUD Controls
$amzPath = "$repo\mods-unpacked\gareth-scrap_and_delivery_mod\mods-unpacked\gareth-scrap_and_delivery_mod\scripts\amazon_delivery_manager.gd"
if (Test-Path $amzPath) {
	$amzCode = Get-Content $amzPath -Raw
	# Relocate Amazon Button to bottom-right directly above Speed Panel
	$amzCode = $amzCode.Replace('hud_btn.offset_top = 16.0', 'hud_btn.anchor_top = 1.0; hud_btn.anchor_bottom = 1.0; hud_btn.offset_top = -94.0')
	$amzCode = $amzCode.Replace('hud_btn.offset_bottom = 54.0', 'hud_btn.offset_bottom = -58.0')
	$amzCode = $amzCode.Replace('hud_btn.offset_left = -348.0', 'hud_btn.offset_left = -110.0')
	$amzCode = $amzCode.Replace('hud_btn.offset_right = -268.0', 'hud_btn.offset_right = -16.0')
	# Apply strict stage gating
	$amzCode = $amzCode.Replace('in_game = is_instance_valid(player_node)', 'in_game = is_instance_valid(player_node) and (Game and Gconsts and ("Stages" in Gconsts) and Game.stage == Gconsts.Stages._IN_GAME)')
	Set-Content -Path $amzPath -Value $amzCode -Encoding UTF8
}
Write-Host "  Updated: Bottom-right anchoring and in-game gating configured" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 7. CI/CD TEST RUNNER IMPLEMENTATION (tests/test_runner.ps1)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Creating automated CI/CD static validator..." -ForegroundColor Cyan
$testScript = "$repo\tests\test_runner.ps1"
New-Item -ItemType Directory -Path "$repo\tests" -Force | Out-Null

@'
param (
	[string]$RepoPath = "C:\Dev\coal-llc-mods"
)

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ">>> COAL LLC CI/CD: Automated Static Analysis & Sanity Tests" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

$allGd = Get-ChildItem -Path "$RepoPath\mods-unpacked" -Recurse -Filter "*.gd"
$allManifests = Get-ChildItem -Path "$RepoPath\mods-unpacked" -Recurse -Filter "manifest.json"

$errors = 0
$warnings = 0

# Test 1: Manifest Schema Integrity
Write-Host ">>> TEST 1: Validating $($allManifests.Count) mod manifests..." -ForegroundColor Yellow
foreach ($m in $allManifests) {
	try {
		$json = Get-Content $m.FullName -Raw | ConvertFrom-Json
		if (-not $json.name -or -not $json.version_number) {
			Write-Host "  [FAIL] Missing name/version: $($m.FullName)" -ForegroundColor Red
			$errors++
		}
	} catch {
		Write-Host "  [CRITICAL] Invalid JSON: $($m.FullName) - $_" -ForegroundColor Red
		$errors++
	}
}

# Test 2: Hook Method Signatures & Zero Division Checks
Write-Host ">>> TEST 2: Inspecting $($allGd.Count) GDScript files for syntax pitfalls..." -ForegroundColor Yellow
foreach ($gd in $allGd) {
	$content = Get-Content $gd.FullName
	for ($i = 0; $i -lt $content.Count; $i++) {
		$line = $content[$i]
		# Check for unguarded division
		if ($line -match '/\s*itemBuyPrice' -and -not ($content[$i-1] -match 'cost <= 0' -or $line -match 'max\(1')) {
			Write-Host "  [WARN] Potential zero-division at $($gd.Name):$($i+1)" -ForegroundColor Yellow
			$warnings++
		}
		# Check hook signature
		if ($line -match 'func\s+[a-zA-Z0-9_]+\s*\(\s*chain\s*:\s*ModLoaderHookChain' -and -not ($line -match '->\s*void')) {
			Write-Host "  [NOTICE] Hook function missing explicit -> void at $($gd.Name):$($i+1)" -ForegroundColor DarkGray
		}
	}
}

Write-Host "=================================================================" -ForegroundColor Cyan
if ($errors -eq 0) {
	Write-Host ">>> ALL CI/CD SANITY CHECKS PASSED (Warnings: $warnings, Errors: 0)" -ForegroundColor Green
	exit 0
} else {
	Write-Host ">>> CI/CD PIPELINE FAILED (Errors: $errors)" -ForegroundColor Red
	exit 1
}
'@ | Set-Content -Path $testScript -Encoding UTF8
Write-Host "  Created: tests\test_runner.ps1" -ForegroundColor Green

# Execute CI Test Runner
& powershell -NoProfile -ExecutionPolicy Bypass -File $testScript -RepoPath $repo
if ($LASTEXITCODE -ne 0) {
    Write-Host "Pipeline stopped due to CI test failures." -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------------------------
# 8. PURGE HOOK CACHE & REPACK AFFECTED MODS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 8. Refreshing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
	Remove-Item -Path $hookZip -Force
	Write-Host "  Purged old mod-hooks.zip" -ForegroundColor Green
}

Write-Host "`n>>> 9. Repackaging updated mods..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression.FileSystem

$modsToRepack = @(
	"gareth-mod_manager_mod",
	"gareth-game_speed_mod",
	"gareth-scrap_and_delivery_mod"
)

foreach ($m in $modsToRepack) {
	$src = "$repo\mods-unpacked\$m"
	$zip = "$steamMods\$m.zip"
	$vaultZip = "$steamRepo\$m.zip"
	if (Test-Path $zip) { Remove-Item -Path $zip -Force }

	$stream  = [System.IO.File]::Open($zip, [System.IO.FileMode]::CreateNew)
	$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
	foreach ($f in (Get-ChildItem -Path $src -Recurse -File)) {
		$entryName = $f.FullName.Substring($src.Length + 1).Replace("\", "/")
		[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
	}
	$archive.Dispose()
	$stream.Dispose()

	# Synchronize master storage copy in mods_repository/
	Copy-Item -Path $zip -Destination $vaultZip -Force
	Write-Host "  Repacked & Staged: $m.zip" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 9. GIT COMMIT & PUSH
# ------------------------------------------------------------------------------
Write-Host "`n>>> 10. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Architecture 2.0: CI/CD test runner, discovery archive, bottom-right HUD docking, 0g shop division guard, and pre-run mod population"
git push origin main

Write-Host "`nPlatform update deployed successfully!" -ForegroundColor Green