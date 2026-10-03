extends Object

const LOG_NAME := "gareth-seismic_hazards_mod:Hook"
static var last_collapse: float = 0.0


func destroy_tile(chain: ModLoaderHookChain, idx: int, tile_properties: Dictionary) -> void:
	var chunk := chain.reference_object as TileMapChunk
	chain.execute_next([idx, tile_properties])

	var tilemap := chunk.get_parent().get_parent() as TileMapManager
	if not tilemap:
		return

	var origin := chunk.array_to_global_pos(idx)
	var left_clear: bool = not tilemap.is_tile_breakable(origin + Vector2i(-1, 0))
	var right_clear: bool = not tilemap.is_tile_breakable(origin + Vector2i(1, 0))

	if left_clear and right_clear and randf() < 0.35:
		var now: float = Time.get_ticks_msec() / 1000.0
		if now - last_collapse > 2.0:
			last_collapse = now
			var ceiling_coord := origin + Vector2i(0, -1)
			var world_pos := Vector2(ceiling_coord.x * 16, ceiling_coord.y * 16)
			ModLoaderLog.info("[Seismic Hazard] Cave-in triggered at ceiling %s!" % str(ceiling_coord), LOG_NAME)
			Bus.DamageTile.emit(world_pos, 50.0)
			Bus.BombExplode.emit(world_pos, 2.0, 30.0)