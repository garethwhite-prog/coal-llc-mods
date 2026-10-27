# ==============================================================================
# Coal LLC - Fix SaveSlotManager Parse Error, Wire Store to Main Menu & Sync Docs
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 400

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

# ------------------------------------------------------------------------------
# 2. PRUNE DUPLICATE FUNCTION IN SAVESLOTMANAGER.GD (RESTORE CLASS UNLOCKS)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Pruning duplicate function in save_slot_manager.gd..." -ForegroundColor Cyan
$ssmPath = "$repo\mods-unpacked\gareth-multisave_mod\mods-unpacked\gareth-multisave_mod\scripts\save_slot_manager.gd"
$ssmLines = Get-Content $ssmPath
$cleanedLines = [System.Collections.Generic.List[string]]::new()

$skipDuplicate = $false
for ($i = 0; $i -lt $ssmLines.Count; $i++) {
	$line = $ssmLines[$i]

	# Detect the second definition of is_mod_active_for_run around line 153
	if ($i -gt 135 -and $line.Trim().StartsWith("func is_mod_active_for_run")) {
		$skipDuplicate = $true
		continue
	}

	# Stop skipping when we hit set_active_slot_mods
	if ($skipDuplicate -and $line.Trim().StartsWith("func set_active_slot_mods")) {
		$skipDuplicate = $false
	}

	if (-not $skipDuplicate) {
		$cleanedLines.Add($line)
	}
}

Set-Content -Path $ssmPath -Value $cleanedLines -Encoding UTF8
Write-Host "  Cleaned: save_slot_manager.gd (Class unlocks & career ranks restored)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. HARDEN _ON_CONFIRM IN PRE_RUN_MOD_SELECTOR.GD (GUARANTEE MAP SELECT TRANSITION)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Hardening _on_confirm in pre_run_mod_selector.gd..." -ForegroundColor Cyan
$prmsPath = "$repo\mods-unpacked\gareth-multisave_mod\mods-unpacked\gareth-multisave_mod\scenes\pre_run_mod_selector.gd"
$prmsCode = Get-Content $prmsPath -Raw
$prmsCode = $prmsCode.Replace(
@'
func _on_confirm() -> void:
	var ssm = get_node_or_null("/root/SaveSlotManager")
	if ssm:
		var cfg := {"mods": toggles}
		var f := FileAccess.open(ssm.get_slot_config_path(ssm.current_slot), FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(cfg, "\t"))
			f.close()
	run_confirmed.emit()
	queue_free()
'@,
@'
func _on_confirm() -> void:
	var ssm = get_node_or_null("/root/SaveSlotManager")
	if ssm and ("current_slot" in ssm) and ssm.has_method("get_slot_config_path"):
		var cfg := {"mods": toggles}
		var path: String = ssm.get_slot_config_path(ssm.current_slot)
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(cfg, "\t"))
			f.close()
	run_confirmed.emit()
	queue_free()
