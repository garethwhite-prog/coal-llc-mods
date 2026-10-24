Clear-Host

# ==============================================================================
# Coal LLC - Knight Worker Passives, Camera Viewport Lock & Game Speed Mod
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

# ------------------------------------------------------------------------------
# 2. UPDATE KNIGHT PROFESSION: ADD WORKER MINER & COLLECTOR PASSIVES
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Adding employee passives to knight_profession.gd..." -ForegroundColor Cyan
$kpPath = "$repo\mods-unpacked\gareth-knight_class_mod\mods-unpacked\gareth-knight_class_mod\scripts\knight_profession.gd"

@'
class_name KnightProfession
extends Profession

func _profession_effect(data: Dictionary) -> Dictionary:
	if Gvars and ("passives" in Gvars) and Gvars.passives:
		for stat in ["sword_damage", "sword_speed", "sword_range"]:
			if not Gvars.passives.has_meta(stat):
				Gvars.passives.set_meta(stat, 0.0)
			Gvars.passives.set(stat, Gvars.passives.get_meta(stat))

	if data.has("inventory_starters"):
		var sword_res = load("res://mods-unpacked/gareth-knight_class_mod/items/KnightSword_01_shoddy.tres")
		if sword_res:
			data["inventory_starters"] = [{
				"item": sword_res,
				"count": 1
			}]

	if data.has("unlocked_passives"):
		data["unlocked_passives"] = [
			"sword_damage",
			"sword_speed",
			"sword_range",
			"employee_miner_speed",
			"employee_miner_damage",
			"employee_collector_speed",
			"employee_collector_capacity",
			"player_sprint_speed",
			"player_jump_velocity",
			"player_climb_speed"
		]

	return data
'@ | Set-Content -Path $kpPath -Encoding UTF8
Write-Host "  Updated: knight_profession.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. FIX CAMERA.HOOKS.GD: HARD-LOCK TO PLAYER & FREE UP BRACKET HOTKEYS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Updating Camera.hooks.gd for player tracking..." -ForegroundColor Cyan
$camHookPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scripts\Camera.hooks.gd"

@'
extends Object

func _process(chain: ModLoaderHookChain, delta: float) -> void:
	chain.execute_next([delta])
	var cam = chain.reference_object
	if not is_instance_valid(cam):
		return

	# Force camera following and re-acquire player if target was detached
	cam.free_move = false
	var target = null
	if ("TargetNode" in cam) and is_instance_valid(cam.TargetNode):
		target = cam.TargetNode
	else:
		var tree = cam.get_tree()
		if tree:
			var players = tree.get_nodes_in_group("player")
			if players.size() > 0 and is_instance_valid(players[0]):
				target = players[0]
				cam.TargetNode = target
			elif is_instance_valid(cam.get_node_or_null("../Player")):
				target = cam.get_node("../Player")
				cam.TargetNode = target

	if is_instance_valid(target):
		cam.global_position = target.global_position

	# Dedicated zoom controls (freed up [ and ] for game speed)
	if Gvars and ("settings" in Gvars) and Gvars.settings:
		var cur_zoom: float = Gvars.settings.zoom_level
		if Input.is_action_just_pressed("zoomOut") or Input.is_key_pressed(KEY_MINUS):
			Gvars.settings.zoom_level = clamp(cur_zoom - 0.2, 0.2, 4.0)
			cam.zoom = Vector2(Gvars.settings.zoom_level, Gvars.settings.zoom_level)
		elif Input.is_action_just_pressed("zoomIn") or Input.is_key_pressed(KEY_EQUAL):
			Gvars.settings.zoom_level = clamp(cur_zoom + 0.2, 0.2, 4.0)
			cam.zoom = Vector2(Gvars.settings.zoom_level, Gvars.settings.zoom_level)
		elif Input.is_key_pressed(KEY_0):
			Gvars.settings.zoom_level = 1.0
			cam.zoom = Vector2(1.0, 1.0)
'@ | Set-Content -Path $camHookPath -Encoding UTF8
Write-Host "  Updated: Camera.hooks.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. CREATE GARETH-GAME_SPEED_MOD (SPEED ARROWS + FORCE-END DAY)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Creating gareth-game_speed_mod..." -ForegroundColor Cyan
$gsRoot  = "$repo\mods-unpacked\gareth-game_speed_mod"
$gsInner = "$gsRoot\mods-unpacked\gareth-game_speed_mod"
$gsScripts = "$gsInner\scripts"
New-Item -ItemType Directory -Path $gsScripts -Force | Out-Null

$gsManifest = @"
{
  "name": "game_speed_mod",
  "namespace": "gareth",
  "version_number": "1.0.0",
  "description": "Adjust game simulation speed (0.5x, 0.75x, 1.0x, 1.5x, 2.0x) via on-screen HUD or hotkeys ([ / ]), plus emergency day finish (F8).",
  "website_url": "https://github.com/garethwhite-prog/coal-llc-mods",
  "dependencies": [],
  "extra": {
    "godot": {
      "display_name": "Game Speed & Shift Finisher",
      "category": "Quality of Life",
      "authors": ["Gareth White"],
      "compatible_mod_loader_version": ["7.0.1"],
      "compatible_game_version": ["1.4.1.1"]
    }
  }
}
"@
Set-Content -Path "$gsRoot\manifest.json" -Value $gsManifest -Encoding UTF8
Set-Content -Path "$gsInner\manifest.json" -Value $gsManifest -Encoding UTF8

