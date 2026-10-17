cls

# ==============================================================================
# Coal LLC - Physical Employee Spawning, Pod Fix & Weapon Restriction
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

Write-Host ">>> 1. Updating entities/CryoPod.gd (Player-only collision & live employee spawn)..." -ForegroundColor Cyan
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
	shape.radius = 14.0
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

func _on_body_entered(body: Node2D) -> void:
	# STRICT: Ignore all static tile blocks, terrain, and debris
	if not (body.name == "Player" or body.is_in_group("player")):
		return
	if not looted:
		in_range = true
		if Bus and Bus.has_signal("ShowInputIndicator"):
			Bus.ShowInputIndicator.emit("interact", true, self)

func _on_body_exited(body: Node2D) -> void:
	if not (body.name == "Player" or body.is_in_group("player")):
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
	
	# 1. Visual state confirmation
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
	
	# 3. Choose employee & register level promotion
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
	
	# 4. Physically instantiate the rescued worker right here in MineRegion
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
	
	# 5. Passive selection card bonus
	var depth_mult: float = maxf(2.0, minf(6.0, 2.0 + abs(global_position.y) / 250.0))
	if Bus and Bus.has_signal("choose_passive"):
		Bus.choose_passive.emit(depth_mult)
'@ | Set-Content -Path "$innerDir\entities\CryoPod.gd" -Encoding UTF8
Write-Host "Updated: $innerDir\entities\CryoPod.gd" -ForegroundColor Green

Write-Host ">>> 2. Writing extensions/scripts/Chest.hooks.gd (weapons filter in chests)..." -ForegroundColor Cyan
@'
extends Object

func roll_loot(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	if Gvars.level == 101:
		var chest = chain.reference_object
		if chest and chest.loot:
			var itype: String = str(chest.loot.itemType).to_lower()
			var iid: String = str(chest.loot.itemID).to_lower()
			# Replace non-pickaxe weapon scrolls with passive upgrades
			if itype == "scroll" and not iid.contains("pickaxe"):
				var pass_res = load("res://resources/Items/power_ups/PassiveUpgrade.tres")
				if pass_res:
					chest.loot = pass_res.duplicate()
					chest.loot_count = 1
			elif itype not in ["gem", "ore", "pickaxe", "passive_upgrade", "scroll"]:
				var pass_res = load("res://resources/Items/power_ups/PassiveUpgrade.tres")
				if pass_res:
					chest.loot = pass_res.duplicate()
					chest.loot_count = 1
'@ | Set-Content -Path "$innerDir\extensions\scripts\Chest.hooks.gd" -Encoding UTF8
Write-Host "Created: $innerDir\extensions\scripts\Chest.hooks.gd" -ForegroundColor Green

Write-Host ">>> 3. Updating extensions/scenes/Stages/management_screen.hooks.gd (pickaxes only)..." -ForegroundColor Cyan
@'
extends Object

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	if Gvars.level == 101:
		var ms = chain.reference_object
		if ms and "equipment_shop" in ms and ms.equipment_shop:
			var allowed := ["pickaxe", "item_filter", "increase_stack_size", "ladder", "whistle", "collector_whistle", "mining_whistle"]
			for card in ms.equipment_shop.get_children():
				if "item" in card and card.item:
					var itype: String = str(card.item.itemType).to_lower()
					if not allowed.has(itype):
						card.visible = false
'@ | Set-Content -Path "$innerDir\extensions\scenes\Stages\management_screen.hooks.gd" -Encoding UTF8
Write-Host "Updated: $innerDir\extensions\scenes\Stages\management_screen.hooks.gd" -ForegroundColor Green

Write-Host ">>> 4. Updating LostExpeditionHelper.gd (surface check & stratum wall matching)..." -ForegroundColor Cyan
@'
class_name LostExpeditionHelper
extends RefCounted

const EXPEDITION_LEVEL_ID: int = 101

func ensure_level_registered() -> void:
	var lvl_mgr = Gvars.level_manager
	if not lvl_mgr:
		return
	
	if not lvl_mgr.all_levels.has(EXPEDITION_LEVEL_ID):
		var custom_level = GameLevel.new()
		custom_level.level_name = "Lost Expedition"
		custom_level.level = EXPEDITION_LEVEL_ID
		custom_level.mining_scene_path = "res://scenes/Stages/MineRegion.tscn"
		custom_level.level_description = "Abandoned subterranean expedition.\nDeep strata riddled with volatile unexploded ordnance.\nCryo-shelters contain trapped mining personnel."
		custom_level.level_difficulty = GameLevel.Difficulty.HARD
		custom_level.unlock_description = ""
		
		var img = Image.load_from_file("res://mods-unpacked/gareth-lost_expedition_mod/assets/lost_expedition_card.png")
		if img:
			custom_level.level_image = ImageTexture.create_from_image(img)
		
		lvl_mgr.all_levels[EXPEDITION_LEVEL_ID] = {
			"level": custom_level,
			"is_unlocked": true
		}

func calculate_tier(pos: Vector2i) -> int:
	var depth: float = float(pos.y)
	if depth < 0.0:
		return -2
	
	var wave: float = sin(float(pos.x) * 0.12) * 5.0
	var effective_y: float = depth + wave
	
	if effective_y < 12.0:
		return 0
	elif effective_y < 35.0:
		return 1
	elif effective_y < 70.0:
		return 2
	elif effective_y < 120.0:
		return 3
	elif effective_y < 200.0:
		return 4
	elif effective_y < 300.0:
		return 5
	elif effective_y < 450.0:
		return 6
	elif effective_y < 600.0:
		return 7
	elif effective_y < 750.0:
		return 8
	elif effective_y < 900.0:
		return 9
	elif effective_y < 1050.0:
		return 10
	elif effective_y < 1200.0:
		return 11
	else:
		return 12

func tag_uxo_tiles(chunk: Node) -> void:
	var uxo: Dictionary = {}
	var total_cells: int = chunk.chunk_size * chunk.chunk_size
	for idx in range(total_cells):
		var tile_id = chunk.tiles[idx]
		if tile_id != chunk.Tiles.EMPTY and chunk.TILE_PROPERTIES[tile_id]["breakable"]:
			if randf() < 0.035:
				uxo[idx] = true
	chunk.set_meta("expedition_uxo", uxo)

func handle_tile_destroyed(chunk: Node, idx: int, tile_properties: Dictionary = {}) -> void:
	if chunk.has_meta("expedition_uxo"):
		var uxo: Dictionary = chunk.get_meta("expedition_uxo")
		if uxo.has(idx):
			uxo.erase(idx)
			detonate_uxo(chunk, idx)
	
	if tile_properties and tile_properties.get("loot", "none") != "none":
		var global_pos = chunk.to_global(chunk.map_to_local(chunk.array_to_pos(idx)))
		if randf() < 0.35:
			var bonus_count: int = randi_range(2, 6)
			Bus.drop_loot.emit(global_pos + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0)), "res://resources/Items/Coal.tres", bonus_count)
		if randf() < 0.15:
			var salvage_cash: float = randf_range(250.0, 1500.0)
			Gvars.CashCount += salvage_cash

