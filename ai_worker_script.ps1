cls

# ==============================================================================
# Coal LLC - Integrate Elemental Passives into nanobotz-autopassivechooser
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"
$nbModName  = "nanobotz-autopassivechooser"
$outerDir   = "$repo\mods-unpacked\$nbModName"
$innerDir   = "$outerDir\mods-unpacked\$nbModName"
$zipPath    = "$steamMods\$nbModName.zip"

Set-Location $repo

Write-Host ">>> 1. Extracting $nbModName from Steam to local repository..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

if (-not (Test-Path $outerDir)) {
    New-Item -ItemType Directory -Path $outerDir -Force | Out-Null
}

$zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
foreach ($entry in $zip.Entries) {$destPath = Join-Path $outerDir $entry.FullName
    $parentDir = Split-Path $destPath
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }
    if (-not $entry.FullName.EndsWith("/")) {
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destPath,$true)
    }
}
$zip.Dispose()
Write-Host "Extracted into: $outerDir" -ForegroundColor Green

Write-Host "`n>>> 2. Patching passive_order.gd to include elemental & tick passives..." -ForegroundColor Cyan
$orderScriptPath = "$innerDir\scenes\passive_order.gd"
if (Test-Path $orderScriptPath) {
    $scriptText = Get-Content $orderScriptPath -Raw
    
    # Replace get_possible_passives_for_professions with version that appends elemental perks
    $pattern = 'func get_possible_passives_for_professions\(profession_name: String\) -> Array:[\s\S]*?return ChoosePassive\.ALL_PASSIVES\.keys\(\)'
    $replacement = @'
func get_possible_passives_for_professions(profession_name: String) -> Array:
	var passives: Array = []
	for profession_idx in Gvars.get("profession_manager").get("all_professions"):
		var profession = Gvars.get("profession_manager").get("all_professions")[profession_idx]
		if profession_name.to_lower() == profession.profession.profession_name.to_lower():
			var data = {"unlocked_passives": []}
			data = profession.profession._profession_effect(data)
			passives = data["unlocked_passives"].duplicate()
			break

	if passives.is_empty():
		passives = ChoosePassive.ALL_PASSIVES.keys().duplicate()

	# Ensure elemental & tick rate bonuses are always configurable
	var extras: Array = ["fire_damage", "wet_damage", "poison_damage", "elemental_tick_rate"]
	for ep in extras:
		if not passives.has(ep):
			passives.append(ep)

	return passives
'@
    $scriptText = $scriptText -replace $pattern, $replacement
    Set-Content -Path $orderScriptPath -Value $scriptText -Encoding UTF8
    Write-Host "Updated: $orderScriptPath" -ForegroundColor Green
}

Write-Host "`n>>> 3. Patching choose_passive.hooks.gd (enabled check & safe stat lookup)..." -ForegroundColor Cyan
$cpHookPath = "$innerDir\extensions\scenes\Interfaces\in_game\choose_passive.hooks.gd"
if (Test-Path $cpHookPath) {
@'
extends Object

var NanobotzAutoPassiveChooserMod = load("res://mods-unpacked/nanobotz-autopassivechooser/mod_main.gd")


func _process(chain: ModLoaderHookChain, delta: float) -> void:
	chain.execute_next([delta])

	var config = NanobotzAutoPassiveChooserMod.get_or_create_config()
	var passive_order = config.data.passive_order
	var reroll_if_no_matches = config.data.reroll_if_no_matches

	var find_passive_idx := func (choose_between: Array) -> int:
		for passive in passive_order:
			# Respect the checkbox: never auto-pick disabled passives
			if not passive.get("enabled", false):
				continue

			for i in range(0, 3):
				var eff: String = choose_between[i]
				if eff == passive.effect:
					# Safe lookup across vanilla passives and mod custom_passives
					var cur_val: float = 0.0
					if Gvars and ("passives" in Gvars) and Gvars.passives and (eff in Gvars.passives):
						cur_val = float(Gvars.passives.get(eff)) * 100.0
					elif Gvars and ("custom_passives" in Gvars) and (Gvars.custom_passives is Dictionary) and Gvars.custom_passives.has(eff):
						cur_val = float(Gvars.custom_passives[eff]) * 100.0

					var cap: float = float(passive.get("upTo", 0.0))
					if cap <= 0.0 or cur_val < cap:
						return i
		return -1

	var orig := chain.reference_object as ChoosePassive
	if orig.live and len(orig.choose_between) > 0:
		var idx: int = find_passive_idx.call(orig.choose_between)
		var button_text: String = ""
		match idx:
			0:
				orig._on_button_pressed.call()
				button_text = orig.button.text
			1:
				orig._on_button_2_pressed.call()
				button_text = orig.button_2.text
			2:
				orig._on_button_3_pressed.call()
				button_text = orig.button_3.text
			_:
				if reroll_if_no_matches:
					orig._on_reroll_pressed.call()
					button_text = "Cash"

		if button_text != "":
			var effect_scene = load("res://mods-unpacked/nanobotz-autopassivechooser/scenes/effect_gain.tscn")
			if effect_scene:
				var effect_text: Node = effect_scene.instantiate()
				var player: Player = Game.player
				if player:
					player.add_child(effect_text)
					effect_text.set_text(button_text)

			ModLoaderLog.info("Auto choosing option " + str(idx) + ": " + button_text, NanobotzAutoPassiveChooserMod.MOD_ID)
'@ | Set-Content -Path $cpHookPath -Encoding UTF8
    Write-Host "Updated: $cpHookPath" -ForegroundColor Green
}

Write-Host "`n>>> 4. Flushing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 5. Repackaging nanobotz-autopassivechooser.zip for Steam..." -ForegroundColor Cyan
if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force
}

$zipStream = [System.IO.File]::Open($zipPath, [System.IO.FileMode]::CreateNew)
$archive   = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create)
$allFiles  = Get-ChildItem -Path $outerDir -Recurse -File

foreach ($f in $allFiles) {
    $entryName = $f.FullName.Substring($outerDir.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$zipStream.Dispose()
Write-Host "Packed archive at: $zipPath" -ForegroundColor Green

Write-Host ">>> 6. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Support elemental and tick passives in nanobotz-autopassivechooser UI and execution"
git push origin main

Write-Host "`nDeploy complete! Launch Coal LLC to test." -ForegroundColor Green