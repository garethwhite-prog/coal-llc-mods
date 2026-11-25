extends Object

const STATE_SCRIPT := "res://mods-unpacked/gareth-tank_arsenal_mod/tank_state.gd"

var _fire_accum: float = 0.0

func start(chain: ModLoaderHookChain, player, item) -> void:
	_fire_accum = 0.0
	if is_instance_valid(player) and ("ready_to_shoot" in player):
		player.ready_to_shoot = true
	chain.execute_next([player, item])
	var state = load(STATE_SCRIPT)
	var item_id = item.itemID if (item and "itemID" in item) else ""
	state.active_tank_id = item_id

	if player and "equipped_item_sprite" in player and player.equipped_item_sprite:
		player.equipped_item_sprite.modulate = state.get_color_for_id(item_id)

func end(chain: ModLoaderHookChain, player) -> void:
	_fire_accum = 0.0
	var state = load(STATE_SCRIPT)
	state.active_tank_id = ""
	if player and "equipped_item_sprite" in player and player.equipped_item_sprite:
		player.equipped_item_sprite.modulate = Color.WHITE
	chain.execute_next([player])

func physics_process(chain: ModLoaderHookChain, player, delta: float) -> void:
	var tank_eq = chain.reference_object
	if not is_instance_valid(tank_eq) or not is_instance_valid(player):
		chain.execute_next([player, delta])
		return

	if Input.is_action_pressed("useItem"):
		tank_eq._using_item = true
	elif Input.is_action_just_released("useItem"):
		tank_eq._using_item = false
	elif Input.is_action_just_pressed("toggle_use_item"):
		tank_eq._using_item = not tank_eq._using_item

	if not tank_eq._using_item:
		_fire_accum = maxf(0.0, _fire_accum - delta)
		return

	_fire_accum -= delta
	if _fire_accum <= 0.0:
		var rate_bonus: float = float(Gvars.passives.tank_firing_rate) if (Gvars and ("passives" in Gvars) and Gvars.passives) else 0.0
		var eff_cd: float = maxf(0.016, float(tank_eq.cooldown_time) / maxf(0.1, 1.0 + rate_bonus))
		_fire_accum = eff_cd

		# Prevent GunCooldown Timer phase-aliasing at high fire rates
		if "ready_to_shoot" in player:
			player.ready_to_shoot = true
		if ("ray_cast_tool" in player) and is_instance_valid(player.ray_cast_tool):
			if player.ray_cast_tool.target_position.length_squared() < 0.01 and ("pointer_pos" in player) and player.pointer_pos.length_squared() > 0.01:
				player.ray_cast_tool.target_position = player.pointer_pos.normalized() * 32.0

		player.shoot_tank(float(tank_eq.damage), eff_cd, int(tank_eq.radius))
