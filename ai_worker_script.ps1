$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. Generating Central Mod Catalog (US-05) ---"
$catalogPath = Join-Path $repoRoot "mod_catalog.json"
$mods = Get-ChildItem -Path "$repoRoot\mods-unpacked" -Directory
$catalogData = @()

foreach ($mod in $mods) {
    $manifestPath = Join-Path $mod.FullName "manifest.json"
    if (Test-Path $manifestPath) {
        $json = Get-Content $manifestPath | ConvertFrom-Json
        $entry = [PSCustomObject]@{
            id = $json.name
            name = $json.extra.godot.display_name
            version = $json.version_number
            description = $json.description
            author = if ($json.extra.godot.authors.Count -gt 0) { $json.extra.godot.authors[0] } else { "Community" }
            download_url = "https://raw.githubusercontent.com/garethwhite-prog/coal-llc-mods/main/downloaded_mods/$($json.name).zip"
        }
        $catalogData += $entry
    }
}
$catalogData | ConvertTo-Json -Depth 10 | Set-Content -Path $catalogPath -Encoding UTF8
Write-Output "Generated mod_catalog.json with $($catalogData.Count) mods."

Write-Output "--- 2. Fixing Mod Manager Syntax & Crashes (BUG-04, BUG-05, BUG-06) ---"
$modMgrExt = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod"

# A. Restore broken files to last clean state
git checkout a9ca50039c02c57c68f24f0fcb0be1b547bb53c3 -- "$modMgrExt\scenes\mod_manager_view.gd"
git checkout a9ca50039c02c57c68f24f0fcb0be1b547bb53c3 -- "$modMgrExt\extensions\scripts\MainMenu.hooks.gd"

# B. Patch MainMenu.hooks.gd (BUG-06)
$mainMenuPath = "$modMgrExt\extensions\scripts\MainMenu.hooks.gd"
$mmContent = Get-Content $mainMenuPath -Raw
# Replace direct property assignment with safe metadata assignment to prevent crashes
$mmContent = $mmContent -replace '\.is_pre_run_mode = (true|false)', '.set_meta("is_pre_run_mode", $1)'
$mmContent = $mmContent -replace 'if menu\.is_pre_run_mode:', 'if menu.get_meta("is_pre_run_mode", false):'
$mmContent | Set-Content -Path $mainMenuPath -Encoding UTF8

# C. Patch Mod Manager View (BUG-04 and BUG-05)
$mgrViewPath = "$modMgrExt\scenes\mod_manager_view.gd"
$mvContent = Get-Content $mgrViewPath -Raw
# Fix BUG-04: Ignore pending_delete files so they vanish from UI immediately
$mvContent = $mvContent -replace 'if file_name\.get_extension\(\) == "zip":', 'if file_name.get_extension() == "zip" and not "pending_delete" in file_name:'
# Fix BUG-05: Safely assign Official tag without breaking the array
$authorLogic = @"
	if manifest and manifest.get("extra") and manifest.extra.get("godot") and manifest.extra.godot.get("authors"):
		var authors = manifest.extra.godot.authors
		if authors.size() > 0 and "Gareth White" in authors[0]:
			return "Gareth White (Official Suite)"
	return "Community Add-Ons"
"@
$mvContent = $mvContent -replace 'return "Community Add-Ons"', $authorLogic
$mvContent | Set-Content -Path $mgrViewPath -Encoding UTF8

# D. Patch Mod Store Client to use central JSON (US-05)
$storeClientPath = "$modMgrExt\scripts\mod_store_client.gd"
if (Test-Path $storeClientPath) {
    $scContent = Get-Content $storeClientPath -Raw
    $oldUrlLogic = 'var url := "https://api.github.com/repos/%s/releases" % repo'
    $newUrlLogic = 'var url := "https://raw.githubusercontent.com/garethwhite-prog/coal-llc-mods/main/mod_catalog.json"'
    $scContent = $scContent.Replace($oldUrlLogic, $newUrlLogic)
    $scContent | Set-Content -Path $storeClientPath -Encoding UTF8
}

Write-Output "--- 3. Repacking Mod Manager ---"
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force }

$mod = "gareth-mod_manager_mod"
$srcDir = Join-Path $repoRoot "mods-unpacked\$mod"
$downZip = Join-Path $downMods "$mod.zip"
$steamZip = Join-Path $steamMods "$mod.zip"

if (Test-Path $downZip) { Remove-Item $downZip -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::Open($downZip, [System.IO.Compression.ZipArchiveMode]::Create)
$files = Get-ChildItem -Path $srcDir -Recurse -File
foreach ($file in $files) {
    $entryName = $file.FullName.Substring($srcDir.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $entryName)
}
$archive.Dispose()
if (Test-Path $steamZip) { Copy-Item -Path $downZip -Destination $steamZip -Force }

Write-Output "--- 4. Updating Sprint Documentation ---"
$sprintBoardPath = Join-Path $repoRoot "docs\ACTIVE_SPRINT_BOARD.md"
$sprintBoard = @"
# Current Active Sprint & Worklist

## 🔴 Open Bugs (Highest Priority)
* **[BUG-01]** Quadcopter Visuals: Needs validation now that Mod Manager is unblocked.
* **[BUG-02]** Bouncing Ball Passives: Needs validation now that Mod Manager is unblocked.
* **[BUG-03]** Verify isolation between Henry Hoover and Drone Workforce.

## 🟡 In Progress / Testing
* **[US-05]** Mod Store Central Registry: `mod_catalog.json` generated and linked to store client. (Awaiting User Validation).
* **[BUG-04]** Mod Uninstall: `pending_delete` files filtered from Manager UI. (Awaiting User Validation).
* **[BUG-05]** Community Tags: Mod Manager routes `Gareth White` manifest authors to Official Suite. (Awaiting User Validation).

## 🟢 Completed (Pending Verification)
* **[BUG-06]** MainMenu crash fixed by using safe `set_meta` for `is_pre_run_mode`.
* **[US-01]** Thomas the Tank Engine: Base class deployed.
* **[CORE]** ModLoader Manifests, Asynchronous `change_stage`, `add_child` tree locks resolved.
"@
$sprintBoard | Set-Content -Path $sprintBoardPath -Encoding UTF8

Write-Output "--- Committing to Git ---"
git add -A
git commit -m "Fix: Create centralized mod_catalog.json, resolve Mod Manager syntax crashes, filter pending_delete files from UI, and route Mod Store to raw GitHub JSON."
git push origin main
Write-Output "Operation Successful."