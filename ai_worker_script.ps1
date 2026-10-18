cls

# ==============================================================================
# Coal LLC - Elemental Passives & Tick Speed for Tectonic Faultline (Map 102)
# ==============================================================================

$repo          = "C:\Dev\coal-llc-mods"
$steamRoot     = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods     = "$steamRoot\mods"
$hookZip       = "$steamRoot\mod-hooks.zip"

$tfModName     = "gareth-tectonic_faultline_mod"
$tfOuterDir    = "$repo\mods-unpacked\$tfModName"
$tfInnerDir    = "$tfOuterDir\mods-unpacked\$tfModName"
$tfZipPath     = "$steamMods\$tfModName.zip"
$tfHelperPath  = "$tfInnerDir\helpers\TectonicFaultlineHelper.gd"
$tfChunkHook   = "$tfInnerDir\extensions\scenes\tilemaps\tile_map_chunk.hooks.gd"

$mmModName     = "gareth-mod_manager_mod"
$mmOuterDir    = "$repo\mods-unpacked\$mmModName"
$mmInnerDir    = "$mmOuterDir\mods-unpacked\$mmModName"
$mmZipPath     = "$steamMods\$mmModName.zip"
$mmPassHook    = "$mmInnerDir\extensions\scenes\Interfaces\in_game\choose_passive.hooks.gd"

Set-Location $repo

Write-Host ">>> 1. Updating gareth-mod_manager_mod choose_passive.hooks.gd..." -ForegroundColor Cyan
@'
extends Object

const CUSTOM_PASSIVES: Dictionary = {
	"sword_damage": 0.10,
	"sword_speed": 0.10,
	"sword_range": 0.15,
	"fracker_pulse_damage": 0.10,
	"fracker_seam_resonance": 0.15,
	"fracker_fire_rate": 0.10,
	"ball_blast_damage": 0.10,
	"ball_blast_radius": 0.15,
	"ball_fire_rate": 0.10,
	"exec_damage": 0.10,
	"exec_fire_rate": 0.10,
	"exec_bounty": 0.15,
	"jedi_saber_damage": 0.10,
	"jedi_swing_rate": 0.10,
	"jedi_cleave_reach": 0.15,
	"sinclair_melt_damage": 0.10,
	"sinclair_beam_width": 0.15,
	"sinclair_spectrum_ticks": 0.10,
	"void_implosion_damage": 0.10,
	"void_pull_radius": 0.15,
	"void_event_horizon": 0.10,
	"dread_shell_damage": 0.10,
	"dread_fire_rate": 0.10,
	"dread_impact_radius": 0.15,
	"chrono_tick_rate": 0.10,
	"chrono_shockwave_damage": 0.15,
	"chrono_stasis_duration": 0.10,
	"elemental_tick_rate": 0.10
}

