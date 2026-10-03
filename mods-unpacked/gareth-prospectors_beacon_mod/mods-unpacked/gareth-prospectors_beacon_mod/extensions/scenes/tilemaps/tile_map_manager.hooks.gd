extends Object

const LOG_NAME := "gareth-prospectors_beacon_mod:Hook"
static var last_pulse: float = 0.0


func apply_tile_effects(chain: ModLoaderHookChain) -> void:
	chain.execute_next()

	var now: float = Time.get_ticks_msec() / 1000.0
	if now - last_pulse > 4.5:
		last_pulse = now
		var tilemap := chain.reference_object as TileMapManager
		if not tilemap:
			return
		var players = tilemap.get_tree().get_nodes_in_group("player")
		if players.is_empty():
			return
		var player_pos: Vector2 = players[0].global_position
		ModLoaderLog.info("[Prospector Beacon] Acoustic pulse pinging near %s" % str(player_pos), LOG_NAME)
		var ping_offset := Vector2(randf_range(-64, 64), randf_range(16, 80))
		Bus.DamageTile.emit(player_pos + ping_offset, 25.0)