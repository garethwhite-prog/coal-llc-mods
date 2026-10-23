# ==============================================================================
# Coal LLC - Fix Mod Manager Boot, Jedi Passives Crash & UFO Console Spam
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$dumpRoot   = "$steamRoot\_dump"
$hookZip    = "$steamRoot\mod-hooks.zip"

$mmInner    = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod"
$hbInner    = "$repo\mods-unpacked\gareth-hardware_booster_mod\mods-unpacked\gareth-hardware_booster_mod"
$vdInner    = "$repo\mods-unpacked\gareth-vacuum_depot_mod\mods-unpacked\gareth-vacuum_depot_mod"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 600

Write-Host "`n>>> 2. Restoring mod_main.gd for Mod Manager and Hardware Booster from commit 9f4ab43..." -ForegroundColor Cyan
git checkout 9f4ab43 -- "$mmInner\mod_main.gd"
git checkout 9f4ab43 -- "$hbInner\mod_main.gd"
Write-Host "Restored clean mod_main.gd files" -ForegroundColor Green

Write-Host "`n>>> 3. Inspecting choose_passive.gd around lines 175-210..." -ForegroundColor Cyan
$passivePath = "$dumpRoot\scenes\Interfaces\in_game\choose_passive.gd"
if (Test-Path $passivePath) {
    $pLines = Get-Content -Path $passivePath
    $startP = [Math]::Max(0, 170)
    $endP   = [Math]::Min($pLines.Count - 1, 215)
    for ($i = $startP; $i -le $endP; $i++) {
        Write-Host ("{0,3}: {1}" -f ($i + 1), $pLines[$i])
    }
}

Write-Host "`n>>> 4. Inspecting Gvars.gd around line 499..." -ForegroundColor Cyan
$gvarsPath = "$dumpRoot\scripts\Gvars.gd"
if (Test-Path $gvarsPath) {
    $gLines = Get-Content -Path $gvarsPath
    $startG = [Math]::Max(0, 485)
    $endG   = [Math]::Min($gLines.Count - 1, 515)
    for ($i = $startG; $i -le $endG; $i++) {
        $marker = if ($i -eq 498) { ">>>" } else { "   " }
        Write-Host ("{0} {1,3}: {2}" -f $marker, ($i + 1), $gLines[$i])
    }
}

Write-Host "`n>>> 5. Writing crash-proof choose_passive.hooks.gd in gareth-mod_manager_mod..." -ForegroundColor Cyan
$passiveHookPath = "$mmInner\extensions\scenes\Interfaces\in_game\choose_passive.hooks.gd"

@'
extends Object

const ALL_CUSTOM_PASSIVES: Array[String] = [
	"jedi_saber_damage",
	"jedi_swing_rate",
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
	"chrono_drill_haste",
	"sprint_speed"
]

func _process(chain: ModLoaderHookChain, delta: float) -> void:
	_ensure_passives(chain.reference_object)
	chain.execute_next([delta])

func _ready(chain: ModLoaderHookChain) -> void:
	_ensure_passives(chain.reference_object)
	chain.execute_next([])

func _on_button_pressed(chain: ModLoaderHookChain) -> void:
	_ensure_passives(chain.reference_object)
	chain.execute_next([])

func _on_button_2_pressed(chain: ModLoaderHookChain) -> void:
	_ensure_passives(chain.reference_object)
	chain.execute_next([])

func _on_button_3_pressed(chain: ModLoaderHookChain) -> void:
	_ensure_passives(chain.reference_object)
	chain.execute_next([])

func _ensure_passives(screen: Node) -> void:
	if not Gvars or not ("passives" in Gvars) or not (Gvars.passives is Dictionary):
		return

	for key in ALL_CUSTOM_PASSIVES:
		if not Gvars.passives.has(key):
			Gvars.passives[key] = 0.0

	if is_instance_valid(screen) and ("options" in screen) and screen.options is Array:
		for opt in screen.options:
			if opt and ("stat_name" in opt) and opt.stat_name != "":
				var sname: String = str(opt.stat_name)
				if not Gvars.passives.has(sname):
					Gvars.passives[sname] = 0.0
'@ | Set-Content -Path $passiveHookPath -Encoding UTF8
Write-Host "Updated: $passiveHookPath" -ForegroundColor Green

Write-Host "`n>>> 6. Silencing UFO print spam in gareth-vacuum_depot_mod..." -ForegroundColor Cyan
$ufoHookPath = "$vdInner\extensions\scripts\LootCollectorUFO.hooks.gd"

@'
extends Object

func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	chain.execute_next([delta])

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
Write-Host "Updated: $ufoHookPath" -ForegroundColor Green

Write-Host "`n>>> 7. Purging mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
    Write-Host "Removed: $hookZip" -ForegroundColor Green
}

Write-Host ">>> 8. Repackaging modified mods..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($m in @("gareth-mod_manager_mod", "gareth-hardware_booster_mod", "gareth-vacuum_depot_mod")) {
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
git commit -m "Restore mod_main, auto-seed Jedi class passives, and silence UFO prints"
git push origin main

Write-Host "`nDeployment complete! Launch Coal LLC to test." -ForegroundColor Green