func _ready(chain: ModLoaderHookChain) -> void:
	var cp = chain.reference_object as ChoosePassive
	if not cp:
		chain.execute_next([])
		return

	cp.process_mode = Node.PROCESS_MODE_ALWAYS
	cp.get_tree().paused = true
	cp.live = true

	var local_passive_map: Dictionary = cp.PASSIVE_MAP.duplicate(true)
	local_passive_map["sword"] = ["sword_damage", "sword_speed", "sword_range"]
	local_passive_map["fracker"] = ["fracker_pulse_damage", "fracker_seam_resonance", "fracker_fire_rate"]
	local_passive_map["bouncing_ball"] = ["ball_blast_damage", "ball_blast_radius", "ball_fire_rate"]
	local_passive_map["debt_executioner"] = ["exec_damage", "exec_fire_rate", "exec_bounty"]
	local_passive_map["jedi_saber"] = ["jedi_saber_damage", "jedi_swing_rate", "jedi_cleave_reach"]
	local_passive_map["sinclair_prism"] = ["sinclair_melt_damage", "sinclair_beam_width", "sinclair_spectrum_ticks"]
	local_passive_map["void_core"] = ["void_implosion_damage", "void_pull_radius", "void_event_horizon"]
	local_passive_map["dread_cannon"] = ["dread_shell_damage", "dread_fire_rate", "dread_impact_radius"]
	local_passive_map["chrono_drill"] = ["chrono_tick_rate", "chrono_shockwave_damage", "chrono_stasis_duration"]

	var data := {"unlocked_passives": []}
	if Gvars and Gvars.profession:
		data = Gvars.profession._profession_effect(data)

	var all_keys: Array = cp.ALL_PASSIVES.keys().duplicate()
	for k in CUSTOM_PASSIVES.keys():
		if not all_keys.has(k):
			all_keys.append(k)

	for up in data.get("unlocked_passives", []):
		if not all_keys.has(up):
			all_keys.append(up)
	cp.x = all_keys

	var player_inventory: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
	var choice_options: Array[String] = []
	var leftover_options: Array = cp.x.duplicate()

	# 1. Standard inventory-gated weapon passives
	if player_inventory and player_inventory.items:
		for inv_item in player_inventory.items:
			if inv_item and inv_item.item:
				for p in local_passive_map.get(inv_item.item.itemType, []):
					if p in leftover_options and not (p in choice_options):
						choice_options.append(p)

	# 2. Tectonic Faultline Exclusive Injection (Map 102 only)
	var is_faultline: bool = false
	if Gvars:
		if ("level" in Gvars and Gvars.level == 102) or ("chosen_level" in Gvars and Gvars.chosen_level == 102) or ("current_level" in Gvars and Gvars.current_level == 102):
			is_faultline = true

	if is_faultline:
		var faultline_perks: Array[String] = ["fire_damage", "wet_damage", "poison_damage", "elemental_tick_rate"]
		for fp in faultline_perks:
			if fp in leftover_options and not (fp in choice_options):
				choice_options.append(fp)

	var choices: Array[String] = []
	var c1: String = choice_options.pick_random() if choice_options.size() > 0 else leftover_options.pick_random()
	choices.append(c1)
	choice_options.erase(c1)
	leftover_options.erase(c1)

	var c2: String = choice_options.pick_random() if choice_options.size() > 0 else leftover_options.pick_random()
	choices.append(c2)
	choice_options.erase(c2)
	leftover_options.erase(c2)

	var mob_opts: Array = ["player_sprint_speed", "player_jump_velocity", "player_climb_speed"]
	var valid_mob: Array = []
	for m in mob_opts:
		if leftover_options.has(m):
			valid_mob.append(m)
	var c3: String = valid_mob.pick_random() if valid_mob.size() > 0 else leftover_options.pick_random()
	choices.append(c3)

	cp.choose_between = choices
	cp.choose_between.shuffle()

	var buttons = [cp.button, cp.button_2, cp.button_3]
	for i in range(3):
		var p_key: String = cp.choose_between[i]
		var base_rate: float = 0.05
		if CUSTOM_PASSIVES.has(p_key):
			base_rate = CUSTOM_PASSIVES[p_key]
		elif cp.ALL_PASSIVES.has(p_key):
			base_rate = cp.ALL_PASSIVES[p_key]
		buttons[i].text = "Increase " + p_key.replace("_", " ").capitalize() + " +" + str(cp.multiplier * (base_rate * 100)) + "%"

	var reroll_btn = cp.get_node_or_null("%Reroll")
	if not reroll_btn and "reroll" in cp:
		reroll_btn = cp.reroll
	if reroll_btn and not reroll_btn.pressed.is_connected(cp._on_reroll_pressed):
		reroll_btn.pressed.connect(cp._on_reroll_pressed)

func _on_button_pressed(chain: ModLoaderHookChain) -> void:
	_handle_button_selection(chain, 0)

func _on_button_2_pressed(chain: ModLoaderHookChain) -> void:
	_handle_button_selection(chain, 1)

func _on_button_3_pressed(chain: ModLoaderHookChain) -> void:
	_handle_button_selection(chain, 2)

func _handle_button_selection(chain: ModLoaderHookChain, idx: int) -> void:
	var cp = chain.reference_object as ChoosePassive
	if not cp or not cp.live:
		return

	if idx >= cp.choose_between.size():
		chain.execute_next([])
		return

	var choice: String = cp.choose_between[idx]
	if CUSTOM_PASSIVES.has(choice):
		cp.live = false
		var base_rate: float = CUSTOM_PASSIVES[choice]
		var delta_amount: float = cp.multiplier * base_rate
		_apply_custom_stat(choice, delta_amount)
		cp.get_tree().paused = false
		cp.queue_free()
	else:
		chain.execute_next([])

