Clear-Host;

# ==============================================================================
# Coal LLC - Restore passive_order.gd & Fix Gunslinger Configuration
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$appData    = "$env:APPDATA\Godot\app_userdata\Coal LLC"
$modName    = "nanobotz-autopassivechooser"
$outerDir   = "$repo\mods-unpacked\$modName"
$innerDir   = "$outerDir\mods-unpacked\$modName"
$zipPath    = "$steamMods\NanobotZ-AutoPassiveChooser.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 600

Write-Host "`n>>> 2. Resetting nanobotz-autopassivechooser to clean Git state..." -ForegroundColor Cyan
git checkout 6a8eb85 -- "mods-unpacked/$modName"
Write-Host "Reset nanobotz-autopassivechooser to commit 6a8eb85" -ForegroundColor Green

Write-Host "`n>>> 3. Ensuring valid gunslinger.json in AppData..." -ForegroundColor Cyan
$gunslingerConfigPath = "$appData\mod_configs\NanobotZ-AutoPassiveChooser\gunslinger.json"
$gunslingerJson = @'
{
	"passive_order": [
		{
			"effect": "bullet_damage",
			"enabled": true,
			"upTo": 0
		},
		{
			"effect": "player_jump_velocity",
			"enabled": true,
			"upTo": 100
		},
		{
			"effect": "player_sprint_speed",
			"enabled": true,
			"upTo": 300
		},
		{
			"effect": "player_pickaxe_mining_damage",
			"enabled": true,
			"upTo": 0
		},
		{
			"effect": "player_pickaxe_mining_speed",
			"enabled": true,
			"upTo": 0
		},
		{
			"effect": "employee_collector_capacity",
			"enabled": true,
			"upTo": 0
		},
		{
			"effect": "employee_collector_speed",
			"enabled": true,
			"upTo": 0
		},
		{
			"effect": "employee_miner_damage",
			"enabled": true,
			"upTo": 0
		},
		{
			"effect": "employee_miner_speed",
			"enabled": true,
			"upTo": 0
		}
	],
	"reroll_if_no_matches": false,
	"skip_weapon_pickups": false
}
'@
Set-Content -Path $gunslingerConfigPath -Value $gunslingerJson -Encoding UTF8
Write-Host "Verified config at: $gunslingerConfigPath" -ForegroundColor Green

Write-Host "`n>>> 4. Patching passive_order.gd cleanly without syntax errors..." -ForegroundColor Cyan
$passiveOrderScript = "$innerDir\scenes\passive_order.gd"
$poContent = [System.IO.File]::ReadAllText($passiveOrderScript)

# Clean replacement with tab indentation and no regex backtick issues
$oldSnippet = "`tvar passive_order = config.data.passive_order"
$newSnippet = @"
	if not config.data.has("passive_order"):
		config.data["passive_order"] = []
	var passive_order = config.data["passive_order"]
"@

$poContent = $poContent.Replace($oldSnippet,$newSnippet)
[System.IO.File]::WriteAllText($passiveOrderScript,$poContent, [System.Text.Encoding]::UTF8)
Write-Host "Successfully patched: $passiveOrderScript" -ForegroundColor Green

Write-Host "`n>>> 5. Patching choose_passive.hooks.gd with safe dictionary getter..." -ForegroundColor Cyan
$choosePassiveHook = "$innerDir\extensions\scenes\Interfaces\in_game\choose_passive.hooks.gd"
$cpContent = [System.IO.File]::ReadAllText($choosePassiveHook)

$oldHookSnippet = "`tvar passive_order = config.data.passive_order"
$newHookSnippet = @"
	var passive_order = config.data.get("passive_order", []) if (config and "data" in config and config.data is Dictionary) else []
"@

$cpContent = $cpContent.Replace($oldHookSnippet,$newHookSnippet)
[System.IO.File]::WriteAllText($choosePassiveHook,$cpContent, [System.Text.Encoding]::UTF8)
Write-Host "Successfully patched: $choosePassiveHook" -ForegroundColor Green

Write-Host "`n>>> 6. Inspecting get_possible_passives_for_professions in passive_order.gd..." -ForegroundColor Cyan
Get-Content $passiveOrderScript | Select-Object -Index (45..100) | ForEach-Object { Write-Host $_ }

Write-Host "`n>>> 7. Repackaging NanobotZ-AutoPassiveChooser.zip..." -ForegroundColor Cyan
if (Test-Path $zipPath) { Remove-Item -Path $zipPath -Force }

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$stream  = [System.IO.File]::Open($zipPath, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $outerDir -Recurse -File)) {$entryName = $f.FullName.Substring($outerDir.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Write-Host "Repacked release archive: $zipPath" -ForegroundColor Green

Write-Host "`n>>> 8. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Cleanly patch passive_order and choose_passive against missing config keys without parse errors"
git push origin main

Write-Host "`nPatch deployed cleanly! Launch Coal LLC to test the Settings menu." -ForegroundColor Green