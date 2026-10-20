Clear-Host;

# ==============================================================================
# Coal LLC - Fix Gunslinger Passive Order & Safeguard Mod Configs
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

Write-Host "`n>>> 2. Populating valid gunslinger.json in AppData..." -ForegroundColor Cyan
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
Write-Host "Populated: $gunslingerConfigPath" -ForegroundColor Green

Write-Host "`n>>> 3. Patching choose_passive.hooks.gd with defensive key access..." -ForegroundColor Cyan
$choosePassiveHook = "$innerDir\extensions\scenes\Interfaces\in_game\choose_passive.hooks.gd"
if (Test-Path $choosePassiveHook) {
    $code = Get-Content -Path $choosePassiveHook -Raw
    # Replace unsafe direct dot access with safe dictionary get
    $code = $code -replace 'var passive_order = config\.data\.passive_order', 'var passive_order = config.data.get("passive_order", []) if config and ("data" in config) and config.data is Dictionary else []'
    Set-Content -Path $choosePassiveHook -Value $code -Encoding UTF8
    Write-Host "Patched: $choosePassiveHook" -ForegroundColor Green
}

Write-Host "`n>>> 4. Patching passive_order.gd to handle empty configs..." -ForegroundColor Cyan
$passiveOrderScript = "$innerDir\scenes\passive_order.gd"
if (Test-Path $passiveOrderScript) {
    $code = Get-Content -Path $passiveOrderScript -Raw
    # Ensure config.data.passive_order is defensively initialized if missing
    $pattern = 'var passive_order = config\.data\.passive_order'
    $replacement = 'if not config.data.has("passive_order"): config.data["passive_order"] = []`n	var passive_order = config.data["passive_order"]'
    $code = $code -replace $pattern, $replacement
    Set-Content -Path $passiveOrderScript -Value $code -Encoding UTF8
    Write-Host "Patched: $passiveOrderScript" -ForegroundColor Green
}

Write-Host "`n>>> 5. Repackaging NanobotZ-AutoPassiveChooser.zip..." -ForegroundColor Cyan
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

Write-Host "`n>>> 6. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Fix Gunslinger passive order empty config crash and add safe dictionary fallbacks"
git push origin main

Write-Host "`nDeployed! Launch Coal LLC to test Settings -> Passive Order." -ForegroundColor Green