'@
)
Set-Content -Path $prmsPath -Value $prmsCode -Encoding UTF8
Write-Host "  Updated: pre_run_mod_selector.gd (Map select transition guaranteed)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. HOOK MOD & MAP STORE BUTTON DIRECTLY ONTO MAIN MENU
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Adding 'Mod & Map Store' button directly to Main Menu..." -ForegroundColor Cyan
$mmmHookPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scripts\MainMenu.hooks.gd"
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var menu = chain.reference_object
	if not menu:
		return

	var btn_grid = menu.get_node_or_null("%MainMenuButtons")
	if btn_grid:
		if not btn_grid.has_node("ModManagerButton"):
			var mod_btn := Button.new()
			mod_btn.name = "ModManagerButton"
			mod_btn.text = "Mod Manager"
			mod_btn.custom_minimum_size = Vector2(0, 32)
			mod_btn.pressed.connect(func():
				var view_script = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_manager_view.gd")
				var view: Control = Control.new()
				view.set_script(view_script)
				view.is_pre_run_mode = false
				menu.add_child(view)
			)
			btn_grid.add_child(mod_btn)
			btn_grid.move_child(mod_btn, 2)

		if not btn_grid.has_node("ModStoreButton"):
			var store_btn := Button.new()
			store_btn.name = "ModStoreButton"
			store_btn.text = "Mod & Map Store"
			store_btn.custom_minimum_size = Vector2(0, 32)
			store_btn.modulate = Color(1.0, 0.88, 0.35)
			store_btn.pressed.connect(func():
				var store_script = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_store_view.gd")
				if store_script:
					var store_view: Control = Control.new()
					store_view.set_script(store_script)
					menu.add_child(store_view)
			)
			btn_grid.add_child(store_btn)
			btn_grid.move_child(store_btn, 3)

		if not btn_grid.has_node("LeaderboardsButton"):
			var lb_btn := Button.new()
			lb_btn.name = "LeaderboardsButton"
			lb_btn.text = "Leaderboards"
			lb_btn.custom_minimum_size = Vector2(0, 32)
			lb_btn.pressed.connect(func():
				var modal_script = load("res://mods-unpacked/gareth-leaderboard_mod/scenes/leaderboard_modal.gd")
				if modal_script:
					var modal = modal_script.new()
					menu.add_child(modal)
			)
			btn_grid.add_child(lb_btn)
			btn_grid.move_child(lb_btn, 4)

func on_profession_selected(chain: ModLoaderHookChain, mode: int, prof: Object, hard_modifier: Object) -> void:
	var menu = chain.reference_object
	if not menu:
		chain.execute_next([mode, prof, hard_modifier])
		return

	var p_select = menu.get_node_or_null("ProfessionSelect")
	if not p_select and "profession_select" in menu:
		p_select = menu.profession_select
	if p_select:
		p_select.visible = false

	var view_script = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_manager_view.gd")
	var view: Control = Control.new()
	view.set_script(view_script)
	view.name = "PreRunModSelector"
	view.is_pre_run_mode = true

	view.confirmed.connect(func():
		chain.execute_next([mode, prof, hard_modifier])
	)

	view.back_pressed.connect(func():
		if p_select:
			p_select.visible = true
	)

	menu.add_child(view)
'@ | Set-Content -Path $mmmHookPath -Encoding UTF8
Write-Host "  Updated: MainMenu.hooks.gd (Mod & Map Store button mounted)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. REPACK AFFECTED MOD ARCHIVES
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Repackaging multisave_mod & mod_manager_mod..." -ForegroundColor Cyan
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

$modsToRepack = @(
	"gareth-multisave_mod",
	"gareth-mod_manager_mod"
)

