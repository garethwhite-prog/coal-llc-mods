Clear-Host

$repo      = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = "$steamRoot\mods"

Set-Location $repo

Write-Host ">>> Locating and patching mod_manager_view.gd..." -ForegroundColor Cyan
$viewFiles = Get-ChildItem -Path "$repo\mods-unpacked\gareth-mod_manager_mod" -Recurse -Filter "mod_manager_view.gd"

foreach ($vf in $viewFiles) {
    $content = Get-Content $vf.FullName -Raw
    # Ensure category_order contains all categories
    $oldBlockPattern = 'var category_order\s*:=\s*\[[\s\S]*?\]'
    $newBlock = @'
var category_order := [
		"Classes & Professions",
		"Progression & Upgrades",
		"Custom Maps & Strata",
		"Weapons & Arsenal",
		"Employees & Automation",
		"Quality of Life",
		"Performance & System",
		"Community Add-Ons",
		"Other Mods"
	]
'@
    if ($content -match $oldBlockPattern) {
        $content = [System.Text.RegularExpressions.Regex]::Replace($content, $oldBlockPattern, $newBlock)
        Set-Content -Path $vf.FullName -Value $content -Encoding UTF8
        Write-Host "  Patched: $($vf.FullName.Replace($repo, ''))" -ForegroundColor Green
    }
}

# Repack gareth-mod_manager_mod.zip
Write-Host ">>> Repackaging gareth-mod_manager_mod.zip..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression.FileSystem
$src = "$repo\mods-unpacked\gareth-mod_manager_mod"
$zip = "$steamMods\gareth-mod_manager_mod.zip"
if (Test-Path $zip) { Remove-Item -Path $zip -Force }

$stream  = [System.IO.File]::Open($zip, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $src -Recurse -File)) {
    $entryName = $f.FullName.Substring($src.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Write-Host "  Repacked: gareth-mod_manager_mod.zip" -ForegroundColor Green

git add -A
git commit -m "Update mod_manager_view.gd category_order to display all 56 installed mods"
git push origin main
Write-Host "Mod Manager category patch complete!" -ForegroundColor Green