Clear-Host

# ==============================================================================
# Coal LLC - Workflow Automation, Safe Test Runner & HUD Alignment
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 400

# ------------------------------------------------------------------------------
# 2. CREATE ONE-CLICK WORKER LAUNCHER (Run-Worker.ps1)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Creating Run-Worker.ps1 (Automates execution & output.txt logging)..." -ForegroundColor Cyan
$runWorkerPath = "$repo\Run-Worker.ps1"
@'
# Executes ai_worker_script.ps1, displays live output, and auto-saves to output.txt
$scriptPath = "C:\Dev\coal-llc-mods\ai_worker_script.ps1"
$outputPath = "C:\Dev\coal-llc-mods\output.txt"

if (-not (Test-Path $scriptPath)) {
    Write-Error "ai_worker_script.ps1 not found!"
    exit 1
}

Write-Host ">>> Executing ai_worker_script.ps1 and capturing to output.txt..." -ForegroundColor Cyan
& powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath *>&1 | Tee-Object -FilePath $outputPath
Write-Host "`nExecution finished. Output automatically written to output.txt" -ForegroundColor Green
'@ | Set-Content -Path $runWorkerPath -Encoding UTF8
Write-Host "  Created: Run-Worker.ps1" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. UPGRADE RUN-MODSUITETEST.PS1 (SAFE, NON-DESTRUCTIVE & AUTO-REDUCING)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Upgrading Run-ModSuiteTest.ps1..." -ForegroundColor Cyan
$rmstPath = "$repo\Run-ModSuiteTest.ps1"
@'
Clear-Host
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "COAL LLC - SAFE LOG AUDITOR & TEST RUNNER" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$repoRoot   = "C:\Dev\coal-llc-mods"
$logDir     = [System.IO.Path]::Combine($env:APPDATA, "Godot\app_userdata\Coal LLC\logs")
$godotLog   = [System.IO.Path]::Combine($logDir, "godot.log")
$conciseOut = [System.IO.Path]::Combine($repoRoot, "tests_concise.txt")

if (-not [System.IO.File]::Exists($godotLog)) {
    Write-Host "godot.log not found at $godotLog" -ForegroundColor Yellow
    exit 0
}

Write-Host "Reading $godotLog (safe shared read)..." -ForegroundColor Cyan

# Read shared stream even if Godot is currently holding the file open
$fileStream = [System.IO.FileStream]::new($godotLog, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
$reader     = [System.IO.StreamReader]::new($fileStream, [System.Text.Encoding]::UTF8)
$lines      = [System.Collections.Generic.List[string]]::new()
while (-not $reader.EndOfStream) {
    $lines.Add($reader.ReadLine())
}
$reader.Dispose()
$fileStream.Dispose()

Write-Host "Audited $($lines.Count) log lines. Processing concise telemetry..." -ForegroundColor Green

# Use StreamWriter to directly generate tests_concise.txt without intermediate files
$writer = [System.IO.StreamWriter]::new($conciseOut, $false, [System.Text.Encoding]::UTF8)

$currentKey = $null
$firstLine  = $null
$lastLine   = $null
$count      = 0

function Flush-Run {
    param($key, $first, $last, [int]$cnt)
    if ($cnt -eq 1) {
        $writer.WriteLine($first)
    } elseif ($cnt -eq 2) {
        $writer.WriteLine($first)
        $writer.WriteLine($last)
    } else {
        $writer.WriteLine("[Repeated $cnt times]")
        $writer.WriteLine("  First: $first")
        $writer.WriteLine("  Last:  $last")
    }
}

$telemetry = [System.Collections.Generic.List[string]]::new()

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ([string]::IsNullOrWhiteSpace($line)) { continue }

    if ($line.Contains("SCRIPT ERROR") -or $line.Contains("Invalid get index") -or $line.Contains("Invalid call")) {
        if (-not $line.Contains("der_floh-performance_mod")) {
            $formatted = ("{0,4}: {1}" -f ($i + 1), $line)
            $key = if ($formatted -match '^\s*\d+:\s*(.*)$') { $Matches[1].Trim() } else { $formatted.Trim() }

            if ($null -ne $currentKey -and $key -eq $currentKey) {
                $lastLine = $formatted
                $count++
            } else {
                if ($count -gt 0) { Flush-Run -key $currentKey -first $firstLine -last $lastLine -cnt $count }
                $currentKey = $key
                $firstLine  = $formatted
                $lastLine   = $formatted
                $count      = 1
            }
        }
    }

    if ($line.Contains("[KnightSword]") -or $line.Contains("Auto choosing") -or $line.Contains("Transmutation")) {
        $telemetry.Add(("{0,4}: {1}" -f ($i + 1), $line))
    }
}

