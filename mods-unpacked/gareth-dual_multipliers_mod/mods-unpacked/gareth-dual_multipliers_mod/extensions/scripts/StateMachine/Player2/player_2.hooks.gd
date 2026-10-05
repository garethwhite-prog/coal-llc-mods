extends Object

func on_fire_gun_attempt(chain: ModLoaderHookChain, cooldown_time: float, gun_shot_audio_stream: AudioStream, gun_recoil: float, bullet_count: int, bullet_spread: float, bullet_speed: float, bullet_damage: float, bullet_max_distance: float, weapon_length: float, is_reloaded: bool = false, gun_reload_audio_stream: AudioStream = AudioStream.new(), gun_reload_delay_time: float = 0) -> void:
	var rate_mult: float = 1.0
	if Gvars and ("passives" in Gvars) and Gvars.passives:
		if "gun_rate" in Gvars.passives:
			rate_mult = 1.0 + float(Gvars.passives.gun_rate)

	var scaled_cooldown: float = max(0.02, cooldown_time / rate_mult)
	chain.execute_next([
		scaled_cooldown, gun_shot_audio_stream, gun_recoil, bullet_count,
		bullet_spread, bullet_speed, bullet_damage, bullet_max_distance,
		weapon_length, is_reloaded, gun_reload_audio_stream, gun_reload_delay_time
	])