func detonate_uxo(chunk: Node, idx: int) -> void:
	var local_pos: Vector2 = chunk.map_to_local(chunk.array_to_pos(idx))
	var world_center: Vector2 = chunk.to_global(local_pos)
	var manager = chunk.get_parent()
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			var offset_world: Vector2 = world_center + Vector2(dx * 16.0, dy * 16.0)
			if manager and manager.has_method("damageTile"):
				manager.damageTile(offset_world, 450)

func spawn_cryo_pods(chunk: Node, current_locs: Array[Vector2i]) -> Array[Vector2i]:
	if randf() > 0.60:
		return current_locs
	
	# Strict: Surface chunks (y <= 0) must never contain subterranean vaults
	if "chunk_pos" in chunk and chunk.chunk_pos.y < 1:
		return current_locs
	
	var width: int = 3
	var height: int = 3
	var start_tile: Vector2i = Vector2i(
		randi_range(0, chunk.chunk_size - width),
		randi_range(0, chunk.chunk_size - height)
	)
	
	var local_start: Vector2 = chunk.map_to_local(start_tile)
	var world_start: Vector2 = chunk.to_global(local_start)
	var global_cell: Vector2i = Vector2i(world_start / 16.0)
	if global_cell.y < 16:
		return current_locs
	
	# Vault walls dynamically match the hardness of the surrounding stratum
	var pod_tier: int = calculate_tier(global_cell)
	var wall_tile: int = chunk.chest_block_from_level(pod_tier)
	if wall_tile == chunk.Tiles.EMPTY:
		wall_tile = chunk.Tiles.HARD_CLAY
	
	for n in range(5):
		if start_tile in current_locs:
			start_tile = Vector2i(
				randi_range(0, chunk.chunk_size - width),
				randi_range(0, chunk.chunk_size - height)
			)
	
	for x in range(start_tile.x - width, start_tile.x + width):
		for y in range(start_tile.y - height, start_tile.y + height):
			current_locs.append(Vector2i(x, y))
	
	for x in range(start_tile.x, start_tile.x + width):
		for y in range(start_tile.y, start_tile.y + height):
			var c_idx: int = chunk.pos_to_array(Vector2i(x, y))
			if (x == start_tile.x + 1) and (y == start_tile.y + 1):
				chunk.tiles[c_idx] = chunk.Tiles.EMPTY
				chunk.build_tile(c_idx)
				var pod_script = load("res://mods-unpacked/gareth-lost_expedition_mod/entities/CryoPod.gd")
				if pod_script:
					var pod = pod_script.new()
					pod.position = chunk.map_to_local(Vector2i(x, y))
					chunk.add_child.call_deferred(pod)
			else:
				chunk.tiles[c_idx] = wall_tile
				chunk.build_tile(c_idx)
	
	return current_locs
'@ | Set-Content -Path "$innerDir\helpers\LostExpeditionHelper.gd" -Encoding UTF8
Write-Host "Updated: $innerDir\helpers\LostExpeditionHelper.gd" -ForegroundColor Green

Write-Host ">>> 5. Updating mod_main.gd with Chest.hooks.gd registration..." -ForegroundColor Cyan
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
	ModLoaderMod.install_script_hooks(
		"res://scenes/Stages/management_screen.gd",
		mod_dir_path.path_join("extensions/scenes/Stages/management_screen.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/Chest.gd",
		mod_dir_path.path_join("extensions/scripts/Chest.hooks.gd")
	)

func _ready() -> void:
	var helper_script = load("res://mods-unpacked/gareth-lost_expedition_mod/helpers/LostExpeditionHelper.gd")
	if helper_script:
		var helper = helper_script.new()
		helper.ensure_level_registered()
	ModLoaderLog.info("Lost Expedition Custom Map Mod (ID 101) online!", MOD_DIR)
'@ | Set-Content -Path "$innerDir\mod_main.gd" -Encoding UTF8
Write-Host "Updated: $innerDir\mod_main.gd" -ForegroundColor Green

Write-Host ">>> 6. Flushing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 7. Repackaging mod archive for Steam..." -ForegroundColor Cyan
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

Write-Host ">>> 8. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Fix pod collision overlap, spawn physical workers from pods, restrict weapons in shop and chests"
git push origin main

Write-Host "`nAll patches deployed cleanly! Restart Coal LLC to test." -ForegroundColor Green