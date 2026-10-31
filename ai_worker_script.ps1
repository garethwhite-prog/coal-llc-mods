$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. Overriding Amazon Delivery Lambda (Hard Replacement) ---"
$amazonPath = "$repoRoot\mods-unpacked\gareth-scrap_and_delivery_mod\mods-unpacked\gareth-scrap_and_delivery_mod\scripts\amazon_delivery_manager.gd"
$amazonContent = Get-Content $amazonPath -Raw
$amazonTarget = @"
		if item.itemBuyEffect:
			item.itemBuyEffect.buy_effect(item, 1)
		else:
			var inv: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
			if inv:
				inv.addToInventory(item, 1)
		Bus.inventory_changed.emit()
		show_toast("📦 DELIVERED! [%s] safely received." % item.itemName)
		crate.queue_free()
	)
"@
$amazonFix = @"
		if item.itemBuyEffect:
			item.itemBuyEffect.buy_effect(item, 1)
		else:
			var inv: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
			if inv:
				inv.addToInventory(item, 1)
		Bus.inventory_changed.emit()
		show_toast("📦 DELIVERED! [%s] safely received." % item.itemName)
		if is_instance_valid(crate):
			crate.queue_free()
	)
"@
$amazonContent = $amazonContent.Replace("`r`n", "`n").Replace($amazonTarget.Replace("`r`n", "`n"), $amazonFix.Replace("`r`n", "`n"))
$amazonContent | Set-Content -Path $amazonPath -Encoding UTF8

Write-Output "--- 2. Securing Henry Hoover Texture Mount (call_deferred) ---"
$vacHookPath = "$repoRoot\mods-unpacked\gareth-henry_the_hoover_mod\mods-unpacked\gareth-henry_the_hoover_mod\extensions\scenes\equipment\vacuum_cleaner.hooks.gd"
$vacHookScript = @"
extends Object

func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	var vac = chain.reference_object
	if is_instance_valid(vac):
		if not vac.has_meta("henry_initialized"):
			vac.set_meta("henry_initialized", true)
			vac.set_meta("gobble_cooldown", 0.0)
			
			var lvl: int = 1
			if Gvars and ("bonus_equipment_manager" in Gvars) and Gvars.bonus_equipment_manager:
				if "vacuum_level" in Gvars.bonus_equipment_manager:
					lvl = int(Gvars.bonus_equipment_manager.vacuum_level)
					
			var sprite = vac.get_node_or_null("Sprite2D")
			if is_instance_valid(sprite):
				var factory = load("res://mods-unpacked/gareth-henry_the_hoover_mod/helpers/henry_texture_factory.gd")
				if factory and factory.has_method("apply_henry_skin"):
					# Apply the high-fidelity Numatic pixel art deferred to prevent tree locks
					factory.call_deferred("apply_henry_skin", sprite, lvl)

		var cd = float(vac.get_meta("gobble_cooldown", 0.0))
		if cd > 0.0:
			vac.set_meta("gobble_cooldown", cd - delta)
			
		var audio = vac.get_node_or_null("AudioStreamPlayer2D")
		if is_instance_valid(audio) and audio.playing:
			if cd > 0.0:
				audio.volume_db = -80.0
			else:
				audio.volume_db = 0.0
				vac.set_meta("gobble_cooldown", 1.0)

	chain.execute_next([delta])
"@
$vacHookScript | Set-Content -Path $vacHookPath -Encoding UTF8

Write-Output "--- 3. Exposing Thomas the Tank Upgrades (US-01) ---"
$thomasTrainPath = "$repoRoot\mods-unpacked\gareth-thomas_tank_engine_mod\mods-unpacked\gareth-thomas_tank_engine_mod\scripts\thomas_train_manager.gd"
$thomasContent = Get-Content $thomasTrainPath -Raw
$thomasFix = @"
class_name ThomasTrainManager
extends Node2D

var left_stop: float = 64.0
var right_stop: float = 880.0
var speed: float = 140.0
var direction: float = 1.0

# Shop Exposed Configuration Variables
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
	loco_sprite.scale = Vector2(1.8, 1.8)
	call_deferred("add_child", loco_sprite)
"@
$thomasFix | Set-Content -Path $thomasTrainPath -Encoding UTF8

Write-Output "--- 4. Repacking Target Mods ---"
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force }

$targetMods = @("gareth-scrap_and_delivery_mod", "gareth-henry_the_hoover_mod", "gareth-thomas_tank_engine_mod")
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
git commit -m "Fix: Explicit override for Amazon lambda crash, call_deferred on Henry visuals, and expose Thomas exports to Inspector/Shop."
git push origin main
Write-Output "Operation Successful."