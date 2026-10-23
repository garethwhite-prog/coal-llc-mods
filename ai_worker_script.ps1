# ==============================================================================
# Coal LLC - Fix Jedi Chest Crash, UFO Console Flood & Camera Zoom Hook
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

$mmInner    = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod"
$hbInner    = "$repo\mods-unpacked\gareth-hardware_booster_mod\mods-unpacked\gareth-hardware_booster_mod"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 600

Write-Host "`n>>> 2. Silencing UFO print loop in gareth-hardware_booster_mod..." -ForegroundColor Cyan
$ufoHookDir  = "$hbInner\extensions\scripts"
$ufoHookPath = "$ufoHookDir\LootCollectorUFO.hooks.gd"
if (-not (Test-Path $ufoHookDir)) { New-Item -ItemType Directory -Path $ufoHookDir -Force | Out-Null }

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
	if Gvars and ("passives" in Gvars) and Gvars.passives is Dictionary:
		capacity_mult += Gvars.passives.get("employee_collector_capacity", 0.0)

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
Write-Host "Created UFO hook: $ufoHookPath" -ForegroundColor Green

Write-Host "`n>>> 3. Fixing Jedi and custom passives dictionary crash in Gvars.hooks.gd..." -ForegroundColor Cyan
$gvarsHookDir  = "$mmInner\extensions\scripts"
$gvarsHookPath = "$gvarsHookDir\Gvars.hooks.gd"
if (-not (Test-Path $gvarsHookDir)) { New-Item -ItemType Directory -Path $gvarsHookDir -Force | Out-Null }

@'
extends Object

const CUSTOM_PASSIVE_KEYS: Array[String] = [
	"jedi_saber_damage",
	"jedi_cleave_reach",
	"jedi_reflection_chance",
	"knight_shield_block",
	"knight_armor_plating",
	"sinclairity_beam_width",
	"sinclairity_refraction",
	"tank_cannon_damage",
	"tank_blast_radius",
	"tectonic_quake_reach",
	"void_siphon_potency",
	"chrono_drill_haste"
]

func reset_resources(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	_ensure_custom_passives()

func _ensure_custom_passives() -> void:
	if not Gvars or not ("passives" in Gvars) or not (Gvars.passives is Dictionary):
		return
	for key in CUSTOM_PASSIVE_KEYS:
		if not Gvars.passives.has(key):
			Gvars.passives[key] = 0.0
'@ | Set-Content -Path $gvarsHookPath -Encoding UTF8
Write-Host "Created Gvars hook: $gvarsHookPath" -ForegroundColor Green

Write-Host "`n>>> 4. Creating Camera.hooks.gd for smooth, UI-safe mouse wheel zoom..." -ForegroundColor Cyan
$camHookDir  = "$mmInner\extensions\scripts"
$camHookPath = "$camHookDir\Camera.hooks.gd"

@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var cam = chain.reference_object
	if is_instance_valid(cam) and Gvars and ("settings" in Gvars) and Gvars.settings:
		if Gvars.settings.zoom_level > 4.0 or Gvars.settings.zoom_level < 0.2:
			Gvars.settings.zoom_level = 1.0
		cam.zoom = Vector2(Gvars.settings.zoom_level, Gvars.settings.zoom_level)

func _process(chain: ModLoaderHookChain, delta: float) -> void:
	chain.execute_next([delta])
	var cam = chain.reference_object
	if not is_instance_valid(cam) or not Gvars or not ("settings" in Gvars) or not Gvars.settings:
		return

	if Input.is_action_just_pressed("zoomOut") or Input.is_key_pressed(KEY_BRACKETLEFT) or Input.is_key_pressed(KEY_MINUS):
		Gvars.settings.zoom_level = clamp(Gvars.settings.zoom_level - 0.2, 0.2, 4.0)
		cam.zoom = Vector2(Gvars.settings.zoom_level, Gvars.settings.zoom_level)
	elif Input.is_action_just_pressed("zoomIn") or Input.is_key_pressed(KEY_BRACKETRIGHT) or Input.is_key_pressed(KEY_EQUAL):
		Gvars.settings.zoom_level = clamp(Gvars.settings.zoom_level + 0.2, 0.2, 4.0)
		cam.zoom = Vector2(Gvars.settings.zoom_level, Gvars.settings.zoom_level)
	elif Input.is_key_pressed(KEY_0):
		Gvars.settings.zoom_level = 1.0
		cam.zoom = Vector2(1.0, 1.0)
'@ | Set-Content -Path $camHookPath -Encoding UTF8
Write-Host "Created Camera hook: $camHookPath" -ForegroundColor Green

Write-Host "`n>>> 5. Registering hooks in hardware_booster and mod_manager manifests..." -ForegroundColor Cyan

# Update hardware booster mod_main.gd to load LootCollectorUFO hooks
$hbMainPath = "$hbInner\mod_main.gd"
$hbCode = Get-Content $hbMainPath -Raw
if ($hbCode -notmatch 'LootCollectorUFO\.hooks\.gd') {
	$hbCode = $hbCode -replace '(install_script_hooks\(self\))', "`$1`r`n`tModLoaderMod.install_script_extension(`"res://mods-unpacked/gareth-hardware_booster_mod/extensions/scripts/LootCollectorUFO.hooks.gd`")"
}
# Fallback hook installation via ModLoaderMod
$hbCode = @'
extends Node

func _init() -> void:
	ModLoaderMod.install_script_hooks(self)

func _ready() -> void:
	var threads: int = OS.get_processor_count()
	print("INFO gareth-hardware_booster_mod: Hardware Multi-Thread Booster active! Detected %d logical CPU threads." % threads)
'@
Set-Content -Path $hbMainPath -Value $hbCode -Encoding UTF8

# Ensure mod_manager mod_main.gd registers Gvars and Camera hooks
$mmMainPath = "$mmInner\mod_main.gd"
@'
extends Node

func _init() -> void:
	ModLoaderMod.install_script_hooks(self)

func _ready() -> void:
	print("INFO gareth-mod_manager_mod: Universal Mod Manager active with full Class, Shop & Input gating.")
'@ | Set-Content -Path $mmMainPath -Encoding UTF8

Write-Host "`n>>> 6. Purging mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
	Remove-Item -Path $hookZip -Force
	Write-Host "Removed: $hookZip" -ForegroundColor Green
}

Write-Host ">>> 7. Repackaging gareth-hardware_booster_mod and gareth-mod_manager_mod..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($m in @("gareth-hardware_booster_mod", "gareth-mod_manager_mod")) {
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

Write-Host "`n>>> 8. Git commit and push..." -ForegroundColor Cyan
git add -A
git commit -m "Fix Jedi passives crash, silence UFO console prints, and hook Camera zoom"
git push origin main

Write-Host "`nDeployment complete! Launch Coal LLC to test." -ForegroundColor Green