# mod_main.gd
@'
extends Node

const MOD_DIR := "gareth-game_speed_mod"

func _ready() -> void:
	var controller_script = load("res://mods-unpacked/gareth-game_speed_mod/scripts/speed_controller.gd")
	var controller = Node.new()
	controller.name = "GameSpeedController"
	controller.set_script(controller_script)
	get_tree().root.call_deferred("add_child", controller)
	ModLoaderLog.info("Game Speed & Shift Finisher mod active!", MOD_DIR)
'@ | Set-Content -Path "$gsInner\mod_main.gd" -Encoding UTF8

# speed_controller.gd
@'
extends Node

const SPEEDS := [0.5, 0.75, 1.0, 1.5, 2.0]
var speed_index: int = 2

var canvas: CanvasLayer
var panel: PanelContainer
var lbl_speed: Label
var btn_slower: Button
var btn_faster: Button
var btn_end_day: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()

func _build_hud() -> void:
	canvas = CanvasLayer.new()
	canvas.name = "SpeedControlHUD"
	canvas.layer = 95
	add_child(canvas)

	panel = PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -260.0
	panel.offset_right = -16.0
	panel.offset_top = 16.0
	panel.offset_bottom = 54.0

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)

	btn_slower = Button.new()
	btn_slower.text = "◀"
	btn_slower.custom_minimum_size = Vector2(30, 28)
	btn_slower.tooltip_text = "Slower [ [ ]"
	btn_slower.pressed.connect(func(): _step_speed(-1))
	hbox.add_child(btn_slower)

	lbl_speed = Label.new()
	lbl_speed.text = "1.00x"
	lbl_speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_speed.custom_minimum_size = Vector2(52, 28)
	hbox.add_child(lbl_speed)

	btn_faster = Button.new()
	btn_faster.text = "▶"
	btn_faster.custom_minimum_size = Vector2(30, 28)
	btn_faster.tooltip_text = "Faster [ ] ]"
	btn_faster.pressed.connect(func(): _step_speed(1))
	hbox.add_child(btn_faster)

	var sep = VSeparator.new()
	hbox.add_child(sep)

	btn_end_day = Button.new()
	btn_end_day.text = "End Day"
	btn_end_day.custom_minimum_size = Vector2(74, 28)
	btn_end_day.modulate = Color(1.0, 0.45, 0.45, 1.0)
	btn_end_day.tooltip_text = "Finish Level / Emergency Exit [ F8 ]"
	btn_end_day.pressed.connect(Callable(self, "_finish_level"))
	hbox.add_child(btn_end_day)

	panel.add_child(hbox)
	canvas.add_child(panel)

func _process(_delta: float) -> void:
	# Show HUD only during mining shifts when a player node exists in tree
	var tree = get_tree()
	var in_game := false
	if tree:
		var p = tree.get_nodes_in_group("player")
		in_game = (p.size() > 0 and is_instance_valid(p[0]))

	if panel:
		panel.visible = in_game

	# Reset time_scale to 1.0 when returning to menus/management screens
	if not in_game and Engine.time_scale != 1.0:
		Engine.time_scale = 1.0
		speed_index = 2
		_update_label()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_BRACKETLEFT:
			_step_speed(-1)
		elif event.keycode == KEY_BRACKETRIGHT:
			_step_speed(1)
		elif event.keycode == KEY_F8:
			_finish_level()

func _step_speed(dir: int) -> void:
	speed_index = clampi(speed_index + dir, 0, SPEEDS.size() - 1)
	Engine.time_scale = SPEEDS[speed_index]
	_update_label()

func _update_label() -> void:
	if is_instance_valid(lbl_speed):
		lbl_speed.text = "%.2fx" % SPEEDS[speed_index]

func _finish_level() -> void:
	Engine.time_scale = 1.0
	speed_index = 2
	_update_label()

	if Game:
		if Game.has_method("on_EndDay"):
			Game.on_EndDay()
		elif Game.has_method("change_stage") and Gconsts and ("Stages" in Gconsts):
			Game.change_stage(Gconsts.Stages._END_OF_DAY_OVERLAY, Vector2.ZERO)
'@ | Set-Content -Path "$gsScripts\speed_controller.gd" -Encoding UTF8
Write-Host "  Created: gareth-game_speed_mod" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. REPACK AND DEPLOY MOD ARCHIVES
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Repackaging modified mods..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression.FileSystem

$modsToRepack = @(
	"gareth-knight_class_mod",
	"gareth-mod_manager_mod",
	"gareth-game_speed_mod"
)

foreach ($m in $modsToRepack) {
	$src = "$repo\mods-unpacked\$m"
	$zip = "$steamMods\$m.zip"
	if (Test-Path $zip) { Remove-Item -Path $zip -Force }

	$stream  = [System.IO.File]::Open($zip, [System.IO.FileMode]::CreateNew)
	$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
	foreach ($f in (Get-ChildItem -Path $src -Recurse -File)) {
		$entryName = $f.FullName.Substring($src.Length + 1).Replace("\", "/")
		[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
	}
	$archive.Dispose()
	$stream.Dispose()
	Write-Host "  Repacked: $m.zip" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 6. GIT STAGING, COMMIT & PUSH
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Add knight worker passives, fix camera player viewport lock, and implement game speed & shift finisher mod"
git push origin main

Write-Host "`nDeployment complete!" -ForegroundColor Green