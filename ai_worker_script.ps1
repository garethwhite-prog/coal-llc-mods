Clear-Host

# ==============================================================================
# Coal LLC - Deploy Mod 1: Employee Passives Mod (Miner Range, Pickup, Collector Range)
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
# 2. CREATE GARETH-EMPLOYEE_PASSIVES_MOD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Creating directory structure for gareth-employee_passives_mod..." -ForegroundColor Cyan
$epRoot     = "$repo\mods-unpacked\gareth-employee_passives_mod"
$epInner    = "$epRoot\mods-unpacked\gareth-employee_passives_mod"
$epExtMiner = "$epInner\extensions\scenes\AutoMiners"
$epExtScript= "$epInner\extensions\scripts"

New-Item -ItemType Directory -Path $epExtMiner -Force | Out-Null
New-Item -ItemType Directory -Path $epExtScript -Force | Out-Null

$epManifest = @"
{
  "name": "employee_passives_mod",
  "namespace": "gareth",
  "version_number": "1.0.0",
  "description": "Expanded employee passives: Employee Miner Range, Employee Miner Pickup Speed, and Collector Range.",
  "website_url": "https://github.com/garethwhite-prog/coal-llc-mods",
  "dependencies": ["gareth-mod_manager_mod"],
  "extra": {
    "godot": {
      "display_name": "Expanded Employee Passives",
      "category": "Employees & Automation",
      "authors": ["Gareth White"],
      "compatible_mod_loader_version": ["7.0.1"],
      "compatible_game_version": ["1.4.1.1"]
    }
  }
}
"@
Set-Content -Path "$epRoot\manifest.json" -Value $epManifest -Encoding UTF8
Set-Content -Path "$epInner\manifest.json" -Value $epManifest -Encoding UTF8

# mod_main.gd
@'
extends Node

const MOD_DIR := "gareth-employee_passives_mod"

