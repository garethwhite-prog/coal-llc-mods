cls

# ==============================================================================
# Coal LLC - Fix Tectonic Faultline Manifest Schema & Packaging
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

Write-Host ">>> 1. Inspecting valid reference manifest from Lost Expedition..." -ForegroundColor Cyan
$refManifestPath = "$repo\mods-unpacked\gareth-lost_expedition_mod\manifest.json"
if (-not (Test-Path $refManifestPath)) {
    $refManifestPath = "$repo\mods-unpacked\gareth-lost_expedition_mod\mods-unpacked\gareth-lost_expedition_mod\manifest.json"
}
if (Test-Path $refManifestPath) {
    Get-Content $refManifestPath \vert{} ForEach-Object { Write-Host "   $_" -ForegroundColor DarkGray }
}

Write-Host "`n>>> 2. Writing schema-compliant manifest.json..." -ForegroundColor Cyan
$manifestContent = @'
{
  "name": "tectonic_faultline_mod",
  "namespace": "gareth",
  "version_number": "1.0.0",
  "description": "Custom Map ID 102: Tectonic Faultline. Superheated strata, brittle seismic fracture seams, and high-pressure Magma Siphons.",
  "dependencies": [],
  "extra": {}
}
'@

# Root of the zip
Set-Content -Path "$outerDir\manifest.json" -Value $manifestContent -Encoding UTF8
# Virtual filesystem path (res://mods-unpacked/gareth-tectonic_faultline_mod/manifest.json)
Set-Content -Path "$innerDir\manifest.json" -Value $manifestContent -Encoding UTF8

Write-Host ">>> 3. Flushing mod-hooks.zip to recompile ModHookPacker..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 4. Repackaging mod archive for Steam..." -ForegroundColor Cyan
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

Write-Host ">>> 5. Validating archive manifest entries..." -ForegroundColor Cyan
$za = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
$rootM = $false
$innerM = $false
foreach ($entry in $za.Entries) {
    if ($entry.FullName -eq "manifest.json") { $rootM = $true }
    if ($entry.FullName -eq "mods-unpacked/gareth-tectonic_faultline_mod/manifest.json") { $innerM = $true }
}
$za.Dispose()

if ($rootM -and $innerM) {
    Write-Host "   Verification PASS: Both root and internal manifests exist." -ForegroundColor Green
} else {
    Write-Host "   Verification FAIL: Root=$rootM, Inner=$innerM" -ForegroundColor Red
}

Write-Host ">>> 6. Git committing and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Fix manifest schema: strip redundant namespace from name, add extra dict"
git push origin main

Write-Host "`nDeploy complete! Launch Coal LLC to test." -ForegroundColor Green