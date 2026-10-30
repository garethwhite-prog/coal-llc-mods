$repoRoot = "C:\Dev\coal-llc-mods"
$steamMods = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mods"
$downMods = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- Patching Henry the Hoover Texture Factory ---"
$factoryPath = "mods-unpacked\gareth-henry_the_hoover_mod\mods-unpacked\gareth-henry_the_hoover_mod\helpers\henry_texture_factory.gd"
$factoryScript = @"
class_name HenryTextureFactory
extends RefCounted

static func apply_henry_skin(sprite: Sprite2D, tier: int) -> void:
	if not sprite:
		return
		
	var path := ""
	match tier:
		1: path = "res://mods-unpacked/gareth-henry_the_hoover_mod/assets/henry_red.png"
		2: path = "res://mods-unpacked/gareth-henry_the_hoover_mod/assets/hetty_pink.png"
		3: path = "res://mods-unpacked/gareth-henry_the_hoover_mod/assets/harry_blue.png"
		4: path = "res://mods-unpacked/gareth-henry_the_hoover_mod/assets/george_green.png"
		5: path = "res://mods-unpacked/gareth-henry_the_hoover_mod/assets/charles_yellow.png"
		_: path = "res://mods-unpacked/gareth-henry_the_hoover_mod/assets/henry_red.png"

	if FileAccess.file_exists(path):
		var bytes = FileAccess.get_file_as_bytes(path)
		if bytes and bytes.size() > 0:
			var img = Image.new()
			if img.load_png_from_buffer(bytes) == OK:
				sprite.texture = ImageTexture.create_from_image(img)
				sprite.offset = Vector2(0, -8)
"@
$factoryScript | Set-Content -Path $factoryPath -Encoding UTF8

Write-Output "--- Patching Vacuum Cleaner Hooks (Rate Limit & Skin) ---"
$vacHookPath = "mods-unpacked\gareth-henry_the_hoover_mod\mods-unpacked\gareth-henry_the_hoover_mod\extensions\scenes\equipment\vacuum_cleaner.hooks.gd"
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
			if sprite:
				var factory = load("res://mods-unpacked/gareth-henry_the_hoover_mod/helpers/henry_texture_factory.gd")
				if factory and factory.has_method("apply_henry_skin"):
					factory.apply_henry_skin(sprite, lvl)

		var cd = float(vac.get_meta("gobble_cooldown", 0.0))
		if cd > 0.0:
			vac.set_meta("gobble_cooldown", cd - delta)

	chain.execute_next([delta])

func play_suck_effect(chain: ModLoaderHookChain) -> void:
	var vac = chain.reference_object
	if is_instance_valid(vac):
		var cd = float(vac.get_meta("gobble_cooldown", 0.0))
		if cd <= 0.0:
			vac.set_meta("gobble_cooldown", 1.0)
			chain.execute_next([])
		else:
			return
	else:
		chain.execute_next([])
"@
$vacHookScript | Set-Content -Path $vacHookPath -Encoding UTF8

Write-Output "--- Repacking and Deploying Henry Mod ---"
$hooksZip = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force }

$mod = "gareth-henry_the_hoover_mod"
$srcDir = Join-Path $repoRoot "mods-unpacked\$mod"
$downZip = Join-Path $downMods "$mod.zip"
$steamZip = Join-Path $steamMods "$mod.zip"

if (Test-Path $downZip) { Remove-Item $downZip -Force }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::Open($downZip, [System.IO.Compression.ZipArchiveMode]::Create)
$files = Get-ChildItem -Path $srcDir -Recurse -File
foreach ($file in $files) {
    $entryName = $file.FullName.Substring($srcDir.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $entryName)
}
$archive.Dispose()

if (Test-Path $steamZip) {
    Copy-Item -Path $downZip -Destination $steamZip -Force
}

Write-Output "--- Committing to Git ---"
git add -A
git commit -m "Feature: Implement Henry vacuum dynamic skins and rate-limit gobble sound effects."
git push origin main