func _apply_custom_stat(stat_name: String, amount: float) -> void:
	if not Gvars:
		return
	if not ("custom_passives" in Gvars) or (Gvars.custom_passives == null):
		Gvars.set("custom_passives", {})
	if not Gvars.custom_passives.has(stat_name):
		Gvars.custom_passives[stat_name] = 0.0
	Gvars.custom_passives[stat_name] += amount
	ModLoaderLog.info("[Passives] Applied %s +%.2f (Total: %.2f)" % [stat_name, amount, Gvars.custom_passives[stat_name]], "gareth-mod_manager_mod")
'@ | Set-Content -Path $mmPassHook -Encoding UTF8
Write-Host "Updated: $mmPassHook" -ForegroundColor Green

Write-Host "`n>>> 2. Updating TectonicFaultlineHelper.gd with tick bonus lookup..." -ForegroundColor Cyan
@'
class_name TectonicFaultlineHelper
extends RefCounted

const FAULTLINE_LEVEL_ID: int = 102
const CHUNK_SIZE: int = 16

static func is_faultline_level() -> bool:
	if Gvars:
		if "level" in Gvars and Gvars.level == FAULTLINE_LEVEL_ID:
			return true
		if "chosen_level" in Gvars and Gvars.chosen_level == FAULTLINE_LEVEL_ID:
			return true
		if "current_level" in Gvars and Gvars.current_level == FAULTLINE_LEVEL_ID:
			return true
	return false

static func get_elemental_tick_bonus() -> float:
	if Gvars and ("custom_passives" in Gvars) and (Gvars.custom_passives is Dictionary):
		return float(Gvars.custom_passives.get("elemental_tick_rate", 0.0))
	return 0.0

func ensure_level_registered() -> void:
	register_faultline_level()

static func register_faultline_level() -> void:
	if not Gvars:
		return
	
	if "level_manager" in Gvars and Gvars.level_manager and ("all_levels" in Gvars.level_manager):
		var lvl_mgr = Gvars.level_manager
		if not lvl_mgr.all_levels.has(FAULTLINE_LEVEL_ID):
			var custom_level = GameLevel.new()
			custom_level.level_name = "Tectonic Faultline"
			custom_level.level = FAULTLINE_LEVEL_ID
			custom_level.mining_scene_path = "res://scenes/Stages/MineRegion.tscn"
			custom_level.level_description = "Seismic faultline with superheated vents, magma fissures, and elemental chambers.\n\nElemental pods contain explosive fluids and geothermal updrafts."
			custom_level.level_difficulty = GameLevel.Difficulty.HARD
			custom_level.unlock_description = ""
			
			var preview_path = "res://mods-unpacked/gareth-tectonic_faultline_mod/assets/tectonic_preview.png"
			var bytes = FileAccess.get_file_as_bytes(preview_path)
			if bytes and bytes.size() > 0:
				var f_img = Image.new()
				if f_img.load_png_from_buffer(bytes) == OK:
					custom_level.level_image = ImageTexture.create_from_image(f_img)
			
			lvl_mgr.all_levels[FAULTLINE_LEVEL_ID] = {
				"level": custom_level,
				"is_unlocked": true
			}
	
	if "level_info" in Gvars and Gvars.level_info is Dictionary:
		if not Gvars.level_info.has(FAULTLINE_LEVEL_ID):
			Gvars.level_info[FAULTLINE_LEVEL_ID] = {
				"name": "Tectonic Faultline",
				"description": "Seismic faultline with superheated vents, magma fissures, and elemental chambers.",
				"depth": 1400,
				"cost": 0,
				"unlocked": true
			}

static func calculate_faultline_tier(pos: Vector2i) -> int:
	var y_tile: int = pos.y
	if y_tile < 0:
		return -2
	elif y_tile < 24:
		return 1
	elif y_tile < 48:
		return 2
	elif y_tile < 80:
		return 3
	elif y_tile < 120:
		return 4
	elif y_tile < 170:
		return 5
	elif y_tile < 230:
		return 6
	elif y_tile < 300:
		return 7
	else:
		return min(12, 8 + int((y_tile - 300) / 80))

