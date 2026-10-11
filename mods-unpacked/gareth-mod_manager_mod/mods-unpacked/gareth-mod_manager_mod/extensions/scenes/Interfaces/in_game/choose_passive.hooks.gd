extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var cp = chain.reference_object as ChoosePassive
	if not cp:
		chain.execute_next([])
		return

	cp.process_mode = Node.PROCESS_MODE_ALWAYS
	cp.get_tree().paused = true
	cp.live = true

	var data := {"unlocked_passives": []}
	if Gvars and Gvars.profession:
		data = Gvars.profession._profession_effect(data)

	var all_keys: Array = cp.ALL_PASSIVES.keys().duplicate()
	for up in data.get("unlocked_passives", []):
		if not all_keys.has(up):
			all_keys.append(up)
	cp.x = all_keys

	var player_inventory: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
	var choice_options: Array[String] = []
	var leftover_options: Array = cp.x.duplicate()

	if player_inventory and player_inventory.items:
		for inv_item in player_inventory.items:
			if inv_item and inv_item.item:
				for p in cp.PASSIVE_MAP.get(inv_item.item.itemType, []):
					if p in leftover_options and not (p in choice_options):
						choice_options.append(p)

	var choices: Array[String] = []
	var c1: String = choice_options.pick_random() if choice_options.size() > 0 else leftover_options.pick_random()
	choices.append(c1)
	choice_options.erase(c1)
	leftover_options.erase(c1)

	var c2: String = choice_options.pick_random() if choice_options.size() > 0 else leftover_options.pick_random()
	choices.append(c2)
	choice_options.erase(c2)
	leftover_options.erase(c2)

	var mob_opts: Array = ["player_sprint_speed", "player_jump_velocity", "player_climb_speed"]
	var valid_mob: Array = []
	for m in mob_opts:
		if leftover_options.has(m):
			valid_mob.append(m)
	var c3: String = valid_mob.pick_random() if valid_mob.size() > 0 else leftover_options.pick_random()
	choices.append(c3)

	cp.choose_between = choices
	cp.choose_between.shuffle()
	cp.set_up_buttons()

	var reroll_btn = cp.get_node_or_null("%Reroll")
	if not reroll_btn and "reroll" in cp:
		reroll_btn = cp.reroll
	if reroll_btn and not reroll_btn.pressed.is_connected(cp._on_reroll_pressed):
		reroll_btn.pressed.connect(cp._on_reroll_pressed)