cls
# ==============================================================================
# Coal LLC - Cryo-Pod Interaction Trigger & Physical Worker Spawner
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

Write-Host ">>> 1. Patching CryoPod.gd (32px radius, Player2 match, physical spawn)..." -ForegroundColor Cyan
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
	shape.radius = 32.0
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

func _is_player(node: Node) -> bool:
	if not node:
		return false
	if node.is_in_group("player") or node.is_in_group("Player"):
		return true
	var nm: String = node.name.to_lower()
	if nm.contains("player"):
		return true
	if node is CharacterBody2D and not nm.contains("miner"):
		return true
	return false

func _process(_delta: float) -> void:
	if in_range and not looted:
		if Input.is_action_just_pressed("interact"):
			rescue_worker()

func _on_body_entered(body: Node2D) -> void:
	if not _is_player(body):
		return
	ModLoaderLog.info("Player entered Cryo-Pod zone: " + body.name, "gareth-lost_expedition_mod")
	if not looted:
		in_range = true
		if Bus and Bus.has_signal("ShowInputIndicator"):
			Bus.ShowInputIndicator.emit("interact", true, self)

func _on_body_exited(body: Node2D) -> void:
	if not _is_player(body):
		return
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
	
	# 1. Swap visual to evacuated state
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
	
	# 3. Upgrade employee ledger
	var emp_mgr = Gvars.employee_manager
	var rescued_title: String = "Expedition Specialist"
	var chosen_emp = null
	if emp_mgr and emp_mgr.ALL_EMPLOYEES.size() > 0:
		chosen_emp = emp_mgr.ALL_EMPLOYEES[randi() % emp_mgr.ALL_EMPLOYEES.size()]
		emp_mgr.purchase_employee_level(chosen_emp, 1.0)
		if chosen_emp.get("level_name") != null:
			rescued_title = str(chosen_emp.level_name)
		elif chosen_emp.get("employee_name") != null:
			rescued_title = str(chosen_emp.employee_name)
	
	# 4. Physically instantiate live worker directly inside MineRegion
	if chosen_emp:
		var mine_region = get_tree().root.find_child("MineRegion", true, false)
		var worker_instance = null
		if chosen_emp.type == EmployeeLevel.EmployeeType.COLLECTOR:
			var ufo_scene = load("res://scenes/LootCollectorUFO.tscn")
			if ufo_scene:
				worker_instance = ufo_scene.instantiate()
				worker_instance.employee_level = chosen_emp
				worker_instance.count = 1.0
				worker_instance.global_position = global_position
		else:
			var miner_scene = load("res://scenes/AutoMiners/multi_miner.tscn")
			if miner_scene:
				worker_instance = miner_scene.instantiate()
				worker_instance.employee_level = chosen_emp
				worker_instance.count = 1.0
				var tm = get_tree().root.find_child("TileMapManager", true, false)
				if tm:
					worker_instance.tilemap = tm
				worker_instance.global_position = global_position
		
		if worker_instance:
			if mine_region:
				mine_region.add_child(worker_instance)
			else:
				get_parent().add_child(worker_instance)
	
	Gvars.CashCount += 10000.0
	ModLoaderLog.info("Cryo-Pod breached! Rescued " + rescued_title + " now working beside you! Salvaged $10,000.", "gareth-lost_expedition_mod")
	
	# 5. Trigger passive card selection (handled by choose_passive UI & auto-chooser)
	var depth_mult: float = maxf(2.0, minf(6.0, 2.0 + abs(global_position.y) / 250.0))
	if Bus and Bus.has_signal("choose_passive"):
		Bus.choose_passive.emit(depth_mult)
'@ | Set-Content -Path "$innerDir\entities\CryoPod.gd" -Encoding UTF8
Write-Host "Updated: $innerDir\entities\CryoPod.gd" -ForegroundColor Green

Write-Host ">>> 2. Flushing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 3. Repackaging mod archive for Steam..." -ForegroundColor Cyan
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

Write-Host ">>> 4. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Expand CryoPod collision to 32px, accept Player2 character body, spawn physical worker in mine"
git push origin main

Write-Host "`nAll updates deployed cleanly! Restart Coal LLC to test." -ForegroundColor Green