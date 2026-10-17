cls

# ==============================================================================
# Coal LLC - Fix Tectonic Faultline Manifest & Packaging
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

Write-Host ">>> 1. Writing manifest.json to root and inner directories..." -ForegroundColor Cyan
$manifestContent = @'
{
  "name": "gareth-tectonic_faultline_mod",
  "namespace": "gareth",
  "version_number": "1.0.0",
  "description": "Custom Map ID 102: Tectonic Faultline. Superheated strata, brittle seismic fracture seams, and high-pressure Magma Siphons.",
  "dependencies": []
}
'@

# Write to outerDir (becomes manifest.json at the root of the ZIP)
Set-Content -Path "$outerDir\manifest.json" -Value $manifestContent -Encoding UTF8

# Write to innerDir (becomes res://mods-unpacked/gareth-tectonic_faultline_mod/manifest.json)
Set-Content -Path "$innerDir\manifest.json" -Value $manifestContent -Encoding UTF8

# Remove misnamed mod_manifest.json files if present
if (Test-Path "$outerDir\mod_manifest.json") { Remove-Item "$outerDir\mod_manifest.json" -Force }
if (Test-Path "$innerDir\mod_manifest.json") { Remove-Item "$innerDir\mod_manifest.json" -Force }

Write-Host ">>> 2. Flushing mod-hooks.zip to force fresh hook compilation..." -ForegroundColor Cyan
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

Write-Host ">>> 4. Verifying ZIP contents for ModLoader requirements..." -ForegroundColor Cyan
$za = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
$hasRootManifest = $false
$hasInnerManifest = $false
foreach ($e in $za.Entries) {
    if ($e.FullName -eq "manifest.json") { $hasRootManifest = $true }
    if ($e.FullName -eq "mods-unpacked/gareth-tectonic_faultline_mod/manifest.json") { $hasInnerManifest = $true }
}
$za.Dispose()

if ($hasRootManifest -and $hasInnerManifest) {
    Write-Host "SUCCESS: Both root manifest.json and inner manifest.json verified in ZIP!" -ForegroundColor Green
} else {
    Write-Host "WARNING: Manifest check failed: Root=$hasRootManifest, Inner=$hasInnerManifest" -ForegroundColor Red
}

Write-Host ">>> 5. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Fix manifest.json naming and dual-placement for gareth-tectonic_faultline_mod"
git push origin main

Write-Host "`nAll updates deployed cleanly! Restart Coal LLC to test." -ForegroundColor Green