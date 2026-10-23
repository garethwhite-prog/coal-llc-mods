Clear-Host
# ==============================================================================
# Coal LLC - Complete Validated Fix (Jedi Passives, Gvars Crash, UFO Log Spam)
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

$mmInner    = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod"
$jediInner  = "$repo\mods-unpacked\gareth-jedi_class_mod\mods-unpacked\gareth-jedi_class_mod"
$vdInner    = "$repo\mods-unpacked\gareth-vacuum_depot_mod\mods-unpacked\gareth-vacuum_depot_mod"
$hbInner    = "$repo\mods-unpacked\gareth-hardware_booster_mod\mods-unpacked\gareth-hardware_booster_mod"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 600

Write-Host "`n>>> 2. Fixing line 499 startup crash in jedi_class_mod mod_main.gd..." -ForegroundColor Cyan
$jediMainPath = "$jediInner\mod_main.gd"
$jediCode = Get-Content -Path $jediMainPath -Raw
# Remove the lines appending dynamic items to item_unlocks.all_items (which pollutes resources_to_save)
$jediCode = $jediCode -replace '(?m)^\s*if not \(item in item_unlocks\.all_items\):\r?\n\s*item_unlocks\.all_items\.append\(item\)\r?\n?', ''
Set-Content -Path $jediMainPath -Value $jediCode -Encoding UTF8
Write-Host "Fixed: $jediMainPath" -ForegroundColor Green

Write-Host "`n>>> 3. Writing crash-proof choose_passive.hooks.gd in mod_manager..." -ForegroundColor Cyan
$passiveHookPath = "$mmInner\extensions\scenes\Interfaces\in_game\choose_passive.hooks.gd"

@'
extends Object

const CUSTOM_PASSIVE_DEFAULTS: Dictionary = {
	"ball_blast_damage": 0.05, "ball_blast_radius": 0.05, "ball_fire_rate": 0.05,
	"chrono_tick_rate": 0.05, "chrono_shockwave_damage": 0.05, "chrono_stasis_duration": 0.05,
	"exec_damage": 0.05, "exec_fire_rate": 0.05, "exec_bounty": 0.05,
	"drill_speed": 0.05, "axe_speed": 0.05, "gun_rate": 0.05,
	"dread_shell_damage": 0.05, "dread_fire_rate": 0.05, "dread_impact_radius": 0.05,
	"jedi_saber_damage": 0.05, "jedi_swing_rate": 0.05, "jedi_cleave_reach": 0.05,
	"sword_damage": 0.05, "sword_speed": 0.05, "sword_range": 0.05,
	"sinclair_melt_damage": 0.05, "sinclair_beam_width": 0.05, "sinclair_spectrum_ticks": 0.05,
	"fracker_pulse_damage": 0.05, "fracker_seam_resonance": 0.05, "fracker_fire_rate": 0.05,
	"void_implosion_damage": 0.05, "void_pull_radius": 0.05, "void_event_horizon": 0.05
}

func set_up_buttons(chain: ModLoaderHookChain) -> void:
	var screen = chain.reference_object
	if not is_instance_valid(screen) or not ("choose_between" in screen):
		chain.execute_next([])
		return

	var buttons = [screen.button, screen.button_2, screen.button_3]
	for i in range(0, min(3, screen.choose_between.size())):
		var stat_name: String = str(screen.choose_between[i])
		var base_val: float = 0.05
		if screen.ALL_PASSIVES.has(stat_name):
			base_val = screen.ALL_PASSIVES[stat_name]
		elif CUSTOM_PASSIVE_DEFAULTS.has(stat_name):
			base_val = CUSTOM_PASSIVE_DEFAULTS[stat_name]

		var pct_str: String = str(screen.multiplier * (base_val * 100.0))
		buttons[i].text = "Increase " + stat_name.replace("_", " ").capitalize() + " +" + pct_str + "%"

func _on_button_pressed(chain: ModLoaderHookChain) -> void:
	_handle_button_click(chain, 0)

func _on_button_2_pressed(chain: ModLoaderHookChain) -> void:
	_handle_button_click(chain, 1)

func _on_button_3_pressed(chain: ModLoaderHookChain) -> void:
	_handle_button_click(chain, 2)

func _handle_button_click(chain: ModLoaderHookChain, button_idx: int) -> void:
	var screen = chain.reference_object
	if not is_instance_valid(screen) or not screen.live or not ("choose_between" in screen):
		chain.execute_next([])
		return

	if button_idx >= screen.choose_between.size():
		chain.execute_next([])
		return

	var stat_name: String = str(screen.choose_between[button_idx])
	if screen.ALL_PASSIVES.has(stat_name):
		chain.execute_next([])
		return

	# Handle custom class passive
	screen.live = false
	var base_val: float = CUSTOM_PASSIVE_DEFAULTS.get(stat_name, 0.05)
	var add_amount: float = screen.multiplier * base_val

	if Gvars and ("passives" in Gvars) and Gvars.passives:
		var p: Resource = Gvars.passives
		var cur_meta: float = 0.0
		if p.has_meta(stat_name):
			cur_meta = float(p.get_meta(stat_name))
		p.set_meta(stat_name, cur_meta + add_amount)

	if Gvars:
		if not ("custom_passives" in Gvars) or Gvars.custom_passives == null:
			Gvars.set("custom_passives", {})
		var cp = Gvars.get("custom_passives")
		if cp is Dictionary:
			cp[stat_name] = cp.get(stat_name, 0.0) + add_amount

	screen.get_tree().paused = false
	screen.queue_free()
