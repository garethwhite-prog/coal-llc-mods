$repoRoot = "C:\Dev\coal-llc-mods"
$steamMods = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mods"
$steamRoot = $steamMods
$downMods = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. Patching Amazon Delivery Lambda Memory Leak ---"
$amazonPath = "$repoRoot\mods-unpacked\gareth-scrap_and_delivery_mod\mods-unpacked\gareth-scrap_and_delivery_mod\scripts\amazon_delivery_manager.gd"
if (Test-Path $amazonPath) {
    $content = Get-Content $amazonPath -Raw
    $oldLambda = @"
		show_toast("📦 DELIVERED! [%s] safely received." % item.itemName)
		crate.queue_free()
"@
    $newLambda = @"
		show_toast("📦 DELIVERED! [%s] safely received." % item.itemName)
		if is_instance_valid(crate):
			crate.queue_free()
"@
    $content = $content.Replace("`r`n", "`n").Replace($oldLambda.Replace("`r`n", "`n"), $newLambda.Replace("`r`n", "`n"))
    $content | Set-Content -Path $amazonPath -Encoding UTF8
}

Write-Output "--- 2. Repairing Bouncing Ball Collision Physics ---"
$ballProjPath = "$repoRoot\mods-unpacked\gareth-bouncing_ball_mod\mods-unpacked\gareth-bouncing_ball_mod\scripts\bouncing_ball_projectile.gd"
if (Test-Path $ballProjPath) {
    $content = Get-Content $ballProjPath -Raw
    $oldReady = @"
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	var shape := CollisionShape2D.new()
	shape.shape = circle
	add_child(shape)
"@
    $newReady = @"
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	var shape := CollisionShape2D.new()
	shape.shape = circle
	
	# Explicitly set Godot 2D collision masks to interact with the TileMap
	collision_layer = 0
	collision_mask = 1 
	
	add_child(shape)
"@
    $content = $content.Replace("`r`n", "`n").Replace($oldReady.Replace("`r`n", "`n"), $newReady.Replace("`r`n", "`n"))
    $content | Set-Content -Path $ballProjPath -Encoding UTF8
}

Write-Output "--- 3. Activating Quadcopter Drones & Thomas the Tank Engine ---"
# Quadcopter Drone Workforce
$droneMinerPath = "$repoRoot\mods-unpacked\gareth-drone_workforce_mod\mods-unpacked\gareth-drone_workforce_mod\extensions\scenes\AutoMiners\employee_miner_2.hooks.gd"
$droneMiner = @"
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var miner = chain.reference_object
	if not is_instance_valid(miner): return

	var factory = load("res://mods-unpacked/gareth-drone_workforce_mod/scripts/drone_texture_factory.gd")
	if not factory: return

	for part in ["Head", "Torso", "Legs", "Tool"]:
		var node = miner.find_child(part, true, false)
		if is_instance_valid(node) and node is CanvasItem:
			node.visible = false

	var drone_spr = miner.get_node_or_null("MinerDroneSprite")
	if not drone_spr:
		drone_spr = Sprite2D.new()
		drone_spr.name = "MinerDroneSprite"
		drone_spr.texture = factory.create_miner_drone_texture()
		drone_spr.scale = Vector2(1.5, 1.5)
		miner.call_deferred("add_child", drone_spr)
"@
$droneMiner | Set-Content -Path $droneMinerPath -Encoding UTF8

$droneUfoPath = "$repoRoot\mods-unpacked\gareth-drone_workforce_mod\mods-unpacked\gareth-drone_workforce_mod\extensions\scripts\LootCollectorUFO.hooks.gd"
$droneUfo = @"
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var ufo = chain.reference_object
	if not is_instance_valid(ufo): return

	var factory = load("res://mods-unpacked/gareth-drone_workforce_mod/scripts/drone_texture_factory.gd")
	if not factory: return

	var models = ufo.find_child("Models", true, false)
	if is_instance_valid(models) and models is CanvasItem:
		models.visible = false

	var cargo_spr = ufo.get_node_or_null("CargoDroneSprite")
	if not cargo_spr:
		cargo_spr = Sprite2D.new()
		cargo_spr.name = "CargoDroneSprite"
		cargo_spr.texture = factory.create_cargo_drone_texture()
		cargo_spr.scale = Vector2(1.5, 1.5)
		ufo.call_deferred("add_child", cargo_spr)
"@
$droneUfo | Set-Content -Path $droneUfoPath -Encoding UTF8

# Thomas the Tank Engine
$thomasTrainPath = "$repoRoot\mods-unpacked\gareth-thomas_tank_engine_mod\mods-unpacked\gareth-thomas_tank_engine_mod\scripts\thomas_train_manager.gd"
$thomasTrain = @"
class_name ThomasTrainManager
extends Node2D

var left_stop: float = 64.0
var right_stop: float = 880.0
var speed: float = 140.0
var direction: float = 1.0

var loco_tier: int = 1
var wagon_count: int = 2
var wagon_capacity: float = 150.0
var current_haul: float = 0.0

var loco_sprite: Sprite2D
var wagons: Array[Sprite2D] = []

func _ready() -> void:
	z_index = 20
	position = Vector2(left_stop, 24.0)

	loco_sprite = Sprite2D.new()
	loco_sprite.scale = Vector2(1.8, 1.8)
	call_deferred("add_child", loco_sprite)
"@
$thomasTrain | Set-Content -Path $thomasTrainPath -Encoding UTF8

Write-Output "--- 4. Repacking All Mods ---"
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force }

$targetMods = @("gareth-scrap_and_delivery_mod", "gareth-bouncing_ball_mod", "gareth-drone_workforce_mod", "gareth-thomas_tank_engine_mod")
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
git commit -m "Fix: Add is_instance_valid safety check to Amazon lambda, inject physical collision_mask to Bouncing Ball, and activate Drone & Thomas mods via call_deferred."
git push origin main
Write-Output "Execution Completed!"