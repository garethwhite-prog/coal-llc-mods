$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. FIXING AUTO-PASSIVE BACKEND LOGIC ---"
$choosePassiveHooksPath = "$repoRoot\mods-unpacked\nanobotz-autopassivechooser\mods-unpacked\nanobotz-autopassivechooser\extensions\scenes\Interfaces\in_game\choose_passive.hooks.gd"
if (Test-Path $choosePassiveHooksPath) {
    # Check if the variables are already defined; if not, inject them into the script body
    $content = Get-Content $choosePassiveHooksPath -Raw
    
    if (-not $content.Contains("var NanobotzAutoPassiveChooserMod")) {
        $injectLogic = @"
extends Object

var NanobotzAutoPassiveChooserMod = load("res://mods-unpacked/nanobotz-autopassivechooser/mod_main.gd")
var ModSettingsMod = null

func _get_mod_settings() -> void:
	if ModSettingsMod == null:
		ModSettingsMod = load("res://mods-unpacked/gareth-mod_settings_mod/mod_main.gd")

func get_current_level_for(effect: String) -> float:
	if not Gvars or not "profession_manager" in Gvars: return 0.0
	var manager = Gvars.profession_manager
	if not "current_profession" in manager: return 0.0
	var prof = manager.current_profession
	if not "unlocked_passives" in prof: return 0.0
	
	for p in prof.unlocked_passives:
		if p.get("effect") == effect:
			return p.get("current_value", 0.0)
	return 0.0

func is_passive_valid(passive: Dictionary, config: Dictionary) -> bool:
	if not passive.get("enabled", false): return false
	
	var up_to = passive.get("upTo", 0)
	var effect = passive.get("effect", "")
	
	if up_to > 0:
		var current_lvl = get_current_level_for(effect)
		if current_lvl >= up_to:
			return false
	return true
"@
        # Prepend the injected logic to the script
        $content = $content -replace 'extends Object', $injectLogic
        $content | Set-Content -Path $choosePassiveHooksPath -Encoding UTF8
        Write-Output "Injected backend logic processing for custom passives."
    } else {
        Write-Output "Backend custom variables already exist."
    }
}

Write-Output "--- 2. REPACKING AUTO PASSIVE CHOOSER ---"
$targetMods = @("nanobotz-autopassivechooser")
Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($mod in $targetMods) {
    $srcDir = Join-Path $repoRoot "mods-unpacked\$mod"
    $downZip = Join-Path $downMods "$mod.zip"
    $steamZip = Join-Path $steamMods "$mod.zip"
    
    if (Test-Path $downZip) { Remove-Item $downZip -Force }
    $archive = [System.IO.Compression.ZipFile]::Open($downZip, [System.IO.Compression.ZipArchiveMode]::Create)
    $files = Get-ChildItem -Path $srcDir -Recurse -File
    foreach ($file in $files) {
        $entryName = $file.FullName.Substring($srcDir.Length + 1).Replace("\", "/")
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $entryName)
    }
    $archive.Dispose()
    if (Test-Path $steamZip) { Copy-Item -Path $downZip -Destination $steamZip -Force }
    Write-Output "Deployed $mod.zip"
}

Write-Output "--- Committing to Git ---"
git add -A
git commit -m "Fix: Re-injected backend AutoPassiveChooser processing for custom ball classes and extra employee passives."
git push origin main
Write-Output "Process Complete."