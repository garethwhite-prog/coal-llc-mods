cls

# ==============================================================================
# Coal LLC - Fix CryoPod Error, Nanobotz Profession Detection & Map Registration
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$modName    = "gareth-lost_expedition_mod"
$outerDir   = "$repo\mods-unpacked\$modName"
$innerDir   = "$outerDir\mods-unpacked\$modName"
$zipPath    = "$steamMods\$modName.zip"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Patching CryoPod.gd to fix employee property error & guarantee card emit..." -ForegroundColor Cyan
@'
class_name CryoPod
extends Area2D

var in_range: bool = false
var looted: bool = false
var sprite: Sprite2D
var tex_closed: Texture2D
var tex_opened: Texture2D

func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 1
	collision_mask = 1
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 20.0
	col.shape = shape
	add_child(col)
	
	var img_closed = Image.load_from_file("res://mods-unpacked/gareth-lost_expedition_mod/assets/cryo_pod.png")
	if img_closed:
		tex_closed = ImageTexture.create_from_image(img_closed)
	
	var img_opened = Image.load_from_file("res://mods-unpacked/gareth-lost_expedition_mod/assets/cryo_pod_opened.png")
	if img_opened:
		tex_opened = ImageTexture.create_from_image(img_opened)
	
	sprite = Sprite2D.new()
	sprite.texture = tex_closed
	add_child(sprite)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if in_range and not looted:
		if Input.is_action_just_pressed("interact"):
			rescue_worker()

func _on_body_entered(_body: Node2D) -> void:
	if not looted:
		in_range = true
		if Bus and Bus.has_signal("ShowInputIndicator"):
			Bus.ShowInputIndicator.emit("interact", true, self)

func _on_body_exited(_body: Node2D) -> void:
	in_range = false
	if Bus and Bus.has_signal("ShowInputIndicator"):
		Bus.ShowInputIndicator.emit("interact", false, self)

func rescue_worker() -> void:
	if looted:
		return
	looted = true
	in_range = false
	monitoring = false
	monitorable = false
	
	if Bus and Bus.has_signal("ShowInputIndicator"):
		Bus.ShowInputIndicator.emit("interact", false, self)
	
	# 1. Visual confirmation: evacuated hollow sprite
	if tex_opened:
		sprite.texture = tex_opened
	else:
		sprite.modulate = Color(0.35, 0.4, 0.45, 0.7)
	
	# 2. Audio feedback
	var sfx_stream = load("res://assets/sound/sound effects/coolDing.wav")
	if sfx_stream:
		var sfx = AudioStreamPlayer2D.new()
		sfx.stream = sfx_stream
		add_child(sfx)
		sfx.play()
	
	# 3. Employee workforce promotion and salvage cash
	var emp_mgr = Gvars.employee_manager
	var rescued_name: String = "Expedition Specialist"
	if emp_mgr and emp_mgr.ALL_EMPLOYEES.size() > 0:
		var chosen_emp = emp_mgr.ALL_EMPLOYEES[randi() % emp_mgr.ALL_EMPLOYEES.size()]
		emp_mgr.purchase_employee_level(chosen_emp, 1.0)
		if chosen_emp.get("level_name") != null:
			rescued_name = str(chosen_emp.level_name)
		elif chosen_emp.get("employee_name") != null:
			rescued_name = str(chosen_emp.employee_name)
	Gvars.CashCount += 10000.0
	
	ModLoaderLog.info("Cryo-Pod breached! Rescued " + rescued_name + " + Salvaged $10,000.", "gareth-lost_expedition_mod")
	
	# 4. Trigger 3-card passive selection directly via Bus signal
	var depth_mult: float = maxf(2.0, minf(6.0, 2.0 + abs(global_position.y) / 250.0))
	if Bus and Bus.has_signal("choose_passive"):
		Bus.choose_passive.emit(depth_mult)
'@ | Set-Content -Path "$innerDir\entities\CryoPod.gd" -Encoding UTF8
Write-Host "Updated: $innerDir\entities\CryoPod.gd" -ForegroundColor Green

Write-Host ">>> 2. Updating Game.hooks.gd to persist level registration & set Game.player..." -ForegroundColor Cyan
@'
extends Object

func change_stage(chain: ModLoaderHookChain, target: int, targetPosition: Vector2) -> void:
	var game = chain.reference_object
	var helper_script = load("res://mods-unpacked/gareth-lost_expedition_mod/helpers/LostExpeditionHelper.gd")
	if helper_script:
		var helper = helper_script.new()
		helper.ensure_level_registered()

	if target == 2 and Gvars.level == 101:
		if game and "MINE_REGION" in game:
			game.target_stage = game.MINE_REGION

	chain.execute_next([target, targetPosition])

	if game:
		if game.has_node("ColorRect"):
			game.get_node("ColorRect").mouse_filter = Control.MOUSE_FILTER_IGNORE
		game.visible = false
		# Supply player & profession reference so nanobotz reads Gvars.profession
		if Gvars.profession:
			if not ("player" in game) or game.player == null:
				var player_node = game.get_tree().get_first_node_in_group("player")
				if player_node:
					game.player = player_node
			if "player" in game and game.player:
				game.player.set("profession", Gvars.profession)
'@ | Set-Content -Path "$innerDir\extensions\scripts\Game.hooks.gd" -Encoding UTF8
Write-Host "Updated: $innerDir\extensions\scripts\Game.hooks.gd" -ForegroundColor Green

Write-Host ">>> 3. Ensuring mod_main.gd registers level 101 globally at startup..." -ForegroundColor Cyan
@'
extends Node

const MOD_DIR := "gareth-lost_expedition_mod"

func _init() -> void:
	ModLoaderLog.info("Lost Expedition Mod initializing...", MOD_DIR)
	var mod_dir_path: String = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/Menus/level_select.gd",
		mod_dir_path.path_join("extensions/scenes/Interfaces/Menus/level_select.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/tilemaps/tile_map_chunk.gd",
		mod_dir_path.path_join("extensions/scenes/tilemaps/tile_map_chunk.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/Game.gd",
		mod_dir_path.path_join("extensions/scripts/Game.hooks.gd")
	)

func _ready() -> void:
	var helper_script = load("res://mods-unpacked/gareth-lost_expedition_mod/helpers/LostExpeditionHelper.gd")
	if helper_script:
		var helper = helper_script.new()
		helper.ensure_level_registered()
	ModLoaderLog.info("Lost Expedition Custom Map Mod (ID 101) online!", MOD_DIR)
'@ | Set-Content -Path "$innerDir\mod_main.gd" -Encoding UTF8
Write-Host "Updated: $innerDir\mod_main.gd" -ForegroundColor Green

Write-Host ">>> 4. Flushing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 5. Repackaging mod archive for Steam..." -ForegroundColor Cyan
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
Write-Host "Packed clean archive at: $zipPath" -ForegroundColor Green

Write-Host ">>> 6. Git committing and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Fix CryoPod employee level property crash, persist level 101 in LevelManager, set Game.player profession"
git push origin main

Write-Host "`nAll patches deployed cleanly! Restart Coal LLC to test." -ForegroundColor Green