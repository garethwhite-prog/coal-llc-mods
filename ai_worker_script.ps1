cls

# ==============================================================================
# Coal LLC - Register Map 102 into LEVEL_ORDER Array
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$modName    = "gareth-tectonic_faultline_mod"
$outerDir   = "$repo\mods-unpacked\$modName"
$innerDir   = "$outerDir\mods-unpacked\$modName"
$zipPath    = "$steamMods\$modName.zip"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Patching level_select.hooks.gd with LEVEL_ORDER registration..." -ForegroundColor Cyan
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
	if helper_script:
		var helper = helper_script.new()
		helper.ensure_level_registered()
		var ls = chain.reference_object
		if ls and ("LEVEL_ORDER" in ls):
			if not ls.LEVEL_ORDER.has(helper.FAULTLINE_LEVEL_ID):
				ls.LEVEL_ORDER.append(helper.FAULTLINE_LEVEL_ID)
	chain.execute_next([])
'@ | Set-Content -Path "$innerDir\extensions\scenes\Interfaces\Menus\level_select.hooks.gd" -Encoding UTF8
Write-Host "Updated: $innerDir\extensions\scenes\Interfaces\Menus\level_select.hooks.gd" -ForegroundColor Green

Write-Host ">>> 2. Flushing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 3. Repackaging mod archive for Steam..." -ForegroundColor Cyan
if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force
}
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

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

Write-Host ">>> 4. Verifying ZIP contents..." -ForegroundColor Cyan
$za = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
$hasHook = $false
foreach ($e in $za.Entries) {
    if ($e.FullName -match "level_select\.hooks\.gd$") { $hasHook = $true }
}
$za.Dispose()
if ($hasHook) {
    Write-Host "Verification PASS: level_select.hooks.gd confirmed in archive." -ForegroundColor Green
} else {
    Write-Host "Verification FAIL: hook file missing." -ForegroundColor Red
}

Write-Host ">>> 5. Git committing and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Append FAULTLINE_LEVEL_ID (102) to LEVEL_ORDER in level_select.hooks.gd"
git push origin main

Write-Host "`nDeploy complete! Launch Coal LLC to test." -ForegroundColor Green