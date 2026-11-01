$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. CRITICAL FIX: Reverting Global Coroutine Destruction ---"
Get-ChildItem -Path "$repoRoot\mods-unpacked" -Recurse -Filter "*.hooks.gd" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match "await chain\.execute_next") {
        $content = $content -replace "await chain\.execute_next", "chain.execute_next"
        $content | Set-Content -Path $_.FullName -Encoding UTF8
    }
}

$mapMods = @("gareth-diagonal_map_mod", "gareth-living_canvas_mod", "gareth-lost_expedition_mod", "gareth-abyssal_trench_mod", "gareth-tectonic_faultline_mod")
foreach ($mod in $mapMods) {
    $gameHook = "$repoRoot\mods-unpacked\$mod\mods-unpacked\$mod\extensions\scripts\Game.hooks.gd"
    if (Test-Path $gameHook) {
        $content = Get-Content $gameHook -Raw
        $content = $content -replace "chain\.execute_next", "await chain.execute_next"
        $content | Set-Content -Path $gameHook -Encoding UTF8
    }
}

Write-Output "--- 2. CRITICAL FIX: Restoring Mod Manager UI ---"
$mgrViewPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_manager_view.gd"
if (Test-Path $mgrViewPath) {
    # Restore the file to the commit BEFORE the _ready() body was accidentally deleted
    git checkout 807de20 -- "$mgrViewPath"
    
    $mvContent = Get-Content $mgrViewPath -Raw
    $mvContent = $mvContent -replace 'func _ready\(\) -> void:', "func _ready() -> void:`n`tcall_deferred(`"_inject_search_bar`")"
    
    $searchAndTag = @"

func _inject_search_bar() -> void:
	var header = find_child("HeaderContainer", true, false)
	if not header: header = self
	var search = LineEdit.new()
	search.placeholder_text = "Search installed mods..."
	search.custom_minimum_size = Vector2(300, 35)
	search.text_changed.connect(_on_search_filter)
	header.add_child(search)

func _on_search_filter(query: String) -> void:
	var q = query.to_lower()
	var list = find_child("ModListContainer", true, false)
	if is_instance_valid(list):
		for card in list.get_children():
			if q.is_empty():
				card.visible = true
			else:
				var mod_name = card.name.to_lower()
				var lbl = card.find_child("*Label*", true, false)
				if is_instance_valid(lbl): mod_name += lbl.text.to_lower()
				card.visible = q in mod_name
"@
    $mvContent = $mvContent + $searchAndTag
    
    $authorLogic = @"
	if manifest and manifest.get("extra") and manifest.extra.get("godot") and manifest.extra.godot.get("authors"):
		var authors = manifest.extra.godot.authors
		if authors.size() > 0 and typeof(authors[0]) == TYPE_STRING and "Gareth White" in authors[0]:
			return "Gareth White (Official Suite)"
	return "Community Add-Ons"
"@
    $mvContent = $mvContent -replace 'return "Community Add-Ons"', $authorLogic
    $mvContent | Set-Content -Path $mgrViewPath -Encoding UTF8
}

Write-Output "--- 3. FIXING MOD STORE JSON CATALOG ---"
$catalogPath = Join-Path $repoRoot "mod_catalog.json"
$mods = Get-ChildItem -Path "$repoRoot\mods-unpacked" -Directory
$githubReleases = @()
foreach ($mod in $mods) {
    $manifestPath = Join-Path $mod.FullName "manifest.json"
    if (Test-Path $manifestPath) {
        $json = Get-Content $manifestPath | ConvertFrom-Json
        $release = [PSCustomObject]@{
            tag_name = "v$($json.version_number)"
            name = $json.extra.godot.display_name
            body = $json.description
            assets = @(
                [PSCustomObject]@{
                    name = "$($json.name).zip"
                    browser_download_url = "https://raw.githubusercontent.com/garethwhite-prog/coal-llc-mods/main/downloaded_mods/$($json.name).zip"
                }
            )
        }
        $githubReleases += $release
    }
}
$githubReleases | ConvertTo-Json -Depth 10 | Set-Content -Path $catalogPath -Encoding UTF8

Write-Output "--- 4. US-01: Thomas the Tank Engine Graphical Logic ---"
$thomasTrainPath = "$repoRoot\mods-unpacked\gareth-thomas_tank_engine_mod\mods-unpacked\gareth-thomas_tank_engine_mod\scripts\thomas_train_manager.gd"
if (Test-Path $thomasTrainPath) {
    $thomasLogic = @"
class_name ThomasTrainManager
extends Node2D

var left_stop: float = 64.0
var right_stop: float = 880.0
var speed: float = 140.0
var direction: float = 1.0

@export var loco_tier: int = 1
@export var wagon_count: int = 2
@export var wagon_capacity: float = 150.0

var current_haul: float = 0.0
var loco_sprite: Sprite2D
var wagons: Array[Sprite2D] = []

func _ready() -> void:
	z_index = 20
	position = Vector2(left_stop, 24.0)

	loco_sprite = Sprite2D.new()
	loco_sprite.texture = _generate_loco_texture(loco_tier)
	loco_sprite.scale = Vector2(1.8, 1.8)
	call_deferred("add_child", loco_sprite)
	
	for i in range(wagon_count):
		var wag = Sprite2D.new()
		wag.texture = _generate_wagon_texture()
		wag.scale = Vector2(1.8, 1.8)
		wag.position = Vector2(-40.0 - (i * 36.0), 0.0)
		wagons.append(wag)
		call_deferred("add_child", wag)

func _physics_process(delta: float) -> void:
	# Locomotive Upgrade logic: Speed scales with tier (140 -> 260)
	var current_speed = speed + (loco_tier * 40.0)
	position.x += current_speed * direction * delta
	
	if position.x >= right_stop:
		direction = -1.0
		loco_sprite.flip_h = true
	elif position.x <= left_stop:
		direction = 1.0
		loco_sprite.flip_h = false
		_unload_haul()
		
func _unload_haul() -> void:
	if current_haul > 0.0:
		if Gvars and ("cash" in Gvars):
			Gvars.cash += current_haul
		current_haul = 0.0

func _generate_loco_texture(tier: int) -> ImageTexture:
	var img = Image.create(32, 16, false, Image.FORMAT_RGBA8)
	var color = Color.CORNFLOWER_BLUE # Thomas
	if tier == 2: color = Color.STEEL_BLUE # Edward
	elif tier == 3: color = Color.FOREST_GREEN # Henry
	elif tier >= 4: color = Color.ROYAL_BLUE # Gordon
	img.fill(color)
	return ImageTexture.create_from_image(img)

func _generate_wagon_texture() -> ImageTexture:
	var img = Image.create(24, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color.SADDLE_BROWN)
	return ImageTexture.create_from_image(img)
"@
    $thomasLogic | Set-Content -Path $thomasTrainPath -Encoding UTF8
}
    
Write-Output "--- 5. Repacking ALL MODS to Clear Cache ---"
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$allMods = Get-ChildItem -Path "$repoRoot\mods-unpacked" -Directory
foreach ($mod in $allMods) {
    $downZip = Join-Path $downMods "$($mod.Name).zip"
    $steamZip = Join-Path $steamMods "$($mod.Name).zip"
    if (Test-Path $downZip) { Remove-Item $downZip -Force }
    $archive = [System.IO.Compression.ZipFile]::Open($downZip, [System.IO.Compression.ZipArchiveMode]::Create)
    $files = Get-ChildItem -Path $mod.FullName -Recurse -File
    foreach ($file in $files) {
        $entryName = $file.FullName.Substring($mod.FullName.Length + 1).Replace("\", "/")
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $entryName)
    }
    $archive.Dispose()
    if (Test-Path $steamZip) { Copy-Item -Path $downZip -Destination $steamZip -Force }
}

Write-Output "--- Committing to Git ---"
git add -A
git commit -m "Fix: Revert global await coroutine destruction, restore Mod Manager UI lists, compile Thomas graphic logic, and repack entire mod ecosystem."
git push origin main
Write-Output "Sprint Executed Successfully!"