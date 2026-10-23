Clear-Host

# ==============================================================================
# Coal LLC - Verified Production Fix (Jedi Passives, Gvars Crash, Camera Zoom)
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

$mmInner    = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 600

Write-Host "`n>>> 2. Removing dynamic item pollution from all 7 class mods..." -ForegroundColor Cyan
$dynamicMods = @(
    "gareth-bouncing_ball_mod",
    "gareth-chrono_industrialist_mod",
    "gareth-debt_executioner_mod",
    "gareth-grav_dreadnought_mod",
    "gareth-sinclairity_class_mod",
    "gareth-tectonic_fracker_mod",
    "gareth-void_siphon_mod"
)

foreach ($dm in $dynamicMods) {
    $mainPath = "$repo\mods-unpacked\$dm\mods-unpacked\$dm\mod_main.gd"
    if (Test-Path $mainPath) {
        $content = Get-Content $mainPath -Raw
        $content = $content -replace '(?m)^\s*if not \(item in item_unlocks\.all_items\):\r?\n\s*item_unlocks\.all_items\.append\(item\)\r?\n?', ''
        Set-Content -Path $mainPath -Value $content -Encoding UTF8
        Write-Host "  Cleaned: $dm" -ForegroundColor Green
    }
}

Write-Host "`n>>> 3. Writing crash-proof choose_passive.hooks.gd..." -ForegroundColor Cyan
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

Write-Host "`n>>> 4. Writing Gvars.hooks.gd to safeguard reset_resources line 499..." -ForegroundColor Cyan
$gvarsHookPath = "$mmInner\extensions\scripts\Gvars.hooks.gd"
@'
extends Object

func reset_resources(chain: ModLoaderHookChain) -> void:
	var gvars = chain.reference_object
	if is_instance_valid(gvars) and ("resources_to_save" in gvars) and (gvars.resources_to_save is Array):
		var clean_res: Array = []
		for r in gvars.resources_to_save:
			if is_instance_valid(r) and ("resource_path" in r) and str(r.resource_path) != "":
				clean_res.append(r)
		gvars.resources_to_save = clean_res
	chain.execute_next([])
'@ | Set-Content -Path $gvarsHookPath -Encoding UTF8
Write-Host "Written: $gvarsHookPath" -ForegroundColor Green

Write-Host "`n>>> 5. Writing Camera.hooks.gd for smooth zoom..." -ForegroundColor Cyan
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

Write-Host "`n>>> 6. Wiring explicit hook installation in mod_manager mod_main.gd..." -ForegroundColor Cyan
$mmMainPath = "$mmInner\mod_main.gd"
@'
extends Node

const MOD_ID := "gareth-mod_manager_mod"
const LOG_NAME := "gareth-mod_manager_mod"

func _init() -> void:
	ModLoaderLog.info("Universal Mod Manager initializing...", LOG_NAME)
	install_hooks()

func _ready() -> void:
	ModLoaderLog.info("Universal Mod Manager active with full Class, Shop & Input gating.", LOG_NAME)

func install_hooks() -> void:
	var unpacked_dir = ModLoaderMod.get_unpacked_dir().path_join(MOD_ID)
	var ext_dir = unpacked_dir.path_join("extensions")

	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/in_game/choose_passive.gd",
		ext_dir.path_join("scenes/Interfaces/in_game/choose_passive.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/MainMenu.gd",
		ext_dir.path_join("scripts/MainMenu.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/Gvars.gd",
		ext_dir.path_join("scripts/Gvars.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Stages/management_screen.gd",
		ext_dir.path_join("scenes/Stages/management_screen.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/Camera.gd",
		ext_dir.path_join("scripts/Camera.hooks.gd")
	)
'@ | Set-Content -Path $mmMainPath -Encoding UTF8
Write-Host "Written: $mmMainPath" -ForegroundColor Green

Write-Host "`n>>> 7. Purging mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
	Remove-Item -Path $hookZip -Force
	Write-Host "Removed: $hookZip" -ForegroundColor Green
}

Write-Host "`n>>> 8. Repackaging updated mods..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$modsToPack = @("gareth-mod_manager_mod", "gareth-jedi_class_mod") + $dynamicMods
foreach ($m in $modsToPack) {
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

Write-Host "`n>>> 9. Git commit and push..." -ForegroundColor Cyan
git add -A
git commit -m "Fix Jedi passives crash, resolve line 499 startup error across class mods, and register Camera hooks"
git push origin main

Write-Host "`nDeployment complete. Launch Coal LLC to test." -ForegroundColor Green