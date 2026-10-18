class_name TectonicFaultlineHelper
extends RefCounted

const FAULTLINE_LEVEL_ID: int = 102
const CHUNK_SIZE: int = 16

static func is_faultline_level() -> bool:
	if Gvars and "chosen_level" in Gvars and Gvars.chosen_level == FAULTLINE_LEVEL_ID:
		return true
	if Gvars and "current_level" in Gvars and Gvars.current_level == FAULTLINE_LEVEL_ID:
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
			
			# Load preview texture via raw buffer to bypass Godot 4 zip filesystem restrictions
			var preview_path = "res://mods-unpacked/gareth-tectonic_faultline_mod/assets/tectonic_preview.png"
			var bytes = FileAccess.get_file_as_bytes(preview_path)
			if bytes and bytes.size() > 0:
				var img = Image.new()
				if img.load_png_from_buffer(bytes) == OK:
					custom_level.level_image = ImageTexture.create_from_image(img)
			
			if not custom_level.level_image:
				var fallback_path = "res://mods-unpacked/gareth-tectonic_faultline_mod/assets/magma_siphon_active.png"
				var fbytes = FileAccess.get_file_as_bytes(fallback_path)
				if fbytes and fbytes.size() > 0:
					var fimg = Image.new()
					if fimg.load_png_from_buffer(fbytes) == OK:
						custom_level.level_image = ImageTexture.create_from_image(fimg)
			
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
	
	if "level_unlocked" in Gvars and Gvars.level_unlocked is Dictionary:
		if not Gvars.level_unlocked.has(FAULTLINE_LEVEL_ID):
			Gvars.level_unlocked[FAULTLINE_LEVEL_ID] = true
	
	if "level_highscores" in Gvars and Gvars.level_highscores is Dictionary:
		if not Gvars.level_highscores.has(FAULTLINE_LEVEL_ID):
			Gvars.level_highscores[FAULTLINE_LEVEL_ID] = 0
	
	if "level_scores" in Gvars and Gvars.level_scores is Dictionary:
		if not Gvars.level_scores.has(FAULTLINE_LEVEL_ID):
			Gvars.level_scores[FAULTLINE_LEVEL_ID] = 0

static func calculate_faultline_tier(global_cell: Vector2i) -> int:
	var y_tile: int = global_cell.y
	if y_tile <= 0:
		return 0
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
	# Sky and surface must remain empty air
	if global_cell.y <= 0:
		return chunk.Tiles.EMPTY
	
	var tier: int = calculate_faultline_tier(global_cell)
	
	# Primary vertical chasm slicing through strata
	var rift_noise: float = abs(noise.get_noise_2d(float(global_cell.x) * 4.5, float(global_cell.y) * 1.2))
	if rift_noise < 0.09 and global_cell.y > 10:
		return chunk.Tiles.EMPTY
	
	# Secondary magma fissures
	var fissure_noise: float = noise.get_noise_2d(float(global_cell.x) * 2.8 + 50.0, float(global_cell.y) * 2.8)
	if fissure_noise > 0.42 and global_cell.y > 18:
		return chunk.Tiles.HARD_FIRE
	
	var base_tile: int = chunk.chest_block_from_level(tier)
	if base_tile == chunk.Tiles.EMPTY:
		base_tile = chunk.Tiles.HARD_FIRE
	return base_tile

static func tag_seismic_seams(_chunk: Node) -> void:
	pass

static func spawn_magma_siphons(chunk: Node, current_locs: Array[Vector2i]) -> Array[Vector2i]:
	if randf() > 0.65:
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
	
	# Vault perimeter walls (+2 tier harder rock)
	var pod_tier: int = calculate_faultline_tier(global_cell)
	var wall_tier: int = min(pod_tier + 2, 12)
	var wall_tile: int = chunk.chest_block_from_level(wall_tier)
	if wall_tile == chunk.Tiles.EMPTY:
		if global_cell.y > 50:
			wall_tile = chunk.Tiles.HARD_DARK
		elif global_cell.y > 25:
			wall_tile = chunk.Tiles.HARD_FIRE
		else:
			wall_tile = chunk.Tiles.HARD_ORANGE
	
	for n in range(5):
		if start_tile in current_locs:
			start_tile = Vector2i(
				randi_range(0, chunk.chunk_size - width),
				randi_range(0, chunk.chunk_size - height)
			)
	
	for x in range(start_tile.x - width, start_tile.x + width):
		for y in range(start_tile.y - height, start_tile.y + height):
			current_locs.append(Vector2i(x, y))
	
	# Carve 3x3 vault and build outer perimeter walls
	for x in range(start_tile.x, start_tile.x + width):
		for y in range(start_tile.y, start_tile.y + height):
			var local_coord: Vector2i = Vector2i(x, y)
			var idx: int = -1
			if chunk.has_method("pos_to_array"):
				idx = chunk.pos_to_array(local_coord)
			else:
				idx = local_coord.x + local_coord.y * chunk.chunk_size
			
			if idx >= 0 and idx < chunk.tiles.size():
				if x == start_tile.x or x == start_tile.x + width - 1 or y == start_tile.y or y == start_tile.y + height - 1:
					chunk.tiles[idx] = wall_tile
				else:
					chunk.tiles[idx] = chunk.Tiles.EMPTY
	
	# Spawn elemental pod entity inside chamber
	var SiphonScene = load("res://mods-unpacked/gareth-tectonic_faultline_mod/entities/MagmaSiphon.gd")
	if SiphonScene:
		var siphon = SiphonScene.new()
		var center_tile: Vector2i = Vector2i(start_tile.x + 1, start_tile.y + 1)
		siphon.position = chunk.map_to_local(center_tile)
		
		var roll = randf()
		if roll < 0.40:
			siphon.set_element("fire")
		elif roll < 0.70:
			siphon.set_element("water")
		else:
			siphon.set_element("poison")
		
		chunk.add_child(siphon)
	
	return current_locs
