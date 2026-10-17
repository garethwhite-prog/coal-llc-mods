cls

# ==============================================================================
# Coal LLC - Fix Tectonic Faultline Manifest Schema (extra.godot)
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

Write-Host ">>> 1. Writing complete schema manifest.json with extra.godot..." -ForegroundColor Cyan
$manifestContent = @'
{
  "name": "tectonic_faultline_mod",
  "namespace": "gareth",
  "version_number": "1.0.0",
  "description": "Custom subterranean faultline map with active magma strata and high-pressure magma siphons.",
  "website_url": "https://github.com/garethwhite-prog/coal-llc-mods",
  "dependencies": [],
  "extra": {
    "godot": {
      "display_name": "Tectonic Faultline",
      "category": "Maps",
      "authors": [
        "Gareth White"
      ],
      "tags": [
        "map",
        "level"
      ],
      "compatible_mod_loader_version": [
        "7.0.1"
      ],
      "compatible_game_version": [
        "1.4.1.1"
      ]
    }
  }
}
'@

# Write to outerDir (zip root) and innerDir (res://mods-unpacked/gareth-tectonic_faultline_mod/manifest.json)
Set-Content -Path "$outerDir\manifest.json" -Value $manifestContent -Encoding UTF8
Set-Content -Path "$innerDir\manifest.json" -Value $manifestContent -Encoding UTF8

Write-Host ">>> 2. Verifying JSON structure locally..." -ForegroundColor Cyan
$parsed = Get-Content "$outerDir\manifest.json" -Raw | ConvertFrom-Json
Write-Host "   Namespace : $($parsed.namespace)" -ForegroundColor DarkGray
Write-Host "   Name      : $($parsed.name)" -ForegroundColor DarkGray
Write-Host "   Expected  : $($parsed.namespace)-$($parsed.name)" -ForegroundColor Green
Write-Host "   Display   : $($parsed.extra.godot.display_name)" -ForegroundColor Green

Write-Host ">>> 3. Flushing mod-hooks.zip..." -ForegroundColor Cyan
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
Write-Host "Packed archive at: $zipPath" -ForegroundColor Green

Write-Host ">>> 5. Git committing and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Populate full extra.godot dictionary in manifest.json for ModLoader validation"
git push origin main

Write-Host "`nDeploy complete! Launch Coal LLC to test." -ForegroundColor Green