if ($count -gt 0) { Flush-Run -key $currentKey -first $firstLine -last $lastLine -cnt $count }

if ($telemetry.Count -gt 0) {
    $writer.WriteLine("Telemetry Highlights (Last 15):")
    $start = [Math]::Max(0, $telemetry.Count - 15)
    for ($t = $start; $t -lt $telemetry.Count; $t++) {
        $writer.WriteLine($telemetry[$t])
    }
}

$writer.Dispose()

Write-Host "Summarized telemetry automatically saved to: $conciseOut" -ForegroundColor Green
Get-Content $conciseOut | Select-Object -First 25 | ForEach-Object { Write-Host "  $_" }
'@ | Set-Content -Path $rmstPath -Encoding UTF8
Write-Host "  Updated: Run-ModSuiteTest.ps1 (Safe and auto-reducing)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. FIX AIR WINGS HUD (BOTTOM-RIGHT ANCHORS & IN-MINE STAGE GATING)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Docking Air Wings HUD to bottom-right and strictly gating to mine..." -ForegroundColor Cyan
$eamScript = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\elemental_airstrike_manager.gd"
@'
extends Node

var canvas: CanvasLayer
var panel: PanelContainer
var btn_dragon: Button
var btn_water: Button
var btn_poison: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()

func _build_hud() -> void:
	canvas = CanvasLayer.new()
	canvas.name = "AirWingsHUDCanvas"
	canvas.layer = 94
	add_child(canvas)

	panel = PanelContainer.new()
	# Anchor to Bottom-Right, right above Amazon button
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -264.0
	panel.offset_right = -16.0
	panel.offset_top = -126.0
	panel.offset_bottom = -92.0
	panel.visible = false

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)

	btn_dragon = Button.new()
	btn_dragon.text = "🔥 Dragon (7)"
	btn_dragon.modulate = Color(1.0, 0.4, 0.2, 1.0)
	btn_dragon.tooltip_text = "Deploy Fire Dragon Airstrike [ Key 7 ]"
	btn_dragon.pressed.connect(func(): trigger_strike("dragon"))
	hbox.add_child(btn_dragon)

	btn_water = Button.new()
	btn_water.text = "💧 Water (8)"
	btn_water.modulate = Color(0.3, 0.7, 1.0, 1.0)
	btn_water.tooltip_text = "Deploy Water Bomber Airstrike [ Key 8 ]"
	btn_water.pressed.connect(func(): trigger_strike("water"))
	hbox.add_child(btn_water)

	btn_poison = Button.new()
	btn_poison.text = "☣️ Poison (9)"
	btn_poison.modulate = Color(0.4, 1.0, 0.4, 1.0)
	btn_poison.tooltip_text = "Deploy Agent Orange Poison Bomber [ Key 9 ]"
	btn_poison.pressed.connect(func(): trigger_strike("poison"))
	hbox.add_child(btn_poison)

	panel.add_child(hbox)
	canvas.add_child(panel)

func _process(_delta: float) -> void:
	var tree = get_tree()
	var in_mining_shift := false
	if tree and tree.root:
		var p = tree.root.find_child("Player", true, false)
		var tm = tree.root.find_child("TileMapManager", true, false)
		var pause = tree.root.find_child("PauseMenu", true, false)
		# Only visible during active underground gameplay
		in_mining_shift = (p is Node2D) and is_instance_valid(tm) and (not is_instance_valid(pause) or not pause.visible)

	if panel:
		panel.visible = in_mining_shift

func _unhandled_input(event: InputEvent) -> void:
	if not panel.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_7:
			trigger_strike("dragon")
		elif event.keycode == KEY_8:
			trigger_strike("water")
		elif event.keycode == KEY_9:
			trigger_strike("poison")

