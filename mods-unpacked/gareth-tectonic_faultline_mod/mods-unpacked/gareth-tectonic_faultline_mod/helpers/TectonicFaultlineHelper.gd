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
	# Sky contract: return -2 for sky / surface air
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
	
	# Tripled pod generation: attempt 3 vaults per subterranean chunk
	var pods_to_spawn: int = 3
	var elements: Array[String] = ["fire", "water", "poison"]
	elements.shuffle()
	
	var width: int = 3
	var height: int = 3
	
	for p_idx in range(pods_to_spawn):
		var found_spot: bool = false
		var start_tile: Vector2i = Vector2i.ZERO
		
		# Attempt 12 random non-overlapping coordinates inside chunk
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
		
		# Vault perimeter walls (+2 tier harder rock)
		var pod_tier: int = calculate_faultline_tier(global_cell)
		var wall_tier: int = min(max(1, pod_tier + 2), 12)
		var wall_tile: int = chunk.chest_block_from_level(wall_tier)
		if wall_tile == chunk.Tiles.EMPTY:
			wall_tile = chunk.Tiles.HARD_DARK if global_cell.y > 40 else chunk.Tiles.HARD_FIRE
		
		# Reserve room footprint so chests and subsequent pods do not overlap
		for x in range(start_tile.x - 1, start_tile.x + width + 1):
			for y in range(start_tile.y - 1, start_tile.y + height + 1):
				current_locs.append(Vector2i(x, y))
		
		# Carve vault into tiles array and sync to GPU render cache via build_tile
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
		
		# Spawn elemental pod entity inside hollowed vault center
		var SiphonScene = load("res://mods-unpacked/gareth-tectonic_faultline_mod/entities/MagmaSiphon.gd")
		if SiphonScene:
			var siphon = SiphonScene.new()
			var center_tile = Vector2i(start_tile.x + 1, start_tile.y + 1)
			siphon.position = chunk.map_to_local(center_tile)
			siphon.set_element(elements[p_idx % elements.size()])
			chunk.add_child(siphon)
	
	return current_locs
