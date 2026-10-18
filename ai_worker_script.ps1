Clear-Host;

# ==============================================================================
# Coal LLC - Fix Map 103 Stage Transition & Gvars Null Crash
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

$modName    = "gareth-living_canvas_mod"
$outerDir   = "$repo\mods-unpacked\$modName"
$innerDir   = "$outerDir\mods-unpacked\$modName"

Set-Location $repo

Write-Host ">>> 1. Creating extensions/scripts/Game.hooks.gd..." -ForegroundColor Cyan
$gameHooksDir = "$innerDir\extensions\scripts"
if (-not (Test-Path $gameHooksDir)) {
    New-Item -ItemType Directory -Path $gameHooksDir -Force | Out-Null
}

@'
extends Object

func change_stage(chain: ModLoaderHookChain, target: int, targetPosition: Vector2) -> void:
	var game = chain.reference_object
	if target == 2 and Gvars and ("level" in Gvars) and Gvars.level == 103:
		# Map 103: The Living Canvas - Route to MineRegion stage
		var mine_scene = load("res://scenes/Stages/MineRegion.tscn")
		if mine_scene and game:
			game.target_stage = mine_scene

	chain.execute_next([target, targetPosition])
'@ | Set-Content -Path "$gameHooksDir\Game.hooks.gd" -Encoding UTF8

Write-Host ">>> 2. Updating mod_main.gd to register Game.gd hook..." -ForegroundColor Cyan
@'
extends Node

const MOD_ID := "gareth-living_canvas_mod"
const LOG_NAME := "gareth-living_canvas_mod"

func _init() -> void:
	ModLoaderLog.info("The Living Canvas Mod initializing...", LOG_NAME)
	install_hooks()

func _ready() -> void:
	var helper_script = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
	if helper_script and helper_script.has_method("ensure_level_registered"):
		helper_script.ensure_level_registered()
	ModLoaderLog.info("The Living Canvas Custom Map (ID 103) online!", LOG_NAME)

func install_hooks() -> void:
	var unpacked_dir = ModLoaderMod.get_unpacked_dir().path_join(MOD_ID)
	var ext_dir = unpacked_dir.path_join("extensions")

	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/Menus/level_select.gd",
		ext_dir.path_join("scenes/Interfaces/Menus/level_select.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/tilemaps/tile_map_chunk.gd",
		ext_dir.path_join("scenes/tilemaps/tile_map_chunk.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/Game.gd",
		ext_dir.path_join("scripts/Game.hooks.gd")
	)
'@ | Set-Content -Path "$innerDir\mod_main.gd" -Encoding UTF8

Write-Host ">>> 3. Patching mod manager or Gvars hook to safeguard reset_resources..." -ForegroundColor Cyan
# Add a safe wrapper in gareth-mod_manager_mod if present, or hook Gvars.gd
$mmGvarsHook = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scripts\Gvars.hooks.gd"
if (-not (Test-Path (Split-Path $mmGvarsHook))) {
    New-Item -ItemType Directory -Path (Split-Path $mmGvarsHook) -Force | Out-Null
}

@'
extends Object

func reset_resources(chain: ModLoaderHookChain) -> void:
	# Clean any null or unpathed items from resources_to_save before running reset
	if Gvars and ("resources_to_save" in Gvars) and Gvars.resources_to_save:
		var cleaned: Array = []
		for res in Gvars.resources_to_save:
			if res != null and ("resource_path" in res) and str(res.resource_path) != "":
				cleaned.append(res)
		Gvars.resources_to_save = cleaned

	chain.execute_next([])
'@ | Set-Content -Path $mmGvarsHook -Encoding UTF8

# Ensure gareth-mod_manager_mod registers the Gvars.gd hook
$mmMainPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\mod_main.gd"
if (Test-Path $mmMainPath) {
    $mmMain = Get-Content $mmMainPath -Raw
    if ($mmMain -notmatch "Gvars\.hooks\.gd") {
        $hookBlock = @'
	ModLoaderMod.install_script_hooks(
		"res://scripts/Gvars.gd",
		ext_dir.path_join("scripts/Gvars.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/MainMenu.gd"
'@
        $mmMain = $mmMain -replace 'ModLoaderMod\.install_script_hooks\(\s*"res://scripts/MainMenu\.gd"', $hookBlock
        Set-Content -Path $mmMainPath -Value $mmMain -Encoding UTF8
    }
}

Write-Host "`n>>> 4. Flushing mod-hooks.zip to trigger re-injection..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 5. Repackaging living_canvas_mod.zip and mod_manager_mod.zip..." -ForegroundColor Cyan
foreach ($mTarget in @("gareth-living_canvas_mod", "gareth-mod_manager_mod")) {
    $mOuter = "$repo\mods-unpacked\$mTarget"
    $mZip   = "$steamMods\$mTarget.zip"
    if (Test-Path $mZip) { 
        Remove-Item -Path $mZip -Force 
    }

    $stream  = [System.IO.File]::Open($mZip, [System.IO.FileMode]::CreateNew)
    $archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
    
    foreach ($f in (Get-ChildItem -Path $mOuter -Recurse -File)) {$entryName = $f.FullName.Substring($mOuter.Length + 1).Replace("\", "/")
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
    }
    
    $archive.Dispose()
	$stream.Dispose()
    Write-Host "Repacked: $mZip" -ForegroundColor Green
}

Write-Host "`n>>> 6. Git staging and committing..." -ForegroundColor Cyan
git add -A
git commit -m "Fix Map 103 stage transition into MineRegion and guard Gvars reset_resources null crash"
git push origin main

Write-Host "`nFix deployed successfully! Launch Coal LLC to test." -ForegroundColor Green