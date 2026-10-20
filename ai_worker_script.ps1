Clear-Host;

# ==============================================================================
# Coal LLC - Fix total_money_earned -> Gvars.CashCount in Elemental Transmutation
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$modName    = "gareth-elemental_transmutation_mod"
$outerDir   = "$repo\mods-unpacked\$modName"
$innerDir   = "$outerDir\mods-unpacked\$modName"
$zipPath    = "$steamMods\$modName.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 600

Write-Host "`n>>> 2. Patching tile_map_chunk.hooks.gd in $modName..." -ForegroundColor Cyan
$chunkHookPath = "$innerDir\extensions\scenes\tilemaps\tile_map_chunk.hooks.gd"

if (Test-Path $chunkHookPath) {
    $content = [System.IO.File]::ReadAllText($chunkHookPath)
    $updated = $content.Replace("Gvars.total_money_earned", "Gvars.CashCount")
    [System.IO.File]::WriteAllText($chunkHookPath, $updated, [System.Text.Encoding]::UTF8)
    Write-Host "Replaced Gvars.total_money_earned with Gvars.CashCount in: $chunkHookPath" -ForegroundColor Green
} else {
    Write-Host "Could not locate: $chunkHookPath" -ForegroundColor Red
}

Write-Host "`n>>> 3. Repackaging $modName.zip..." -ForegroundColor Cyan
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

Write-Host "`n>>> 4. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Fix total_money_earned error by routing bounties to Gvars.CashCount in elemental transmutation mod"
git push origin main

Write-Host "`nPatch deployed successfully! Launch Coal LLC to verify." -ForegroundColor Green