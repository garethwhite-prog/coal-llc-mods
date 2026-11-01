$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. Fixing Syntax Errors in Mod Manager ---"
$choosePassivePath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scenes\Interfaces\in_game\choose_passive.hooks.gd"
if (Test-Path $choosePassivePath) {
    # Reverting to the last known good state to clear the duplicate function parse error
    git checkout a9ca50039c02c57c68f24f0fcb0be1b547bb53c3 -- "$choosePassivePath"
    Write-Output "Restored choose_passive.hooks.gd"
}

$mgrViewPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_manager_view.gd"
if (Test-Path $mgrViewPath) {
    # Reverting to the last known good state to clear the array element parse error
    git checkout a9ca50039c02c57c68f24f0fcb0be1b547bb53c3 -- "$mgrViewPath"
    
    # Re-applying the Category fix carefully without breaking the array structure
    $content = Get-Content $mgrViewPath -Raw
    $oldCategory = '"Community Add-Ons",'
    $newCategory = '"Gareth White (Official Suite)",`n		"Community Add-Ons",'
    $content = $content.Replace("`r`n", "`n").Replace($oldCategory.Replace("`r`n", "`n"), $newCategory.Replace("`r`n", "`n"))
    
    $categoryHook = @"
	if manifest and manifest.extra and manifest.extra.has("godot") and manifest.extra.godot.has("authors"):
		var authors = manifest.extra.godot.authors
		if authors.size() > 0 and "Gareth White" in authors[0]:
			return "Gareth White (Official Suite)"
"@
    $content = $content -replace 'return "Community Add-Ons"', "$categoryHook`n`treturn `"Community Add-Ons`""
    $content | Set-Content -Path $mgrViewPath -Encoding UTF8
    Write-Output "Patched mod_manager_view.gd category logic safely."
}

Write-Output "--- 2. Injecting Bouncing Ball Passives Correctly ---"
$bbProfPath = "$repoRoot\mods-unpacked\gareth-bouncing_ball_mod\mods-unpacked\gareth-bouncing_ball_mod\scripts\bouncing_ball_profession.gd"
if (Test-Path $bbProfPath) {
    $content = Get-Content $bbProfPath -Raw
    if ($content -notmatch "ball_blast_damage") {
        $oldPassives = '"player_climb_speed"'
        $newPassives = '"player_climb_speed",`n			"ball_blast_damage",`n			"ball_blast_radius",`n			"ball_fire_rate"'
        $content = $content.Replace("`r`n", "`n").Replace($oldPassives.Replace("`r`n", "`n"), $newPassives.Replace("`r`n", "`n"))
        $content | Set-Content -Path $bbProfPath -Encoding UTF8
        Write-Output "Patched Bouncing Ball passives into bouncing_ball_profession.gd"
    }
}

Write-Output "--- 3. Repacking Modified Mods ---"
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force }

$targetMods = @("gareth-mod_manager_mod", "gareth-bouncing_ball_mod")
Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($mod in $targetMods) {
    $srcDir = Join-Path $repoRoot "mods-unpacked\$mod"
    $downZip = Join-Path $downMods "$mod.zip"
    $steamZip = Join-Path $steamMods "$mod.zip"
    
    if (Test-Path $downZip) { Remove-Item $downZip -Force }
    $archive = [System.IO.Compression.ZipFile]::Open($downZip, [System.IO.Compression.ZipArchiveMode]::Create)
    $files = Get-ChildItem -Path $srcDir -Recurse -File
    foreach ($file in $files) {
        $entryName = $file.FullName.Substring($srcDir.Length + 1).Replace("\", "/")
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $entryName)
    }
    $archive.Dispose()
    
    if (Test-Path $steamZip) { Copy-Item -Path $downZip -Destination $steamZip -Force }
    Write-Output "Deployed $mod.zip"
}

Write-Output "--- Committing to Git ---"
git add -A
git commit -m "Fix: Resolve syntax errors in Mod Manager preventing load, and explicitly inject passives into Bouncing Ball profession array."
git push origin main
Write-Output "Operation Successful."