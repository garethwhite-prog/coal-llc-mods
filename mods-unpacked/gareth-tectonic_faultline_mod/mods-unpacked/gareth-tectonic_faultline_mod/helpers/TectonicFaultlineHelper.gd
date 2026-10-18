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

static func ensure_level_registered() -> void:
	if not Gvars:
		return
	
	# 1. Level info metadata
	if "level_info" in Gvars and Gvars.level_info is Dictionary:
		if not Gvars.level_info.has(FAULTLINE_LEVEL_ID):
			Gvars.level_info[FAULTLINE_LEVEL_ID] = {
				"name": "Tectonic Faultline",
				"description": "Seismic faultline with superheated vents, magma fissures, and elemental chambers.",
				"depth": 1400,
				"cost": 0,
				"unlocked": true
			}
	
	# 2. Level unlock state
	if "level_unlocked" in Gvars and Gvars.level_unlocked is Dictionary:
		if not Gvars.level_unlocked.has(FAULTLINE_LEVEL_ID):
			Gvars.level_unlocked[FAULTLINE_LEVEL_ID] = true
	
	# 3. Highscore and stat trackers
	if "level_highscores" in Gvars and Gvars.level_highscores is Dictionary:
		if not Gvars.level_highscores.has(FAULTLINE_LEVEL_ID):
			Gvars.level_highscores[FAULTLINE_LEVEL_ID] = 0
	
	if "level_scores" in Gvars and Gvars.level_scores is Dictionary:
		if not Gvars.level_scores.has(FAULTLINE_LEVEL_ID):
			Gvars.level_scores[FAULTLINE_LEVEL_ID] = 0

static func register_level_select_ui(level_select: Node) -> void:
	ensure_level_registered()
	if not level_select:
		return
	
	# Load or construct preview texture for Map 102 card
	var preview_tex: Texture2D = null
	var preview_path = "res://mods-unpacked/gareth-tectonic_faultline_mod/assets/tectonic_preview.png"
	if ResourceLoader.exists(preview_path):
		preview_tex = load(preview_path)
	elif ResourceLoader.exists("res://mods-unpacked/gareth-tectonic_faultline_mod/assets/magma_siphon_active.png"):
		preview_tex = load("res://mods-unpacked/gareth-tectonic_faultline_mod/assets/magma_siphon_active.png")
	
	# Inject into LevelSelect instance dictionaries
	if "level_images" in level_select and level_select.level_images is Dictionary:
		if not level_select.level_images.has(FAULTLINE_LEVEL_ID):
			level_select.level_images[FAULTLINE_LEVEL_ID] = preview_tex
	
	if "level_names" in level_select and level_select.level_names is Dictionary:
		if not level_select.level_names.has(FAULTLINE_LEVEL_ID):
			level_select.level_names[FAULTLINE_LEVEL_ID] = "Tectonic Faultline"
	
	if "level_descriptions" in level_select and level_select.level_descriptions is Dictionary:
		if not level_select.level_descriptions.has(FAULTLINE_LEVEL_ID):
			level_select.level_descriptions[FAULTLINE_LEVEL_ID] = "Seismic faultline with superheated vents, magma fissures, and elemental chambers.\n\nElemental pods contain explosive fluids and geothermal updrafts."
	
	if "level_scenes" in level_select and level_select.level_scenes is Dictionary:
		if not level_select.level_scenes.has(FAULTLINE_LEVEL_ID):
			if level_select.level_scenes.has(1):
				level_select.level_scenes[FAULTLINE_LEVEL_ID] = level_select.level_scenes[1]
	
	if "level_depths" in level_select and level_select.level_depths is Dictionary:
		if not level_select.level_depths.has(FAULTLINE_LEVEL_ID):
			level_select.level_depths[FAULTLINE_LEVEL_ID] = 1400

static func calculate_faultline_tier(global_cell: Vector2i) -> int:
	var y_tile: int = abs(global_cell.y)
	if y_tile < 24:
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
	var tier: int = calculate_faultline_tier(global_cell)
	
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

static func spawn_magma_siphons(chunk: Node, current_locs: Array[Vector2i]) -> Array[Vector2i]:
	if randf() > 0.60:
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
	
	for x in range(start_tile.x, start_tile.x + width):
		for y in range(start_tile.y, start_tile.y + height):
			var local_coord: Vector2i = Vector2i(x, y)
			if x == start_tile.x or x == start_tile.x + width - 1 or y == start_tile.y or y == start_tile.y + height - 1:
				chunk.tiles[chunk.coord_to_array(local_coord)] = wall_tile
			else:
				chunk.tiles[chunk.coord_to_array(local_coord)] = chunk.Tiles.EMPTY
	
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
