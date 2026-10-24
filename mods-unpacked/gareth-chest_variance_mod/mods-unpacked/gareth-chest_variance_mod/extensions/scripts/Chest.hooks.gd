extends Object

const MOD_DIR := "gareth-chest_variance_mod"

func roll_loot(chain: ModLoaderHookChain) -> void:
	var chest = chain.reference_object
	if not is_instance_valid(chest):
		chain.execute_next([])
		return

	# 3% chance of a booby-trap explosion
	if randf() < 0.03:
		ModLoaderLog.info("[Chest Variance] *** BOOBY TRAP DETONATED *** at %s" % str(chest.global_position), MOD_DIR)
		_trigger_trap_explosion(chest)
		return

	# Tier variance roll:
	# -2 tiers: 5% | -1 tier: 15% | 0 (base): 60% | +1 tier: 15% | +2 tiers: 5%
	var roll: float = randf()
	var tier_shift: int = 0
	if roll < 0.05:
		tier_shift = -2
	elif roll < 0.20:
		tier_shift = -1
	elif roll > 0.95:
		tier_shift = 2
	elif roll > 0.80:
		tier_shift = 1

	var original_level: int = chest.loot_level
	var effective_level: int = clampi(original_level + tier_shift, 1, 15)
	chest.loot_level = effective_level

	chain.execute_next([])

	# Scale passive upgrade multipliers to match effective tier
	if is_instance_valid(chest.loot) and chest.loot.itemType == "passive_upgrade":
		if chest.loot.itemPickupEffect and ("multiplier" in chest.loot.itemPickupEffect):
			if effective_level <= 4:
				chest.loot.itemPickupEffect.multiplier = float(effective_level)
			else:
				chest.loot.itemPickupEffect.multiplier = float(effective_level ** 2)

	# Seed custom class weapons into power-up scroll drops
	var custom_weapon_seeded := false
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if item_unlocks and is_instance_valid(chest.loot) and chest.loot.itemType == "scroll":
		var candidates: Array = []
		for it in item_unlocks.all_equipment_items:
			if is_instance_valid(it) and it.itemType in ["sword", "jedi_saber", "tank_fire", "tank_poison", "tank_uranium"]:
				candidates.append(it)
		if candidates.size() > 0 and randf() < 0.35:
			var custom_weapon = candidates.pick_random()
			chest.loot = chest.generate_power_up_scroll_for_item(custom_weapon)
			custom_weapon_seeded = true

	var loot_name: String = chest.loot.itemName if is_instance_valid(chest.loot) else "Unknown"
	ModLoaderLog.info("[Chest Variance] Stratum Tier: %d -> Rolled Tier: %d (Shift: %+d) | Loot: %s%s" % [
		original_level,
		effective_level,
		tier_shift,
		loot_name,
		" [CUSTOM WEAPON SCROLL]" if custom_weapon_seeded else ""
	], MOD_DIR)

	chest.loot_level = original_level

func _trigger_trap_explosion(chest: Node2D) -> void:
	chest.looted = true
	chest.opened = true
	if "sprite_empty" in chest and is_instance_valid(chest.sprite_empty):
		chest.sprite_empty.visible = true
	if "sprite_closed" in chest and is_instance_valid(chest.sprite_closed):
		chest.sprite_closed.visible = false
	if "sprite_open" in chest and is_instance_valid(chest.sprite_open):
		chest.sprite_open.visible = false

	var tree = chest.get_tree()
	if not tree:
		return

	var tilemaps = tree.get_nodes_in_group("tilemap")
	var tilemap = tilemaps[0] if tilemaps.size() > 0 else null

	var center_pos: Vector2 = chest.global_position
	if tilemap and tilemap.has_method("damageTileCoords"):
		var center_cell: Vector2i = tilemap.local_to_map(tilemap.to_local(center_pos))
		for dx in range(-3, 4):
			for dy in range(-3, 4):
				if dx*dx + dy*dy <= 9:
					var cell = center_cell + Vector2i(dx, dy)
					tilemap.damageTileCoords(cell, 350.0)

	var boom_audio = AudioStreamPlayer2D.new()
	boom_audio.stream = load("res://assets/sound/sound effects/box_1.wav")
	boom_audio.global_position = center_pos
	tree.current_scene.add_child(boom_audio)
	boom_audio.play()
	boom_audio.finished.connect(boom_audio.queue_free)
