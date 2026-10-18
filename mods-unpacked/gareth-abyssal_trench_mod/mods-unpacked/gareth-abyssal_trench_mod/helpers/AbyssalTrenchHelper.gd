class_name AbyssalTrenchHelper
extends RefCounted

const TRENCH_LEVEL_ID: int = 104
const PREVIEW_PATH: String = "res://mods-unpacked/gareth-abyssal_trench_mod/assets/abyssal_preview.png"
const BUFFER_SURFACE_ROWS: int = 12

static func is_abyssal_level() -> bool:
	if Gvars:
		if "level" in Gvars and Gvars.level == TRENCH_LEVEL_ID:
			return true
		if "chosen_level" in Gvars and Gvars.chosen_level == TRENCH_LEVEL_ID:
			return true
		if "current_level" in Gvars and Gvars.current_level == TRENCH_LEVEL_ID:
			return true
	return false

func ensure_level_registered() -> void:
	register_trench_level()

static func register_trench_level() -> void:
	if not Gvars:
		return

	if "level_manager" in Gvars and Gvars.level_manager and ("all_levels" in Gvars.level_manager):
		var lvl_mgr = Gvars.level_manager
		if not lvl_mgr.all_levels.has(TRENCH_LEVEL_ID):
			var custom_level = GameLevel.new()
			custom_level.level_name = "The Abyssal Trench"
			custom_level.level = TRENCH_LEVEL_ID
			custom_level.mining_scene_path = "res://scenes/Stages/MineRegion.tscn"
			custom_level.level_description = "Subterranean ocean trench.\n\nDeep sapphire strata, submerged cavern pockets, and hydrothermal black smoker steam geysers."
			custom_level.level_difficulty = GameLevel.Difficulty.HARD
			custom_level.unlock_description = ""

			var bytes = FileAccess.get_file_as_bytes(PREVIEW_PATH)
			if bytes.size() > 0:
				var img = Image.new()
				if img.load_png_from_buffer(bytes) == OK:
					custom_level.level_image = ImageTexture.create_from_image(img)

			lvl_mgr.all_levels[TRENCH_LEVEL_ID] = {
				"level": custom_level,
				"is_unlocked": true
			}

	if "level_info" in Gvars and Gvars.level_info is Dictionary:
		if not Gvars.level_info.has(TRENCH_LEVEL_ID):
			Gvars.level_info[TRENCH_LEVEL_ID] = {
				"name": "The Abyssal Trench",
				"description": "Subterranean ocean trench with hydrothermal vents and sapphire strata.",
				"depth": 1500,
				"cost": 0,
				"unlocked": true
			}

static func generate_abyssal_strata(chunk: Node, noise: Noise) -> void:
	if not ("tiles" in chunk) or not chunk.has_method("array_to_global_pos"):
		return

	var vent_spawned: bool = false

	for idx in range(chunk.tiles.size()):
		var global_pos: Vector2i = Vector2i(chunk.array_to_global_pos(idx))

		# 1. Surface buffer (Rows 0-12): Keep soft clay/coal starter ground intact
		if global_pos.y <= BUFFER_SURFACE_ROWS:
			continue

		var local_x = idx % chunk.chunk_size
		var local_y = idx / chunk.chunk_size

		# 2. Carve Submerged Trench Caverns using 2D noise
		var cave_noise: float = abs(noise.get_noise_2d(float(global_pos.x) * 3.2, float(global_pos.y) * 1.8))
		if cave_noise < 0.12 and global_pos.y > 18:
			chunk.tiles[idx] = chunk.Tiles.EMPTY
			chunk.build_tile(idx)

			# Spawn Hydrothermal Black Smoker on cavern floor
			if not vent_spawned and global_pos.y >= 28 and local_y < chunk.chunk_size - 2:
				var below_idx = idx + chunk.chunk_size
				if below_idx < chunk.tiles.size() and chunk.tiles[below_idx] != chunk.Tiles.EMPTY:
					var VentScene = load("res://mods-unpacked/gareth-abyssal_trench_mod/entities/HydrothermalVent.gd")
					if VentScene:
						var vent = VentScene.new()
						vent.position = chunk.map_to_local(Vector2i(local_x, local_y + 1))
						chunk.add_child(vent)
						vent_spawned = true
			continue

		# 3. Strata Distribution
		var tile_to_set: int = chunk.Tiles.BASIC_DARKBLUE
		var seed_val: int = abs(global_pos.x * 73856093 ^ global_pos.y * 19349663)
		var roll: int = seed_val % 100

		if global_pos.y <= 60:
			# Twilight Zone: Dark Blue Stone & Sapphires / Moonstones
			if roll < 38:
				tile_to_set = 212 # COAL_DARKBLUE
			elif roll < 56:
				tile_to_set = 215 # SAPPHIRE_DARKBLUE
			elif roll < 66:
				tile_to_set = 225 # MOONSTONE_DARKBLUE
			elif roll < 78:
				tile_to_set = 213 # COPPER_DARKBLUE
			else:
				tile_to_set = 211 # BASIC_DARKBLUE
		else:
			# Hadal Trench: Volcanic Basalt, Onyx, Supercooled Ice Crystals
			if roll < 35:
				tile_to_set = 93  # COAL_DARK
			elif roll < 54:
				tile_to_set = 107 # ONYX_DARK
			elif roll < 65:
				tile_to_set = 68  # DIAMOND_ICE
			elif roll < 78:
				tile_to_set = 98  # GOLD_DARK
			else:
				tile_to_set = 92  # BASIC_DARK

		chunk.tiles[idx] = tile_to_set
		chunk.build_tile(idx)
