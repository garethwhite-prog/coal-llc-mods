cls
# ==============================================================================
# Coal LLC - Cryo-Pod Visual States & Passive Chest Integration
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

Write-Host ">>> 1. Generating cryo_pod_opened.png (evacuated state)..." -ForegroundColor Cyan
Add-Type -AssemblyName System.Drawing

$podOpenedPath = "$innerDir\assets\cryo_pod_opened.png"
$podBmp = New-Object System.Drawing.Bitmap 32, 32
$gPod = [System.Drawing.Graphics]::FromImage($podBmp)
$gPod.Clear([System.Drawing.Color]::Transparent)

$fBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(60, 65, 70))
$sBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(45, 50, 55))
$hBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(18, 20, 24))
$dBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(75, 45, 45))

# Unpowered exterior frame
$gPod.FillRectangle($fBrush, 4, 2, 24, 28)
$gPod.FillRectangle($sBrush, 6, 4, 20, 24)
# Hollow opened interior chamber
$gPod.FillRectangle($hBrush, 8, 7, 16, 15)
# Dim red offline status diode
$gPod.FillEllipse($dBrush, 13, 23, 6, 3)

$podBmp.Save($podOpenedPath, [System.Drawing.Imaging.ImageFormat]::Png)
$gPod.Dispose()
$podBmp.Dispose()
Write-Host "Generated: $podOpenedPath" -ForegroundColor Green

Write-Host ">>> 2. Updating entities/CryoPod.gd with passive choice & state swap..." -ForegroundColor Cyan
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
	
	# 1. Visual confirmation: swap texture to hollow evacuated chamber
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
		rescued_name = chosen_emp.employee_name
	Gvars.CashCount += 10000.0
	
	ModLoaderLog.info("Cryo-Pod breached! Rescued " + rescued_name + " + Salvaged $10,000.", "gareth-lost_expedition_mod")
	
	# 4. Trigger 3-card passive selection (integrates with choose_passive & nanobotz-autopassivechooser)
	var passive_res = load("res://resources/Items/power_ups/PassiveUpgrade.tres")
	if passive_res:
		var passive_upgrade = passive_res.duplicate()
		if passive_upgrade and passive_upgrade.itemPickupEffect:
			var effect = passive_upgrade.itemPickupEffect.duplicate()
			var depth_mult: float = maxf(2.0, minf(6.0, 2.0 + abs(global_position.y) / 250.0))
			effect.multiplier = depth_mult
			effect.pickupEffect(passive_upgrade)
'@ | Set-Content -Path "$innerDir\entities\CryoPod.gd" -Encoding UTF8
Write-Host "Updated: $innerDir\entities\CryoPod.gd" -ForegroundColor Green

Write-Host ">>> 3. Flushing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 4. Repackaging mod archive for Steam..." -ForegroundColor Cyan
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

Write-Host ">>> 5. Git committing and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Add evacuated Cryo-Pod sprite and integrate passive upgrade selection"
git push origin main

Write-Host "`nAll tasks complete! Launch Coal LLC to test the updated pods." -ForegroundColor Green