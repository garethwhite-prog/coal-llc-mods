cls

# ==============================================================================
# Coal LLC - Restore ensure_level_registered() in TectonicFaultlineHelper
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$modName    = "gareth-tectonic_faultline_mod"
$outerDir   = "$repo\mods-unpacked\$modName"
$innerDir   = "$outerDir\mods-unpacked\$modName"
$zipPath    = "$steamMods\$modName.zip"
$hookZip    = "$steamRoot\mod-hooks.zip"
$helperPath = "$innerDir\helpers\TectonicFaultlineHelper.gd"

Set-Location $repo

Write-Host ">>> 1. Extracting ensure_level_registered() from git history (HEAD~1)..." -ForegroundColor Cyan
$oldHelper = git show "HEAD~1:mods-unpacked/$modName/mods-unpacked/$modName/helpers/TectonicFaultlineHelper.gd"

$capturing = $false
$funcLines = @()
foreach ($line in ($oldHelper -split "`r?`n")) {
    if ($line -match "static\s+func\s+ensure_level_registered") {
        $capturing = $true
    } elseif ($capturing -and $line -match "^static\s+func\s+(?!ensure_level_registered)") {
        $capturing = $false
    }
    if ($capturing) {
        $funcLines += $line
    }
}

if ($funcLines.Count -eq 0) {
    Write-Host "Fallback: Constructing default ensure_level_registered()..." -ForegroundColor Yellow
    $funcBlock = @'
static func ensure_level_registered() -> void:
	if not Gvars:
		return
	if "level_info" in Gvars and Gvars.level_info is Dictionary:
		if not Gvars.level_info.has(FAULTLINE_LEVEL_ID):
			Gvars.level_info[FAULTLINE_LEVEL_ID] = {
				"name": "Tectonic Faultline",
				"description": "Seismic faultline with superheated vents, magma fissures, and elemental chambers.",
				"depth": 1200,
				"cost": 0,
				"unlocked": true
			}
'@
} else {
    $funcBlock = $funcLines -join "`r`n"
    Write-Host "Successfully extracted original ensure_level_registered() ($($funcLines.Count) lines)." -ForegroundColor Green
}

Write-Host ">>> 2. Updating $helperPath with ensure_level_registered() + 3 Elemental Pod mechanics..." -ForegroundColor Cyan
$currentContent = Get-Content $helperPath -Raw

# Replace after CHUNK_SIZE constant
$targetPattern = "const CHUNK_SIZE: int = 16`r?`n"
$insertion = "const CHUNK_SIZE: int = 16`r`n`r`n" + $funcBlock.Trim() + "`r`n"

if ($currentContent -match $targetPattern) {
    $newContent = [regex]::Replace($currentContent, $targetPattern, $insertion, 1)
    $newContent | Set-Content -Path $helperPath -Encoding UTF8
    Write-Host "Injected ensure_level_registered() into TectonicFaultlineHelper.gd" -ForegroundColor Green
} else {
    Write-Host "Target anchor not found, prepending ensure_level_registered()..." -ForegroundColor Yellow
    ($funcBlock + "`r`n`r`n" + $currentContent) | Set-Content -Path $helperPath -Encoding UTF8
}

Write-Host ">>> 3. Flushing mod-hooks.zip cache..." -ForegroundColor Cyan
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

Write-Host ">>> 5. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Restore ensure_level_registered() in TectonicFaultlineHelper to fix level select freeze"
git push origin main

Write-Host "`nFix complete! Launch Coal LLC to test." -ForegroundColor Green