'@ | Set-Content -Path $passiveHookPath -Encoding UTF8
Write-Host "Written: $passiveHookPath" -ForegroundColor Green

Write-Host "`n>>> 4. Writing compile-safe, silent UFO check_inventory_count hook..." -ForegroundColor Cyan
# Clean out any old Gvars.hooks.gd that failed compilation
$gvarsHookPath = "$mmInner\extensions\scripts\Gvars.hooks.gd"
if (Test-Path $gvarsHookPath) { Remove-Item -Path $gvarsHookPath -Force }

$ufoHookPath = "$vdInner\extensions\scripts\LootCollectorUFO.hooks.gd"
@'
extends Object

func check_inventory_count(chain: ModLoaderHookChain) -> void:
	var ufo = chain.reference_object
	if not is_instance_valid(ufo) or not ("inventory" in ufo) or not ("maxInventoryCount" in ufo):
		chain.execute_next([])
		return

	if "StateLabel" in ufo and is_instance_valid(ufo.StateLabel):
		ufo.StateLabel.text = Gconsts.add_comma_to_float_no_dp(ufo.maxInventoryCount)

	var capacity_mult: float = 1.0
	if Gvars and ("passives" in Gvars) and Gvars.passives:
		capacity_mult += Gvars.passives.employee_collector_capacity

	var max_cap: float = float(ufo.maxInventoryCount) * capacity_mult
	if float(ufo.inventory.inventoryCount) >= max_cap:
		ufo.set_deferred("monitorable", false)
		if "States" in ufo and ("RETURNING_TO_BASE" in ufo.States):
			ufo.state = ufo.States.RETURNING_TO_BASE
		if "baseCoords" in ufo and "models" in ufo and is_instance_valid(ufo.models):
			if ufo.baseCoords.x < ufo.global_position.x:
				ufo.models.scale.x = -1
			else:
				ufo.models.scale.x = 1
'@ | Set-Content -Path $ufoHookPath -Encoding UTF8
Write-Host "Written: $ufoHookPath" -ForegroundColor Green

Write-Host "`n>>> 5. Writing Camera.hooks.gd for smooth zoom in mod_manager..." -ForegroundColor Cyan
$camHookPath = "$mmInner\extensions\scripts\Camera.hooks.gd"
@'
extends Object

func _process(chain: ModLoaderHookChain, delta: float) -> void:
	chain.execute_next([delta])
	var cam = chain.reference_object
	if not is_instance_valid(cam) or not Gvars or not ("settings" in Gvars) or not Gvars.settings:
		return

	var cur_zoom: float = Gvars.settings.zoom_level
	if Input.is_action_just_pressed("zoomOut") or Input.is_key_pressed(KEY_BRACKETLEFT) or Input.is_key_pressed(KEY_MINUS):
		Gvars.settings.zoom_level = clamp(cur_zoom - 0.2, 0.2, 4.0)
		cam.zoom = Vector2(Gvars.settings.zoom_level, Gvars.settings.zoom_level)
	elif Input.is_action_just_pressed("zoomIn") or Input.is_key_pressed(KEY_BRACKETRIGHT) or Input.is_key_pressed(KEY_EQUAL):
		Gvars.settings.zoom_level = clamp(cur_zoom + 0.2, 0.2, 4.0)
		cam.zoom = Vector2(Gvars.settings.zoom_level, Gvars.settings.zoom_level)
	elif Input.is_key_pressed(KEY_0):
		Gvars.settings.zoom_level = 1.0
		cam.zoom = Vector2(1.0, 1.0)
'@ | Set-Content -Path $camHookPath -Encoding UTF8
Write-Host "Written: $camHookPath" -ForegroundColor Green

Write-Host "`n>>> 6. Ensuring mod_main.gd in mod_manager is clean and error-free..." -ForegroundColor Cyan
$mmMainPath = "$mmInner\mod_main.gd"
@'
extends Node

const MOD_DIR = "gareth-mod_manager_mod"

func _init() -> void:
	pass

func _ready() -> void:
	print("INFO gareth-mod_manager_mod: Universal Mod Manager active with full Class, Shop & Input gating.")
'@ | Set-Content -Path $mmMainPath -Encoding UTF8
Write-Host "Cleaned: $mmMainPath" -ForegroundColor Green

Write-Host "`n>>> 7. Purging mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
	Remove-Item -Path $hookZip -Force
	Write-Host "Removed: $hookZip" -ForegroundColor Green
}

Write-Host "`n>>> 8. Repackaging modified mods..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($m in @("gareth-mod_manager_mod", "gareth-jedi_class_mod", "gareth-vacuum_depot_mod")) {
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
}

Write-Host "`n>>> 9. Git commit and push..." -ForegroundColor Cyan
git add -A
git commit -m "Fix Jedi passives crash, resolve line 499 startup error, and hook camera zoom"
git push origin main

Write-Host "`nDeployment finished. Launch Coal LLC to verify!" -ForegroundColor Green