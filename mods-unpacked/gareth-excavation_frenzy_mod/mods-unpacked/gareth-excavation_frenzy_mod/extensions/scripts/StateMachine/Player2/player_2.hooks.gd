extends Object

const LOG_NAME := "gareth-excavation_frenzy_mod:Hook"
static var combo_count: int = 0
static var last_mine_time: float = 0.0


func mine_action(chain: ModLoaderHookChain) -> void:
	var player := chain.reference_object as Player
	var now: float = Time.get_ticks_msec() / 1000.0
	if (now - last_mine_time) > 2.2:
		combo_count = 0
	last_mine_time = now
	combo_count = mini(combo_count + 1, 5)

	if player and player.animation_tool:
		player.animation_tool.speed_scale = 1.0 + (combo_count * 0.4)

	ModLoaderLog.info("[Frenzy] Swing! Combo: %d/5 | Animation Scale: %.2fx" % [
		combo_count,
		player.animation_tool.speed_scale if player and player.animation_tool else 1.0
	], LOG_NAME)

	if combo_count >= 5:
		var strike_pos: Vector2 = player.pointer_global_pos if player.mine_where_mouse_is else player.global_position
		ModLoaderLog.info("[Frenzy] MAX FRENZY SHOCKWAVE at %s!" % str(strike_pos), LOG_NAME)
		Bus.BombExplode.emit(strike_pos, 3.5, 60.0)
		combo_count = 0

	chain.execute_next()