func trigger_strike(strike_type: String) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return

	var p = tree.root.find_child("Player", true, false)
	var target_pos: Vector2 = p.global_position if (p is Node2D) else Vector2.ZERO

	var strike_node: Node2D = null
	if strike_type == "dragon":
		var scr = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/dragon_strike.gd")
		strike_node = Node2D.new()
		strike_node.set_script(scr)
	elif strike_type == "water":
		var scr = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/water_bomber_strike.gd")
		strike_node = Node2D.new()
		strike_node.set_script(scr)
	elif strike_type == "poison":
		var scr = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/agent_orange_strike.gd")
		strike_node = Node2D.new()
		strike_node.set_script(scr)

	if strike_node:
		strike_node.global_position = target_pos
		tree.current_scene.add_child(strike_node)

		var boom_audio = AudioStreamPlayer2D.new()
		boom_audio.stream = load("res://assets/sound/sound effects/box_1.wav")
		boom_audio.pitch_scale = 0.8
		boom_audio.global_position = target_pos
		tree.current_scene.add_child(boom_audio)
		boom_audio.play()
		boom_audio.finished.connect(boom_audio.queue_free)
'@ | Set-Content -Path $eamScript -Encoding UTF8

# ------------------------------------------------------------------------------
# 5. REGISTER MISSING MAPS IN LEVEL_SELECT.HOOKS.GD (ABYSSAL TRENCH & DIAGONAL)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Registering Abyssal Trench & Diagonal Map in level_select.hooks.gd..." -ForegroundColor Cyan
$atHook = "$repo\mods-unpacked\gareth-abyssal_trench_mod\mods-unpacked\gareth-abyssal_trench_mod\extensions\scenes\Interfaces\Menus\level_select.hooks.gd"
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-abyssal_trench_mod/helpers/AbyssalTrenchHelper.gd")
	if helper_script:
		var helper = helper_script.new()
		if helper.has_method("ensure_level_registered"):
			helper.ensure_level_registered()
		var ls = chain.reference_object
		if ls and ("LEVEL_ORDER" in ls):
			if not ls.LEVEL_ORDER.has(helper.ABYSSAL_LEVEL_ID):
				ls.LEVEL_ORDER.append(helper.ABYSSAL_LEVEL_ID)
	chain.execute_next([])
'@ | Set-Content -Path $atHook -Encoding UTF8

$dmHookDir = "$repo\mods-unpacked\gareth-diagonal_map_mod\mods-unpacked\gareth-diagonal_map_mod\extensions\scenes\Interfaces\Menus"
New-Item -ItemType Directory -Path $dmHookDir -Force | Out-Null
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var ls = chain.reference_object
	if ls and ("LEVEL_ORDER" in ls):
		if not ls.LEVEL_ORDER.has(105):
			ls.LEVEL_ORDER.append(105)
	chain.execute_next([])
'@ | Set-Content -Path "$dmHookDir\level_select.hooks.gd" -Encoding UTF8

# Register hook in diagonal map mod_main.gd
$dmMain = "$repo\mods-unpacked\gareth-diagonal_map_mod\mods-unpacked\gareth-diagonal_map_mod\mod_main.gd"
@'
extends Node
const MOD_DIR := "gareth-diagonal_map_mod"
func _init() -> void:
	ModLoaderMod.install_script_hooks("res://scenes/tilemaps/tile_map_chunk.gd", "res://mods-unpacked/gareth-diagonal_map_mod/extensions/scenes/tilemaps/tile_map_chunk.hooks.gd")
	ModLoaderMod.install_script_hooks("res://scenes/Interfaces/Menus/level_select.gd", "res://mods-unpacked/gareth-diagonal_map_mod/extensions/scenes/Interfaces/Menus/level_select.hooks.gd")
func _ready() -> void:
	ModLoaderLog.info("Diagonal Map Mod active!", MOD_DIR)
'@ | Set-Content -Path $dmMain -Encoding UTF8

# ------------------------------------------------------------------------------
# 6. REPACK ALL MODS & SYNC PRODUCTIONS ARCHIVES
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Repackaging all modified mods to Steam..." -ForegroundColor Cyan
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

Add-Type -AssemblyName System.IO.Compression.FileSystem

$modsToRepack = @(
	"gareth-mod_manager_mod",
	"gareth-elemental_airstrikes_mod",
	"gareth-abyssal_trench_mod",
	"gareth-diagonal_map_mod",
	"gareth-knight_class_mod",
	"gareth-scrap_and_delivery_mod"
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
# 7. COMMIT & PUSH
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Workflow: Add Run-Worker auto-logger, safe log auditor in Run-ModSuiteTest, dock Air Wings HUD, and register all custom maps"
git push origin main

Write-Host "`nAutomation and fixes deployed successfully!" -ForegroundColor Green