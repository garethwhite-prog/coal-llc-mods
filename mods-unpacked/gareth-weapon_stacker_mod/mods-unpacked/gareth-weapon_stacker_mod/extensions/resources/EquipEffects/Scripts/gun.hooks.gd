extends Object

func start(chain: ModLoaderHookChain, player, item) -> void:
	if chain and chain.reference_object:
		chain.reference_object.set_meta("equipped_item", item)
	chain.execute_next([player, item])

func end(chain: ModLoaderHookChain, player) -> void:
	if chain and chain.reference_object:
		chain.reference_object.set_meta("equipped_item", null)
	chain.execute_next([player])

func physics_process(chain: ModLoaderHookChain, player, delta) -> void:
	var gun = chain.reference_object
	if not gun:
		chain.execute_next([player, delta])
		return

	var stack: float = _get_gun_stack(gun, player)
	if stack <= 1.0:
		chain.execute_next([player, delta])
		return

	var orig_damage: float = gun.bullet_damage
	var orig_count: int = gun.bullet_count
	var orig_cooldown: float = gun.cooldown_time
	var orig_speed: float = gun.bullet_speed

	var raw_bullets: float = float(orig_count) * stack
	var capped_count: int = int(clamp(round(raw_bullets), 5, 40))
	var bullet_ratio: float = raw_bullets / float(capped_count)
	var scaled_damage: float = orig_damage * stack * bullet_ratio
	var scaled_cooldown: float = max(orig_cooldown / stack, 0.01)

	# Compensate for player_2.gd deducting 5 speed per bullet so the slowest pellet never goes negative
	var required_speed_boost: float = float(capped_count) * 5.5
	var scaled_speed: float = orig_speed + required_speed_boost

	gun.bullet_damage = scaled_damage
	gun.bullet_count = capped_count
	gun.cooldown_time = scaled_cooldown
	gun.bullet_speed = scaled_speed

	if Input.is_action_just_pressed("useItem"):
		ModLoaderLog.info("[Minigun Stacker x%d] Dmg: %.1f | Bullets: %d | Delay: %.4fs (~%.1f bursts/sec) | Forward Speed: %.0f" % [int(stack), scaled_damage, capped_count, scaled_cooldown, 1.0 / scaled_cooldown, scaled_speed], "gareth-weapon_stacker_mod")

	chain.execute_next([player, delta])

	gun.bullet_damage = orig_damage
	gun.bullet_count = orig_count
	gun.cooldown_time = orig_cooldown
	gun.bullet_speed = orig_speed

func _get_gun_stack(gun, player) -> float:
	var item = gun.get_meta("equipped_item", null)
	var inv = null
	if player and "inventory" in player and player.inventory:
		inv = player.inventory
	else:
		inv = load("res://resources/Inventories/PlayerInventory.tres")

	if not inv or not ("items" in inv) or not inv.items:
		return 1.0

	if item and inv.has_method("count_item"):
		var c: float = inv.count_item(item)
		if c > 0.0:
			return c

	var total: float = 0.0
	for slot in inv.items:
		if slot and slot.item:
			if item and slot.item.itemID == item.itemID:
				total += float(slot.count)
			elif slot.item.get("itemType") == "minigun":
				total += float(slot.count)

	return max(total, 1.0)