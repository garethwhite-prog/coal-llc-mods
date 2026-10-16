cls

# ==============================================================================
# Coal LLC - Fix Lost Expedition Mod (Manifest Schema & Whitespace Scrub)
# ==============================================================================

$repoRoot      = "C:\Dev\coal-llc-mods"
$modName       = "gareth-lost_expedition_mod"
$outerModDir   = Join-Path $repoRoot "mods-unpacked\$modName"
$innerModDir   = Join-Path $outerModDir "mods-unpacked\$modName"
$steamModsDir  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mods"
$zipPath       = Join-Path $steamModsDir "$modName.zip"

Set-Location $repoRoot

Write-Host ">>> 1. Scrubbing old whitespace folders from Git and Disk..." -ForegroundColor Cyan

# Remove Git-tracked files with leading spaces
git rm -r --cached -f "mods-unpacked/ gareth-lost_expedition_mod" 2>$null

# Remove directories with leading spaces from disk
$badOuter = Join-Path $repoRoot "mods-unpacked\ $modName"
if (Test-Path $badOuter) { Remove-Item -Path $badOuter -Recurse -Force }
Get-ChildItem -Path $steamModsDir -Filter "*lost_expedition*.zip" | Remove-Item -Force

# Recreate correct directory tree
$dirs = @(
    $outerModDir,
    $innerModDir,
    (Join-Path $innerModDir "assets"),
    (Join-Path $innerModDir "entities"),
    (Join-Path $innerModDir "helpers"),
    (Join-Path $innerModDir "extensions\scenes\Interfaces\Menus"),
    (Join-Path $innerModDir "extensions\scenes\tilemaps")
)
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

Write-Host ">>> 2. Resolving manifest schema from existing working mod..." -ForegroundColor Cyan

# Pull extra structure from a verified working mod
$knightManifestPath = Join-Path $repoRoot "mods-unpacked\gareth-knight_class_mod\manifest.json"
$extraBlock = @{}
if (Test-Path $knightManifestPath) {
    $refJson = Get-Content $knightManifestPath -Raw | ConvertFrom-Json
    if ($refJson.extra) {
        $extraBlock = $refJson.extra
    }
}

# Construct manifest with required fields
$manifestObj = [ordered]@{
    "name"            = "lost_expedition_mod"
    "namespace"       = "gareth"
    "version_number"  = "1.0.0"
    "description"     = "Custom subterranean expedition map featuring unexploded ordnance and cryo-pod survivor rescue mechanics."
    "dependencies"    = @()
    "extra"           = $extraBlock
}
$manifestJson = $manifestObj | ConvertTo-Json -Depth 5

Set-Content -Path (Join-Path $outerModDir "manifest.json") -Value $manifestJson -Encoding UTF8
Set-Content -Path (Join-Path $innerModDir "manifest.json") -Value $manifestJson -Encoding UTF8
Write-Host "manifest.json configured with full ModLoader extra schema." -ForegroundColor Green

Write-Host ">>> 3. Packaging $modName.zip cleanly..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$zipStream = [System.IO.File]::Open($zipPath, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create)

$filesToZip = Get-ChildItem -Path $outerModDir -Recurse -File
foreach ($file in $filesToZip) {
    $relative = $file.FullName.Substring($outerModDir.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $relative) | Out-Null
}

$archive.Dispose()
$zipStream.Dispose()
Write-Host "Archive cleanly packed at: $zipPath" -ForegroundColor Green

Write-Host ">>> 4. Staging, committing, and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Fix manifest schema (extra.godot) and remove whitespace from Lost Expedition mod"
git push origin main

Write-Host "`nAll fixed! Run Coal LLC now to test." -ForegroundColor Green