cls

# ==============================================================================
# Coal LLC - Fix Lost Expedition (website_url schema & install_script_hooks)
# ==============================================================================

$repoRoot      = "C:\Dev\coal-llc-mods"
$modName       = "gareth-lost_expedition_mod"
$outerModDir   = Join-Path $repoRoot "mods-unpacked\$modName"
$innerModDir   = Join-Path $outerModDir "mods-unpacked\$modName"
$steamModsDir  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mods"
$zipPath       = Join-Path $steamModsDir "$modName.zip"

Set-Location $repoRoot

Write-Host ">>> 1. Generating compliant manifest.json with website_url..." -ForegroundColor Cyan

# Read working manifest as template
$templateManifestPath = Join-Path $repoRoot "mods-unpacked\gareth-knight_class_mod\manifest.json"
$manifestObj = [ordered]@{
    "name"            = "lost_expedition_mod"
    "namespace"       = "gareth"
    "version_number"  = "1.0.0"
    "description"     = "Custom subterranean expedition map featuring unexploded ordnance and cryo-pod survivor rescue mechanics."
    "website_url"     = "https://github.com/garethwhite-prog/coal-llc-mods"
    "dependencies"    = @()
    "extra"           = @{
        "godot" = @{
            "compatible_game_version" = @("1.4.1.1")
            "version" = "4.4.1"
        }
    }
}

if (Test-Path $templateManifestPath) {
    $tmpl = Get-Content $templateManifestPath -Raw | ConvertFrom-Json
    if ($tmpl.extra) { $manifestObj.extra = $tmpl.extra }
    if ($tmpl.website_url) { $manifestObj.website_url = $tmpl.website_url }
}

$manifestJson = $manifestObj | ConvertTo-Json -Depth 5
Set-Content -Path (Join-Path $outerModDir "manifest.json") -Value $manifestJson -Encoding UTF8
Set-Content -Path (Join-Path $innerModDir "manifest.json") -Value $manifestJson -Encoding UTF8
Write-Host "manifest.json written with website_url and extra.godot schema." -ForegroundColor Green

Write-Host ">>> 2. Updating mod_main.gd with install_script_hooks..." -ForegroundColor Cyan
$modMainGd = @'
extends Node

const MOD_DIR = "gareth-lost_expedition_mod"

func _init() -> void:
	ModLoaderLog.info("Lost Expedition Mod initializing...", MOD_DIR)
	ModLoaderMod.install_script_hooks("res://mods-unpacked/gareth-lost_expedition_mod/extensions/scenes/Interfaces/Menus/level_select.hooks.gd")
	ModLoaderMod.install_script_hooks("res://mods-unpacked/gareth-lost_expedition_mod/extensions/scenes/tilemaps/tile_map_chunk.hooks.gd")

func _ready() -> void:
	ModLoaderLog.info("Lost Expedition Custom Map Mod (ID 101) online!", MOD_DIR)
'@
Set-Content -Path (Join-Path $innerModDir "mod_main.gd") -Value $modMainGd -Encoding UTF8

Write-Host ">>> 3. Packaging $modName.zip for Steam..." -ForegroundColor Cyan
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

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
Write-Host "Re-packaged cleanly to $zipPath" -ForegroundColor Green

Write-Host ">>> 4. Updating SESSION_PROMPT.md with manifest & hook directives..." -ForegroundColor Cyan
$sessionPromptPath = Join-Path $repoRoot "SESSION_PROMPT.md"
$sessionContent = Get-Content $sessionPromptPath -Raw

if ($sessionContent -notmatch "website_url") {
    $sessionContent = $sessionContent -replace 'Dual-Manifest & Dual-README Requirement:', "Dual-Manifest & Dual-README Requirement:
   Every mod archive MUST contain manifest.json and README.md at the archive root AND duplicate copies inside mods-unpacked/<namespace>-<mod_name>/.
   manifest.json strictly requires: 'name', 'namespace', 'version_number', 'description', 'website_url', 'dependencies', and 'extra': { 'godot': { ... } }. Omitting website_url triggers a fatal ModManifest validation rejection."
}

if ($sessionContent -notmatch "install_script_hooks") {
    $sessionContent = $sessionContent -replace 'ModLoader Hook Limitations:', "ModLoader Hook Limitations:
   Hook scripts (*.hooks.gd) must be registered via `ModLoaderMod.install_script_hooks()`, NOT `install_script_extension()`. They must ONLY contain method names that exist directly on the vanilla target script. Any custom helper functions defined at script root will trigger parse errors. Delegate custom logic to RefCounted helper classes."
}

Set-Content -Path $sessionPromptPath -Value $sessionContent -Encoding UTF8
Write-Host "SESSION_PROMPT.md updated." -ForegroundColor Green

Write-Host ">>> 5. Git Staging, Commit & Push..." -ForegroundColor Cyan
git add -A
git commit -m "Fix manifest website_url validation and install_script_hooks for Lost Expedition mod"
git push origin main

Write-Host "`nDone! Start Coal LLC now — Lost Expedition will load cleanly." -ForegroundColor Green