static func pick_faultline_block(chunk: Node, global_cell: Vector2i, noise: FastNoiseLite) -> int:
	if global_cell.y <= 0:
		return chunk.Tiles.EMPTY
	
	var tier: int = calculate_faultline_tier(global_cell)
	if tier < 0:
		return chunk.Tiles.EMPTY
	
	var rift_noise: float = abs(noise.get_noise_2d(float(global_cell.x) * 4.5, float(global_cell.y) * 1.2))
	if rift_noise < 0.09 and global_cell.y > 10:
		return chunk.Tiles.EMPTY
	
	var fissure_noise: float = noise.get_noise_2d(float(global_cell.x) * 2.8 + 50.0, float(global_cell.y) * 2.8)
	if fissure_noise > 0.42 and global_cell.y > 18:
		return chunk.Tiles.HARD_FIRE
	
	var base_tile: int = chunk.chest_block_from_level(tier)
	if base_tile == chunk.Tiles.EMPTY:
		base_tile = chunk.Tiles.HARD_FIRE
	return base_tile

static func generate_faultline_strata(chunk: Node, noise: FastNoiseLite) -> void:
	if not ("tiles" in chunk) or not ("chunk_size" in chunk):
		return
	
	for x in range(chunk.chunk_size):
		for y in range(chunk.chunk_size):
			var local_pos = Vector2i(x, y)
			var global_posi: Vector2i = Vector2i(chunk.to_global(chunk.map_to_local(local_pos)) / 16.0)
			
			if global_posi.y > 3:
				var idx: int = chunk.pos_to_array(local_pos) if chunk.has_method("pos_to_array") else (x + y * chunk.chunk_size)
				if idx >= 0 and idx < chunk.tiles.size():
					if chunk.tiles[idx] != chunk.Tiles.EMPTY:
						var new_block = pick_faultline_block(chunk, global_posi, noise)
						chunk.tiles[idx] = new_block
						chunk.build_tile(idx)

static func spawn_magma_siphons(chunk: Node, current_locs: Array[Vector2i]) -> Array[Vector2i]:
	if "chunk_pos" in chunk and chunk.chunk_pos.y < 1:
		return current_locs
	
	var pods_to_spawn: int = 3
	var elements: Array[String] = ["fire", "water", "poison"]
	elements.shuffle()
	
	var width: int = 3
	var height: int = 3
	
	for p_idx in range(pods_to_spawn):
		var found_spot: bool = false
		var start_tile: Vector2i = Vector2i.ZERO
		
		for attempt in range(12):
			var candidate = Vector2i(
				randi_range(1, chunk.chunk_size - width - 1),
				randi_range(1, chunk.chunk_size - height - 1)
			)
			
			var overlaps: bool = false
			for ox in range(candidate.x - 1, candidate.x + width + 1):
				for oy in range(candidate.y - 1, candidate.y + height + 1):
					if Vector2i(ox, oy) in current_locs:
						overlaps = true
						break
				if overlaps:
					break
			
			if not overlaps:
				start_tile = candidate
				found_spot = true
				break
		
		if not found_spot:
			continue
		
		var local_start: Vector2 = chunk.map_to_local(start_tile)
		var world_start: Vector2 = chunk.to_global(local_start)
		var global_cell: Vector2i = Vector2i(world_start / 16.0)
		if global_cell.y < 10:
			continue
		
		var pod_tier: int = calculate_faultline_tier(global_cell)
		var wall_tier: int = min(max(1, pod_tier + 2), 12)
		var wall_tile: int = chunk.chest_block_from_level(wall_tier)
		if wall_tile == chunk.Tiles.EMPTY:
			wall_tile = chunk.Tiles.HARD_DARK if global_cell.y > 40 else chunk.Tiles.HARD_FIRE
		
		for x in range(start_tile.x - 1, start_tile.x + width + 1):
			for y in range(start_tile.y - 1, start_tile.y + height + 1):
				current_locs.append(Vector2i(x, y))
		
		for x in range(start_tile.x, start_tile.x + width):
			for y in range(start_tile.y, start_tile.y + height):
				var local_coord = Vector2i(x, y)
				var c_idx: int = chunk.pos_to_array(local_coord)
				var is_wall = (x == start_tile.x or x == start_tile.x + width - 1 or y == start_tile.y or y == start_tile.y + height - 1)
				
				if is_wall:
					chunk.tiles[c_idx] = wall_tile
					chunk.build_tile(c_idx)
				else:
					chunk.tiles[c_idx] = chunk.Tiles.EMPTY
					chunk.build_tile(c_idx)
		
		var SiphonScene = load("res://mods-unpacked/gareth-tectonic_faultline_mod/entities/MagmaSiphon.gd")
		if SiphonScene:
			var siphon = SiphonScene.new()
			var center_tile = Vector2i(start_tile.x + 1, start_tile.y + 1)
			siphon.position = chunk.map_to_local(center_tile)
			siphon.set_element(elements[p_idx % elements.size()])
			chunk.add_child(siphon)
	
	return current_locs
