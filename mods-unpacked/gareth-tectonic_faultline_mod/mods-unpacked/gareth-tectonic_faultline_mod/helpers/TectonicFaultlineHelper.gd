class_name TectonicFaultlineHelper
extends RefCounted

const FAULTLINE_LEVEL_ID: int = 102

func ensure_level_registered() -> void:
	var lvl_mgr = Gvars.level_manager
	if not lvl_mgr:
		return
	
	if not lvl_mgr.all_levels.has(FAULTLINE_LEVEL_ID):
		var custom_level = GameLevel.new()
		custom_level.level_name = "Tectonic Faultline"
		custom_level.level = FAULTLINE_LEVEL_ID
		custom_level.mining_scene_path = "res://scenes/Stages/MineRegion.tscn"
		custom_level.level_description = "Unstable geothermal faultline.\nBrittle volcanic basalt and superheated magma strata.\nVent high-pressure Magma Siphons for thermal tech."
		custom_level.level_difficulty = GameLevel.Difficulty.HARD
		custom_level.unlock_description = ""
		
		var img = Image.load_from_file("res://mods-unpacked/gareth-tectonic_faultline_mod/assets/tectonic_faultline_card.png")
		if img:
			custom_level.level_image = ImageTexture.create_from_image(img)
		
		lvl_mgr.all_levels[FAULTLINE_LEVEL_ID] = {
			"level": custom_level,
			"is_unlocked": true
		}

func calculate_faultline_tier(pos: Vector2i) -> int:
	var depth: float = float(pos.y)
	if depth < 0.0:
		return -2
	
	# Dynamic jagged faultline shifts
	var wave: float = sin(float(pos.x) * 0.16) * 7.0 + cos(float(pos.x) * 0.05) * 4.0
	var effective_y: float = depth + wave
	
	if effective_y < 15.0:
		return 1  # Volcanic crust (Hard Clay/Stone)
	elif effective_y < 45.0:
		return 3  # Fractured Basalt (Hard Stone)
	elif effective_y < 120.0:
		return 8  # Shallow Magma Chamber (Hard Fire)
	elif effective_y < 300.0:
		return 9  # Molten Core (Hard Fire / Superheated)
	elif effective_y < 600.0:
		return 12 # Vitrified Obsidian (Hard Dark)
	elif effective_y < 950.0:
		return 14 # Mantle Transition (Hard Orange)
	else:
		return 18 # Abyssal Core (Hard Dark Brown)

func tag_seismic_seams(chunk: Node) -> void:
	var seams: Dictionary = {}
	var total_cells: int = chunk.chunk_size * chunk.chunk_size
	for idx in range(total_cells):
		var tile_id = chunk.tiles[idx]
		if tile_id != chunk.Tiles.EMPTY and chunk.TILE_PROPERTIES[tile_id]["breakable"]:
			# 4.5% chance of brittle seismic stress point
			if randf() < 0.045:
				seams[idx] = true
	chunk.set_meta("seismic_seams", seams)

func handle_tile_destroyed(chunk: Node, idx: int, tile_properties: Dictionary = {}) -> void:
	if chunk.has_meta("seismic_seams"):
		var seams: Dictionary = chunk.get_meta("seismic_seams")
		if seams.has(idx):
			seams.erase(idx)
			trigger_micro_tremor(chunk, idx)
	
	if tile_properties and tile_properties.get("loot", "none") != "none":
		var global_pos = chunk.to_global(chunk.map_to_local(chunk.array_to_pos(idx)))
		if randf() < 0.40:
			Bus.drop_loot.emit(global_pos + Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0)), "res://resources/Items/Coal.tres", randi_range(2, 5))

func trigger_micro_tremor(chunk: Node, idx: int) -> void:
	var world_center: Vector2 = chunk.to_global(chunk.map_to_local(chunk.array_to_pos(idx)))
	var manager = chunk.get_parent()
	if manager and manager.has_method("damageTile"):
		# Shatter adjacent brittle rock along the fault line
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				if dx != 0 or dy != 0:
					manager.damageTile(world_center + Vector2(dx * 16.0, dy * 16.0), 250)

func spawn_magma_siphons(chunk: Node, current_locs: Array[Vector2i]) -> Array[Vector2i]:
	if randf() > 0.55:
		return current_locs
	
	if "chunk_pos" in chunk and chunk.chunk_pos.y < 1:
		return current_locs
	
	var width: int = 3
	var height: int = 3
	var start_tile: Vector2i = Vector2i(
		randi_range(0, chunk.chunk_size - width),
		randi_range(0, chunk.chunk_size - height)
	)
	
	var global_cell: Vector2i = Vector2i(chunk.to_global(chunk.map_to_local(start_tile)) / 16.0)
	if global_cell.y < 16:
		return current_locs
	
	var pod_tier: int = calculate_faultline_tier(global_cell)
	var wall_tile: int = chunk.chest_block_from_level(pod_tier)
	if wall_tile == chunk.Tiles.EMPTY:
		wall_tile = chunk.Tiles.HARD_FIRE
	
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
				var siphon_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/entities/MagmaSiphon.gd")
				if siphon_script:
					var siphon = siphon_script.new()
					siphon.position = chunk.map_to_local(Vector2i(x, y))
					chunk.add_child.call_deferred(siphon)
			else:
				chunk.tiles[c_idx] = wall_tile
				chunk.build_tile(c_idx)
	
	return current_locs
