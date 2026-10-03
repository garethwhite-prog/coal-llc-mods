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
	var water_gun = chain.reference_object
	if not water_gun:
		chain.execute_next([player, delta])
		return

	var stack: float = _get_water_stack(water_gun, player)
	if stack <= 1.0:
		chain.execute_next([player, delta])
		return

	var orig_radius: int = water_gun.radius
	var scaled_radius: int = int(max(orig_radius + int(floor(stack * 0.5)) - 1, orig_radius))
	water_gun.radius = scaled_radius

	if Input.is_action_just_pressed("useItem"):
		ModLoaderLog.info("[WaterGun Stacker x%d] Spray Radius: %d | Pressure Dmg: %d" % [int(stack), scaled_radius, int(stack * 10)], "gareth-weapon_stacker_mod")

	chain.execute_next([player, delta])

	water_gun.radius = orig_radius

func _get_water_stack(water_gun, player) -> float:
	var item = water_gun.get_meta("equipped_item", null)
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
			elif slot.item.get("itemType") == "water_gun":
				total += float(slot.count)

	return max(total, 1.0)