'@ | Set-Content -Path $tfHelperPath -Encoding UTF8
Write-Host "Updated: $tfHelperPath" -ForegroundColor Green

Write-Host "`n>>> 3. Updating tile_map_chunk.hooks.gd with apply_tile_effects acceleration..." -ForegroundColor Cyan
@'
extends Object

func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	if Gvars.level == 102:
		var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
		if helper_script:
			return helper_script.calculate_faultline_tier(pos)
	return chain.execute_next([pos])

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	chain.execute_next([noise])
	if Gvars.level == 102:
		var chunk = chain.reference_object
		if chunk and "chunk_pos" in chunk and chunk.chunk_pos.y >= 0:
			var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
			if helper_script:
				var fnl = FastNoiseLite.new()
				fnl.seed = Gvars.map_seed if ("map_seed" in Gvars) else 1337
				fnl.frequency = 0.035
				helper_script.generate_faultline_strata(chunk, fnl)

func generate_chests(chain: ModLoaderHookChain, current_block_chest_locations: Array[Vector2i]) -> Array[Vector2i]:
	var locs: Array[Vector2i] = chain.execute_next([current_block_chest_locations])
	if Gvars.level == 102:
		var chunk = chain.reference_object
		if chunk:
			var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
			if helper_script:
				locs = helper_script.spawn_magma_siphons(chunk, locs)
	return locs

func destroy_tile(chain: ModLoaderHookChain, idx: int, tile_properties: Dictionary) -> void:
	chain.execute_next([idx, tile_properties])

func apply_tile_effects(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var chunk = chain.reference_object
	if chunk and ("level" in Gvars) and Gvars.level == 102:
		var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
		if helper_script:
			var tick_bonus: float = helper_script.get_elemental_tick_bonus()
			if tick_bonus > 0.0:
				var acc: float = chunk.get_meta("elem_tick_acc", 0.0) + tick_bonus
				while acc >= 1.0:
					acc -= 1.0
					if chunk.has_method("poisons_loop"):
						chunk.poisons_loop()
					if chunk.has_method("burns_loop"):
						chunk.burns_loop()
				chunk.set_meta("elem_tick_acc", acc)
'@ | Set-Content -Path $tfChunkHook -Encoding UTF8
Write-Host "Updated: $tfChunkHook" -ForegroundColor Green

Write-Host "`n>>> 4. Flushing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 5. Repackaging gareth-tectonic_faultline_mod.zip..." -ForegroundColor Cyan
if (Test-Path $tfZipPath) { Remove-Item -Path $tfZipPath -Force }
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$stream1  = [System.IO.File]::Open($tfZipPath, [System.IO.FileMode]::CreateNew)
$archive1 = New-Object System.IO.Compression.ZipArchive($stream1, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $tfOuterDir -Recurse -File)) {
    $entryName = $f.FullName.Substring($tfOuterDir.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive1, $f.FullName, $entryName) | Out-Null
}
$archive1.Dispose()
$stream1.Dispose()
Write-Host "Packed: $tfZipPath" -ForegroundColor Green

Write-Host ">>> 6. Repackaging gareth-mod_manager_mod.zip..." -ForegroundColor Cyan
if (Test-Path $mmZipPath) { Remove-Item -Path $mmZipPath -Force }
$stream2  = [System.IO.File]::Open($mmZipPath, [System.IO.FileMode]::CreateNew)
$archive2 = New-Object System.IO.Compression.ZipArchive($stream2, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $mmOuterDir -Recurse -File)) {
    $entryName = $f.FullName.Substring($mmOuterDir.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive2, $f.FullName, $entryName) | Out-Null
}
$archive2.Dispose()
$stream2.Dispose()
Write-Host "Packed: $mmZipPath" -ForegroundColor Green

Write-Host ">>> 7. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Add Elemental Tick Rate perk and map-gated elemental bonuses (Fire, Water, Poison) to Tectonic Faultline"
git push origin main

Write-Host "`nDeploy complete! Launch Coal LLC to test." -ForegroundColor Green