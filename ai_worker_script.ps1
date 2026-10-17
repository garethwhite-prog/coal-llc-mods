cls

# ==============================================================================
# Coal LLC - Fix Coal Drops, Cryo-Pod Passive Signal & Inspect Profession
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$modName    = "gareth-lost_expedition_mod"
$outerDir   = "$repo\mods-unpacked\$modName"
$innerDir   = "$outerDir\mods-unpacked\$modName"
$zipPath    = "$steamMods\$modName.zip"
$hookZip    = "$steamRoot\mod-hooks.zip"
$dumpRoot   = "$steamRoot\_dump"

Set-Location $repo

Write-Host ">>> 1. Patching LostExpeditionHelper.gd with exact Coal.tres path..." -ForegroundColor Cyan
$helperPath = "$innerDir\helpers\LostExpeditionHelper.gd"
$helperContent = Get-Content $helperPath -Raw
# Replace invalid lowercase coal path with verified case-sensitive res://resources/Items/Coal.tres
$helperContent =$helperContent -replace 'res://resources/items/mined_items/coal\.tres', 'res://resources/Items/Coal.tres'
Set-Content -Path $helperPath -Value $helperContent -Encoding UTF8
Write-Host "Updated Coal drop path in: $helperPath" -ForegroundColor Green

Write-Host ">>> 2. Updating CryoPod.gd to directly emit Bus.choose_passive..." -ForegroundColor Cyan
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
		rescued_name = chosen_emp.employee_name
	Gvars.CashCount += 10000.0
	
	ModLoaderLog.info("Cryo-Pod breached! Rescued " + rescued_name + " + Salvaged $10,000.", "gareth-lost_expedition_mod")
	
	# 4. Trigger 3-card passive selection directly via Bus signal
	var depth_mult: float = maxf(2.0, minf(6.0, 2.0 + abs(global_position.y) / 250.0))
	if Bus and Bus.has_signal("choose_passive"):
		Bus.choose_passive.emit(depth_mult)
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

foreach ($f in $allFiles) {$entryName = $f.FullName.Substring($outerDir.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$zipStream.Dispose()
Write-Host "Packed clean archive at: $zipPath" -ForegroundColor Green

Write-Host ">>> 5. Git committing and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Fix case-sensitive Coal.tres drop path and directly emit Bus.choose_passive from CryoPod"
git push origin main

Write-Host ">>> 6. Inspecting Bus.NewGame listeners & nanobotz profession logic..." -ForegroundColor Cyan
$diagOutput = @()
$diagOutput += "=== PROFESSION & NEWGAME DIAGNOSTIC ==="

# Search where Bus.NewGame is connected in _dump
$diagOutput += "`n--- 1. Bus.NewGame Listeners in Vanilla ---"
Get-ChildItem -Path $dumpRoot -Filter "*.gd" -Recurse | ForEach-Object {
    $matches = Get-Content $_.FullName | Select-String -Pattern 'NewGame\.connect\b|connect\(\s*["'']NewGame["'']'
    if ($matches) {
        $diagOutput += "`nIn $($_.FullName.Replace($dumpRoot, '')):"
        foreach ($m in $matches) {$diagOutput += "  L$($m.LineNumber): $($m.Line.Trim())"
        }
    }
}

# Inspect nanobotz-autopassivechooser settings tab / profession reading
$nanobotzZip = "$steamMods\nanobotz-autopassivechooser.zip"
if (Test-Path $nanobotzZip) {$diagOutput += "`n--- 2. nanobotz-autopassivechooser Script Contents ---"
    $za = [System.IO.Compression.ZipFile]::OpenRead($nanobotzZip)
    foreach ($entry in $za.Entries) {
        if ($entry.Name.EndsWith(".gd")) {
            $diagOutput += "`n>>> File in zip: $($entry.FullName)"
            $reader = New-Object System.IO.StreamReader($entry.Open())
            $content = $reader.ReadToEnd()
            $reader.Dispose()
            $cLines =$content -split "`r?`n"
            for ($i = 0; $i -lt [Math]::Min(50, $cLines.Length);$i++) {
                if ($cLines[$i] -match "(profession|Gvars|Settings|tab|Internship)") {
                    $diagOutput += "{0,3}: {1}" -f ($i + 1), $cLines[$i]
                }
            }
        }
    }
    $za.Dispose()
}

$diagText =$diagOutput -join "`r`n"
$diagText | Set-Clipboard

Write-Host "Diagnostic complete! Output copied to clipboard." -ForegroundColor Green