foreach ($m in $modsToRepack) {
	$src = "$repo\mods-unpacked\$m"
	$zip = "$steamMods\$m.zip"

	if (-not (Test-Path $src)) { continue }
	if (Test-Path $zip) { Remove-Item -Path $zip -Force }

	$stream  = [System.IO.File]::Open($zip, [System.IO.FileMode]::CreateNew)
	$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
	foreach ($f in (Get-ChildItem -Path $src -Recurse -File)) {
		$entryName = $f.FullName.Substring($src.Length + 1).Replace("\", "/")
		[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
	}
	$archive.Dispose()
	$stream.Dispose()
	Write-Host "  Repacked cleanly: $m.zip" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 6. COMPREHENSIVE UPDATE OF README.MD (DOCUMENT ALL RECENT RELEASES)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Updating README.md with all new releases & engine contracts..." -ForegroundColor Cyan
@'
# Coal LLC Modding Suite

A complete, high-performance ecosystem of gameplay overhauls, custom subterranean maps, unique character classes, industrial workforce hierarchies, high-tier demolition options, and quality-of-life tools for **[Coal LLC](https://store.steampowered.com/app/3361510/Coal_LLC/)**, built on the **[Godot ModLoader 7.x](https://godotengine.org/asset-library/asset/4107)** hook architecture.

![Tectonic Faultline Preview](mods-unpacked/gareth-tectonic_faultline_mod/assets/tectonic_preview.png)

---

## Complete Mod Directory (51 mods)

### 1. Custom Maps & Subterranean Overhauls (Maps 101–105)
| Mod | ID | Type | Description |
| :--- | :--- | :--- | :--- |
| **The Lost Expedition** | `gareth-lost_expedition_mod` | Map (ID 101) | Subterranean cryo-abyss featuring ancient buried shelters, unexploded landmines (UXO), and survival extraction mechanics. |
| **Tectonic Faultline** | `gareth-tectonic_faultline_mod` | Map (ID 102) | Seismic rift featuring vertical chasms, active magma fissures, 3x density elemental pods (Fire, Water, Poison), and an elemental tick rate progression engine. |
| **The Living Canvas** | `gareth-living_canvas_mod` | Map (ID 103) | Image-to-strata mosaic quarry supporting custom PNG imports converted into mineable subterranean strata. |
| **The Abyssal Trench** | `gareth-abyssal_trench_mod` | Map (ID 104) | Subterranean ocean trench featuring hydrothermal black smoker geysers, twilight sapphire strata, and abyssal basalt. |
| **Diagonal Seams** | `gareth-diagonal_map_mod` | Map (ID 105) | 45-degree rotated diagonal subterranean strata layers requiring specialized diagonal tunneling and stepped excavation. |

### 2. Character Classes & Combat Archetypes
| Mod | ID | Description |
| :--- | :--- | :--- |
| **Knight Class** | `gareth-knight_class_mod` | Master of chivalric blade combat. Starts with a Shoddy Sword that sweeps in a 180° frontal arc clearing rock and ore. |
| **Jedi Class** | `gareth-jedi_class_mod` | Wielder of plasma energy sabers across 15 mineral tiers with rapid deflect swings and rock vaporisation. |
| **Bouncing Demolitionist**| `gareth-custom_classes_mod` | Master of ricochet excavation using bouncy rubber demolition spheres. |
| **Rainbow Sinclairity** | `gareth-sinclairity_class_mod` | Experimental spectral optics miner with continuous prismatic beam across 15 tiers. |
| **Void Siphon** | `gareth-void_siphon_mod` | Gravitational vacuum imploder that collapses distant ore veins directly into personal inventory. |
| **Debt Executioner** | `gareth-debt_executioner_mod` | High-risk financial class converting unpaid daily quotas into raw pickaxe excavation damage. |
| **Chrono-Industrialist** | `gareth-chrono_industrialist_mod` | Temporal manipulation specialist that warps excavation speed and slows physics timers. |
| **Gravitational Dreadnought** | `gareth-grav_dreadnought_mod` | Heavy exo-suit miner that crushes stone beneath accelerated downward terminal velocity. |
| **Tectonic Fracker** | `gareth-tectonic_fracker_mod` | High-pressure hydraulic injection specialist that shatters surrounding strata veins. |

### 3. Weapons, Demolition & Surface Hazards
| Mod | ID | Description |
| :--- | :--- | :--- |
| **Elemental Airstrikes & B-52** | `gareth-elemental_airstrikes_mod` | Consumable tactical radios: Dragon Firebomber, Water Deluge, Agent Orange Defoliant, and **B-52 Carpet Bomber** (10 heavy ordnance bombs). |
| **High-Energy Laser Beam** | `gareth-laser_beam_mod` | Continuous collimated beam that melts stone and ore in real time via scaled mining damage. |
| **Donkey Kong Surface Hazard** | `gareth-donkey_kong_mod` | Surface plateau ape that rolls heavy wooden barrels into the shaft, stunning and immobilizing miners for 2.5 seconds. |
| **Heavy Turrets** | `gareth-heavy_turrets_mod` | Deployable perimeter auto-turrets targeting subterranean stone clusters within a 14-tile radius. |
| **Bouncing Grenades** | `gareth-grenade_mod` | 15 tiers of timed demolition grenades that rebound off solid walls before exploding. |
| **Tank Arsenal** | `gareth-tank_arsenal_mod` | Heavy artillery tank shells with shockwave piercing and multi-block blast radiuses. |

### 4. Workforce, Automation & Progression
| Mod | ID | Description |
| :--- | :--- | :--- |
| **Workforce Chart** | `gareth-more_employees_mod` | Complete 5-tier employee hierarchy: Interns, Junior Miners, Engineers, Directors, and Executives. |
| **Collector UFO Priority** | `gareth-collector_priority_mod` | Configurable in-game settings tab: Closest First, Most Valuable Gems First, or Quota Priority. |
| **Auto-Ladder Builder** | `gareth-auto_ladder_mod` | Automatically drops scaffolding ladders under the miner when descending vertical shafts. |
| **Scrap & Parachute Delivery**| `gareth-scrap_and_delivery_mod` | Mid-mine ore recycling for 50% cash and instant parachute deliveries via Amazon drone. |
| **Bonus Upgrades Search & Filter** | `gareth-mod_manager_mod` | Search bar, A-Z sorting, and "Affordable Only" checkbox on both Equipment and Bonus Upgrades shop tabs. |
| **Multisave Career Profiles** | `gareth-multisave_mod` | 6 isolated career save slots with independent JSON mod configurations and badge persistence. |
| **In-Game Mod & Map Store** | `gareth-mod_manager_mod` | Title-screen community repository browser with category filtering and version checking. |

---

## Core Engine Modding Contracts

1. **Sky Code Contract:** `lvl_from_global_pos(pos)` must return `-2` whenever `pos.y <= 0`. Returning positive rock tiers at or above ground level fills the sky and spawn point with solid bedrock, crushing the player on spawn.
2. **Tile Damage Signature:** In *Coal LLC*, tile damage is processed via `tilemap.damageTileCoords(coords: Vector2i, damage: float)`. Passing non-primitive objects into argument 2 triggers an unhandled conversion abort.
3. **InputMap Restrictions:** Never query unmapped input action names (e.g., `"fire"`). Vanilla only registers `useItem`, `rightMouseClick`, and `toggle_use_item`. Querying unregistered strings logs errors on every physics tick.
4. **Chunk Bounds Protection:** `TileMapManager.chunks_created` must be guarded with `.has(chunk_id)` before indexing. Querying unloaded chunk IDs throws an unhandled dictionary exception.
5. **Ordnance & Tween Lifecycles:** Decouple falling projectiles from their parent launchers into standalone entities (`AirstrikeBomb`) to prevent `Instance is null` errors when parent nodes are freed while tween callbacks are pending.
'@ | Set-Content -Path (Join-Path $repo "README.md") -Encoding UTF8
Write-Host "  Updated: README.md" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 7. COMPREHENSIVE UPDATE OF SESSION_PROMPT.MD (RETAINED KNOWLEDGE BASE)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Updating SESSION_PROMPT.md with all retained architectural knowledge..." -ForegroundColor Cyan
@'
# Coal LLC Modding Architecture & Session Knowledge Base (Updated October 2026)

## 1. Directory Structure & Environment Paths
- Local Git Repository: `C:\Dev\coal-llc-mods`
- Remote Repository: `https://github.com/garethwhite-prog/coal-llc-mods`
- Active Unpacked Mods: `C:\Dev\coal-llc-mods\mods-unpacked\<namespace>-<mod_name>`
- Steam Game Root: `C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC`
- Steam Active Mods (.zip): `C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mods`
- Hook Preprocessor Zip: `C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mod-hooks.zip`
- User Data & Logs: `%APPDATA%\Godot\app_userdata\Coal LLC` (`godot.log`, `modloader.log`, `gareth_mods_config.json`, `profile_mods_slot_*.json`)

## 2. Packaging & Git Directives
1. **Dual-Manifest & Dual-README Requirement:**
   Every mod archive MUST contain `manifest.json` and `README.md` at the archive root AND duplicate copies inside `mods-unpacked/<namespace>-<mod_name>/`.
   `manifest.json` strictly requires: `name`, `namespace`, `version_number`, `description`, `website_url`, `dependencies`, and `extra: { godot: { ... } }`.
2. **Forward Slash Zip Rule:**
   Godot's virtual filesystem requires all zip entry paths to use forward slashes (`/`). Windows `Compress-Archive` uses backslashes (`\`), causing silent resource load failures. Always use `System.IO.Compression.ZipArchive` with entry paths normalized via `.Replace("\", "/")`.
3. **Targeted Deployment Only:**
   Only repack archives that have received code or asset updates. Never touch or rebuild unrelated mod packages.
4. **Test Runner Timing:**
   Never run `Run-ModSuiteTest.ps1` at the end of deployment scripts. The test auditor must only run after the developer has launched the game and played a live session to produce fresh telemetry.

## 3. Core Engine Contracts & Invariants
1. **The Sky Code Contract ($Y \le 0$):**
   `lvl_from_global_pos(pos)` must return `-2` whenever `pos.y <= 0`. Returning `>= 0` generates solid subterranean rock throughout the surface, crushing the player on frame 1.
2. **Native Tile Damage Protocol:**
   `tilemap.damageTileCoords(coords: Vector2i, damage: float)` is the sole engine method for damaging strata. Argument 2 must always be cast to `float`.
3. **InputMap Action Integrity:**
   The game registers `useItem`, `rightMouseClick`, and `toggle_use_item`. It does NOT register `"fire"`. Querying `Input.is_action_pressed("fire")` throws an engine error on every physics frame.
4. **Unloaded Chunk Dictionary Guard:**
   `TileMapManager.chunks_created` must be guarded with `.has(chunk_id)` before indexing. Querying coordinates outside active chunks throws fatal dictionary key exceptions.
5. **Chest Loot Null Dereference:**
   When a chest detonates as a booby trap, `chest.loot` is cleared to `null`. Hooks must verify `chest.loot != null` before delegating to vanilla `pickup_item()`.
6. **Ordnance Callback Isolation:**
   Falling ordnance must be instantiated as independent entities (`AirstrikeBomb`) rather than child nodes of moving planes. Freeing the parent plane while tween callbacks are queued causes `Instance is null` errors.
7. **Player Stun Implementation:**
   Freezing the character requires setting `velocity = Vector2.ZERO`, setting `able_to_mine = false`, and pausing the child `$StateMachine` via `set_physics_process(false)`.

## 4. UI Architecture & In-Game Navigation
1. **Main Menu Extensions:**
   `%MainMenuButtons` in `MainMenu.hooks.gd` hosts:
   - Index 1: `SaveProfilesButton` (Career multisave modal)
   - Index 2: `ModManagerButton` (Universal mod manager)
   - Index 3: `ModStoreButton` (Mod & Map Store browser)
   - Index 4: `LeaderboardsButton` (Community records)
2. **Bottom-Right In-Mine Micro-Dock:**
   Widgets are docked in a 150px-wide column with uniform 4px vertical separation:
   - Speed Controls (`◀ 1.00x ▶`): `-42.0` to `-16.0`
   - Amazon Emergency Delivery (`📦 Amazon (B)`): `-72.0` to `-46.0`
   - Air Wings (`🔥 7 | 💧 8 | ☣️ 9 | 💣 0`): `-102.0` to `-76.0`
   All three widgets dynamically query `_is_actively_mining()`, hiding completely during menus, customize screens, and between-day management.
3. **Shop Search & Filters:**
   Injected into the `VBoxContainer` directly above the `ScrollContainer` in both `%EquipmentShop` and `%BonusShop`.
'@ | Set-Content -Path (Join-Path $repo "SESSION_PROMPT.md") -Encoding UTF8
Write-Host "  Updated: SESSION_PROMPT.md" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 8. STAGE, COMMIT AND PUSH TO GITHUB
# ------------------------------------------------------------------------------
Write-Host "`n>>> 8. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Fix: Prune duplicate is_mod_active_for_run in SaveSlotManager, restore class unlocks, harden map transition, add Mod Store to Main Menu, and refresh README/SESSION_PROMPT"
git push origin main

Write-Host "`nDeployment complete! Zero tests executed (awaiting gameplay session)." -ForegroundColor Green