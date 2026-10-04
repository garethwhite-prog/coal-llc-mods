extends Object

const STATE_SCRIPT := "res://mods-unpacked/gareth-tank_arsenal_mod/tank_state.gd"

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var bullet = chain.reference_object
	if not bullet:
		return

	var state = load(STATE_SCRIPT)
	var tank_id = state.active_tank_id
	bullet.set_meta("tank_id", tank_id)

	if "tank_fire" in tank_id:
		bullet.modulate = Color(2.0, 0.45, 0.1, 1.0)
	elif "tank_poison" in tank_id:
		bullet.modulate = Color(0.25, 2.0, 0.35, 1.0)
	elif "tank_uranium" in tank_id:
		bullet.modulate = Color(0.35, 1.0, 2.2, 1.0)

		# Scale penetration by tier level (01 = 1 block, 02 = 2 blocks ... 15 = 15 blocks)
		var tier_num: int = 1
		var parts: PackedStringArray = tank_id.split("_")
		if parts.size() >= 3 and parts[2].is_valid_int():
			tier_num = parts[2].to_int()

		bullet.set_meta("pierce_left", max(1, tier_num))
		bullet.set_meta("last_pierced_tile", Vector2i(-999999, -999999))

func attack_tile(chain: ModLoaderHookChain) -> void:
	var bullet = chain.reference_object
	if not bullet or not bullet.tilemap or bullet.hit:
		chain.execute_next([])
		return

	var tank_id = bullet.get_meta("tank_id", "")
	if tank_id == "" or (not "tank_fire" in tank_id and not "tank_poison" in tank_id and not "tank_uranium" in tank_id):
		chain.execute_next([])
		return

	var current_tile: Vector2i = bullet.tilemap.local_to_map(bullet.tilemap.to_local(bullet.global_position))
	var is_solid: bool = bullet.tilemap.is_tile_collision(current_tile)
	var expired: bool = bullet.t > bullet.LIFETIME

	var tank_mult: float = 1.0 + Gvars.passives.tank_damage

	# 1. INCENDIARY
	if "tank_fire" in tank_id:
		if is_solid or expired:
			bullet.hit = true
			var fire_mult: float = 1.0 + Gvars.passives.fire_damage
			var direct_dmg: float = bullet.damage * tank_mult
			var burn_dmg: float = (bullet.damage * 0.5) * fire_mult

			for x in range(-bullet.radius, bullet.radius + 1):
				for y in range(-bullet.radius, bullet.radius + 1):
					if abs(x) + abs(y) < (bullet.radius + 1):
						var tile_coords = Vector2i(current_tile.x + x, current_tile.y + y)
						bullet.tilemap.damageTileCoords(Vector2(tile_coords.x, tile_coords.y), direct_dmg)
						bullet.tilemap.burn_tile_coords(tile_coords, burn_dmg, 6)
			bullet.explode()
		return

	# 2. CAUSTIC
	if "tank_poison" in tank_id:
		if is_solid or expired:
			bullet.hit = true
			var poison_mult: float = 1.0 + Gvars.passives.poison_damage
			var direct_dmg: float = bullet.damage * tank_mult
			var poison_dmg: float = (bullet.damage * 0.5) * poison_mult

			for x in range(-bullet.radius, bullet.radius + 1):
				for y in range(-bullet.radius, bullet.radius + 1):
					if abs(x) + abs(y) < (bullet.radius + 1):
						var tile_coords = Vector2i(current_tile.x + x, current_tile.y + y)
						bullet.tilemap.damageTileCoords(Vector2(tile_coords.x, tile_coords.y), direct_dmg)
						bullet.tilemap.poison_tile_coords(tile_coords, poison_dmg, 6)
			bullet.explode()
		return

	# 3. DEPLETED URANIUM (SCALED PENETRATION BY TIER)
	if "tank_uranium" in tank_id:
		if is_solid:
			var last_hit: Vector2i = bullet.get_meta("last_pierced_tile", Vector2i(-999999, -999999))
			if current_tile != last_hit:
				bullet.set_meta("last_pierced_tile", current_tile)
				var pierce: int = bullet.get_meta("pierce_left", 1) - 1
				bullet.set_meta("pierce_left", pierce)

				# Punch damage through rock wall
				var punch_dmg: float = bullet.damage * tank_mult
				bullet.tilemap.damageTileCoords(Vector2(current_tile.x, current_tile.y), punch_dmg)

				if pierce <= 0:
					_detonate_uranium(bullet, current_tile, tank_mult)
					return
			return

		if expired:
			_detonate_uranium(bullet, current_tile, tank_mult)
			return

func _detonate_uranium(bullet, current_tile: Vector2i, tank_mult: float) -> void:
	bullet.hit = true
	var direct_dmg: float = bullet.damage * tank_mult
	for x in range(-bullet.radius, bullet.radius + 1):
		for y in range(-bullet.radius, bullet.radius + 1):
			if abs(x) + abs(y) < (bullet.radius + 1):
				var tile_coords = Vector2(current_tile.x + x, current_tile.y + y)
				bullet.tilemap.damageTileCoords(tile_coords, direct_dmg)
	bullet.explode()