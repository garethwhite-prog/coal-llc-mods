extends Object

const LOG_NAME := "gareth-prospectors_beacon_mod:Hook"
static var last_pulse: float = 0.0


func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	chain.execute_next([delta])

	var player := chain.reference_object as Player
	if not player or not player.is_inside_tree():
		return

	var now: float = Time.get_ticks_msec() / 1000.0
	if (now - last_pulse) > 4.5:
		last_pulse = now
		var player_pos: Vector2 = player.global_position
		ModLoaderLog.info("[Prospector Beacon] Acoustic pulse pinging near %s" % str(player_pos), LOG_NAME)
		var ping_offset := Vector2(randf_range(-64, 64), randf_range(16, 80))
		Bus.DamageTile.emit(player_pos + ping_offset, 25.0)