func _init() -> void:
	var unpacked_dir = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	var ext_dir = unpacked_dir.path_join("extensions")

	ModLoaderMod.install_script_hooks(
		"res://scenes/AutoMiners/employee_miner_2.gd",
		ext_dir.path_join("scenes/AutoMiners/employee_miner_2.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/LootCollectorUFO.gd",
		ext_dir.path_join("scripts/LootCollectorUFO.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/loot_drops.gd",
		ext_dir.path_join("scripts/loot_drops.hooks.gd")
	)

func _ready() -> void:
	ModLoaderLog.info("Expanded Employee Passives Mod active (Miner Range, Miner Pickup Speed, Collector Range)!", MOD_DIR)
'@ | Set-Content -Path "$epInner\mod_main.gd" -Encoding UTF8

# employee_miner_2.hooks.gd
@'
extends Object

func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	var miner = chain.reference_object
	if is_instance_valid(miner):
		var range_stat: float = _get_passive_stat("employee_miner_range")
		var speed_stat: float = _get_passive_stat("employee_miner_pickup_speed")

		if range_stat > 0.0:
			miner.pickaxe_range = int(round(3.0 * (1.0 + range_stat)))
			miner.search_range = int(round(10.0 * (1.0 + range_stat)))

		if speed_stat > 0.0 and miner.state == miner.States.MOVING_TO_TARGET:
			miner.velocity.x *= (1.0 + speed_stat)

		if range_stat > 0.0 and miner.state == miner.States.MOVING_TO_TARGET:
			var reach: float = 16.0 * (1.0 + range_stat)
			if abs(miner.global_position.x - miner.target_pos.x) < reach:
				miner.mining_animation_player.play("mining")
				miner.state = miner.States.MINING

		if speed_stat > 0.0:
			_vacuum_nearby_loot(miner, 52.0 * (1.0 + range_stat), 260.0 * (1.0 + speed_stat), delta)

	chain.execute_next([delta])

func _vacuum_nearby_loot(miner: Node2D, radius: float, pull_speed: float, delta: float) -> void:
	var tree = miner.get_tree()
	if not tree or not tree.root:
		return
	var loot_mgr = tree.root.find_child("LootDrops", true, false)
	if not loot_mgr:
		return
	var m_pos = miner.global_position
	var r_sq = radius * radius
	for child in loot_mgr.get_children():
		if is_instance_valid(child) and ("global_position" in child):
			var d_sq = m_pos.distance_squared_to(child.global_position)
			if d_sq <= r_sq:
				var dir = (m_pos - child.global_position).normalized()
				child.global_position += dir * pull_speed * delta

func _get_passive_stat(stat_name: String) -> float:
	if not Gvars:
		return 0.0
	if ("custom_passives" in Gvars) and (Gvars.custom_passives is Dictionary) and Gvars.custom_passives.has(stat_name):
		return float(Gvars.custom_passives[stat_name])
	if ("passives" in Gvars) and Gvars.passives:
		if Gvars.passives.has_meta(stat_name):
			return float(Gvars.passives.get_meta(stat_name))
		if stat_name in Gvars.passives:
			return float(Gvars.passives.get(stat_name))
	return 0.0
'@ | Set-Content -Path "$epExtMiner\employee_miner_2.hooks.gd" -Encoding UTF8

# LootCollectorUFO.hooks.gd
@'
extends Object

func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	chain.execute_next([delta])
	var ufo = chain.reference_object
	if not is_instance_valid(ufo):
		return

	var range_stat: float = _get_passive_stat("collector_range")
	if range_stat <= 0.0:
		return

	var magnet_radius: float = 64.0 * (1.0 + range_stat)
	var pull_speed: float = 350.0 * (1.0 + range_stat * 0.5)
	var tree = ufo.get_tree()
	if not tree or not tree.root:
		return
	var loot_mgr = tree.root.find_child("LootDrops", true, false)
	if not loot_mgr:
		return

	var u_pos = ufo.global_position
	var r_sq = magnet_radius * magnet_radius
	for child in loot_mgr.get_children():
		if is_instance_valid(child) and ("global_position" in child):
			var d_sq = u_pos.distance_squared_to(child.global_position)
			if d_sq <= r_sq:
				var dir = (u_pos - child.global_position).normalized()
				child.global_position += dir * pull_speed * delta
				if d_sq < 324.0:
					if child.has_method("pickup"):
						child.pickup(ufo)
					elif ufo.has_method("on_ItemPickup") and ("pickupItem" in child):
						ufo.on_ItemPickup(child.pickupItem, ufo)
						child.queue_free()

func _get_passive_stat(stat_name: String) -> float:
	if not Gvars:
		return 0.0
	if ("custom_passives" in Gvars) and (Gvars.custom_passives is Dictionary) and Gvars.custom_passives.has(stat_name):
		return float(Gvars.custom_passives[stat_name])
	if ("passives" in Gvars) and Gvars.passives:
		if Gvars.passives.has_meta(stat_name):
			return float(Gvars.passives.get_meta(stat_name))
		if stat_name in Gvars.passives:
			return float(Gvars.passives.get(stat_name))
	return 0.0
'@ | Set-Content -Path "$epExtScript\LootCollectorUFO.hooks.gd" -Encoding UTF8

# loot_drops.hooks.gd
@'
extends Object

func find_loot(chain: ModLoaderHookChain, collector) -> void:
	var ld = chain.reference_object
	if is_instance_valid(ld):
		var range_stat: float = _get_passive_stat("collector_range")
		if range_stat > 0.0 and ("collector_sample_live_limit" in ld):
			ld.collector_sample_live_limit = int(round(25.0 * (1.0 + range_stat)))
	chain.execute_next([collector])

func _get_passive_stat(stat_name: String) -> float:
	if not Gvars:
		return 0.0
	if ("custom_passives" in Gvars) and (Gvars.custom_passives is Dictionary) and Gvars.custom_passives.has(stat_name):
		return float(Gvars.custom_passives[stat_name])
	if ("passives" in Gvars) and Gvars.passives:
		if Gvars.passives.has_meta(stat_name):
			return float(Gvars.passives.get_meta(stat_name))
		if stat_name in Gvars.passives:
			return float(Gvars.passives.get(stat_name))
	return 0.0
'@ | Set-Content -Path "$epExtScript\loot_drops.hooks.gd" -Encoding UTF8
Write-Host "  Created: gareth-employee_passives_mod scripts and hooks" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. UPDATE CHOOSE_PASSIVE.HOOKS.GD (ADD 3 PASSIVES TO DEFAULT DICTIONARY)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Registering 3 new passives in choose_passive.hooks.gd..." -ForegroundColor Cyan
$cpHookPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scenes\Interfaces\in_game\choose_passive.hooks.gd"
@'
extends Object

const CUSTOM_PASSIVE_DEFAULTS: Dictionary = {
	"ball_blast_damage": 0.05, "ball_blast_radius": 0.05, "ball_fire_rate": 0.05,
	"chrono_tick_rate": 0.05, "chrono_shockwave_damage": 0.05, "chrono_stasis_duration": 0.05,
	"exec_damage": 0.05, "exec_fire_rate": 0.05, "exec_bounty": 0.05,
	"drill_speed": 0.05, "axe_speed": 0.05, "gun_rate": 0.05,
	"dread_shell_damage": 0.05, "dread_fire_rate": 0.05, "dread_impact_radius": 0.05,
	"jedi_saber_damage": 0.05, "jedi_swing_rate": 0.05, "jedi_cleave_reach": 0.05,
	"sword_damage": 0.05, "sword_speed": 0.05, "sword_range": 0.05,
	"employee_miner_range": 0.05, "employee_miner_pickup_speed": 0.05, "collector_range": 0.05,
	"sinclair_melt_damage": 0.05, "sinclair_beam_width": 0.05, "sinclair_spectrum_ticks": 0.05,
	"fracker_pulse_damage": 0.05, "fracker_seam_resonance": 0.05, "fracker_fire_rate": 0.05,
	"void_implosion_damage": 0.05, "void_pull_radius": 0.05, "void_event_horizon": 0.05
}

func set_up_buttons(chain: ModLoaderHookChain) -> void:
	var screen = chain.reference_object
	if not is_instance_valid(screen) or not ("choose_between" in screen):
		chain.execute_next([])
		return

	var buttons = [screen.button, screen.button_2, screen.button_3]
	for i in range(0, min(3, screen.choose_between.size())):
		var stat_name: String = str(screen.choose_between[i])
		var base_val: float = 0.05
		if screen.ALL_PASSIVES.has(stat_name):
			base_val = screen.ALL_PASSIVES[stat_name]
		elif CUSTOM_PASSIVE_DEFAULTS.has(stat_name):
			base_val = CUSTOM_PASSIVE_DEFAULTS[stat_name]

		var pct_str: String = str(screen.multiplier * (base_val * 100.0))
		buttons[i].text = "Increase " + stat_name.replace("_", " ").capitalize() + " +" + pct_str + "%"

func _on_button_pressed(chain: ModLoaderHookChain) -> void:
	_handle_button_click(chain, 0)

func _on_button_2_pressed(chain: ModLoaderHookChain) -> void:
	_handle_button_click(chain, 1)

func _on_button_3_pressed(chain: ModLoaderHookChain) -> void:
	_handle_button_click(chain, 2)

func _handle_button_click(chain: ModLoaderHookChain, button_idx: int) -> void:
	var screen = chain.reference_object
	if not is_instance_valid(screen) or not screen.live or not ("choose_between" in screen):
		chain.execute_next([])
		return

	if button_idx >= screen.choose_between.size():
		chain.execute_next([])
		return

	var stat_name: String = str(screen.choose_between[button_idx])
	if screen.ALL_PASSIVES.has(stat_name):
		chain.execute_next([])
		return

	screen.live = false
	var base_val: float = CUSTOM_PASSIVE_DEFAULTS.get(stat_name, 0.05)
	var add_amount: float = screen.multiplier * base_val

	if Gvars and ("passives" in Gvars) and Gvars.passives:
		var p: Resource = Gvars.passives
		var cur_meta: float = 0.0
		if p.has_meta(stat_name):
			cur_meta = float(p.get_meta(stat_name))
		p.set_meta(stat_name, cur_meta + add_amount)

	if Gvars:
		if not ("custom_passives" in Gvars) or Gvars.custom_passives == null:
			Gvars.set("custom_passives", {})
		var cp = Gvars.get("custom_passives")
		if cp is Dictionary:
			cp[stat_name] = cp.get(stat_name, 0.0) + add_amount

	screen.get_tree().paused = false
	screen.queue_free()
'@ | Set-Content -Path $cpHookPath -Encoding UTF8

# ------------------------------------------------------------------------------
# 4. UPDATE PASSIVE_BONUSES.HOOKS.GD (ADD 3 PASSIVES TO BONUSES TAB DISPLAY)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Registering 3 new passives in passive_bonuses.hooks.gd..." -ForegroundColor Cyan
$pbHookPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scenes\Interfaces\Management\passive_bonuses.hooks.gd"
@'
extends Object

func refresh(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var pb = chain.reference_object
	if not is_instance_valid(pb) or not Gvars or not ("passives" in Gvars) or not Gvars.passives:
		return

	var p = Gvars.passives

	var worker_stats = {
		"Employee Miner Speed": "employee_miner_speed",
		"Employee Miner Damage": "employee_miner_damage",
		"Employee Collector Speed": "employee_collector_speed",
		"Employee Collector Capacity": "employee_collector_capacity"
	}
	for s_name in worker_stats.keys():
		var prop: String = worker_stats[s_name]
		if prop in p:
			var val: float = float(p.get(prop))
			if val > 0.0:
				var lbl = RichTextLabel.new()
				lbl.text = "Increase %s +%d%%" % [s_name, roundi(val * 100)]
				lbl.fit_content = true
				pb.add_child(lbl)

	var custom_stats = [
		"sword_damage", "sword_speed", "sword_range",
		"employee_miner_range", "employee_miner_pickup_speed", "collector_range",
		"jedi_saber_damage", "jedi_swing_rate", "jedi_cleave_reach",
		"ball_blast_damage", "chrono_tick_rate", "exec_damage",
		"fracker_pulse_damage", "void_implosion_damage", "sinclair_melt_damage"
	]

	var cp_dict: Dictionary = {}
	if ("custom_passives" in Gvars) and (Gvars.custom_passives is Dictionary):
		cp_dict = Gvars.custom_passives

	for stat_key in custom_stats:
		var s_val: float = 0.0
		if cp_dict.has(stat_key):
			s_val = float(cp_dict[stat_key])
		elif p.has_meta(stat_key):
			s_val = float(p.get_meta(stat_key))
		elif stat_key in p:
			s_val = float(p.get(stat_key))

		if s_val > 0.0:
			var c_lbl = RichTextLabel.new()
			c_lbl.text = "Increase %s +%d%%" % [stat_key.replace("_", " ").capitalize(), roundi(s_val * 100)]
			c_lbl.fit_content = true
			pb.add_child(c_lbl)
'@ | Set-Content -Path $pbHookPath -Encoding UTF8

# ------------------------------------------------------------------------------
# 5. UPDATE KNIGHT_PROFESSION.GD UNLOCKED_PASSIVES
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Adding new employee passives to knight_profession.gd unlock pool..." -ForegroundColor Cyan
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
			"employee_miner_range",
			"employee_miner_pickup_speed",
			"employee_collector_speed",
			"employee_collector_capacity",
			"collector_range",
			"player_sprint_speed",
			"player_jump_velocity",
			"player_climb_speed"
		]

	return data
'@ | Set-Content -Path $kpPath -Encoding UTF8
Write-Host "  Updated: knight_profession.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. PURGE HOOK CACHE AND REPACKAGE MODS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Refreshing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
	Remove-Item -Path $hookZip -Force
	Write-Host "  Purged old mod-hooks.zip" -ForegroundColor Green
}

Write-Host "`n>>> 7. Repackaging mod zips..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression.FileSystem

$modsToRepack = @(
	"gareth-employee_passives_mod",
	"gareth-mod_manager_mod",
	"gareth-knight_class_mod"
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
# 7. GIT STAGING, COMMIT & PUSH (DEDICATED MOD COMMIT)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 8. Staging, committing and pushing Mod 1 to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Part 5: Implement Employee Passives Mod (Miner Range, Miner Pickup Speed, Collector Range)"
git push origin main

Write-Host "`nMod 1: Employee Passives Mod deployed and committed cleanly!" -ForegroundColor Green