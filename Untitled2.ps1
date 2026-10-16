cls
# ==============================================================================
# Coal LLC - Patch purchase_employee_level count & Async Await in Game.hooks.gd
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

Write-Host ">>> 1. Patching CryoPod.gd with purchase_employee_level(emp, 1.0)..." -ForegroundColor Cyan
@'
class_name CryoPod
extends Area2D

var in_range: bool = false
var looted: bool = false
var sprite: Sprite2D

func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 1
	collision_mask = 1
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16.0
	col.shape = shape
	add_child(col)
	
	sprite = Sprite2D.new()
	var img = Image.load_from_file("res://mods-unpacked/gareth-lost_expedition_mod/assets/cryo_pod.png")
	if img:
		sprite.texture = ImageTexture.create_from_image(img)
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
	looted = true
	in_range = false
	if Bus and Bus.has_signal("ShowInputIndicator"):
		Bus.ShowInputIndicator.emit("interact", false, self)
	
	var emp_mgr = Gvars.employee_manager
	if emp_mgr and emp_mgr.ALL_EMPLOYEES.size() > 0:
		var chosen_emp = emp_mgr.ALL_EMPLOYEES[randi() % emp_mgr.ALL_EMPLOYEES.size()]
		emp_mgr.purchase_employee_level(chosen_emp, 1.0)
		Gvars.CashCount += 10000.0
		ModLoaderLog.info("Cryo-Pod opened! Rescued " + chosen_emp.employee_name + "! Salvaged $10,000.", "gareth-lost_expedition_mod")
	
	if sprite:
		sprite.modulate = Color(0.3, 1.0, 0.4, 0.8)
'@ | Set-Content -Path "$innerDir\entities\CryoPod.gd" -Encoding UTF8

Write-Host ">>> 2. Ensuring Game.hooks.gd uses await on change_stage..." -ForegroundColor Cyan
@'
extends Object

func change_stage(chain: ModLoaderHookChain, target: int, targetPosition: Vector2) -> void:
	var game = chain.reference_object
	if target == 2 and Gvars.level == 101:
		if game and "MINE_REGION" in game:
			game.target_stage = game.MINE_REGION
	await chain.execute_next([target, targetPosition])
'@ | Set-Content -Path "$innerDir\extensions\scripts\Game.hooks.gd" -Encoding UTF8

Write-Host ">>> 3. Flushing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 4. Repackaging mod archive for Steam..." -ForegroundColor Cyan
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
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

Write-Host ">>> 5. Git committing and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Fix purchase_employee_level count parameter in CryoPod and await stage transitions"
git push origin main

Write-Host "`nPatch deployed cleanly! Launch Coal LLC to test Cryo-Pods." -ForegroundColor Green