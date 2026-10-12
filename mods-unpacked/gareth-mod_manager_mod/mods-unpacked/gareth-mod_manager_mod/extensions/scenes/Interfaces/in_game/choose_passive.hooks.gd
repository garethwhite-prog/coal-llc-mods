extends Object

const CUSTOM_PASSIVES: Dictionary = {
	"sword_damage": 0.10,
	"sword_speed": 0.10,
	"sword_range": 0.15
}

func _ready(chain: ModLoaderHookChain) -> void:
	var cp = chain.reference_object as ChoosePassive
	if not cp:
		chain.execute_next([])
		return

	cp.process_mode = Node.PROCESS_MODE_ALWAYS
	cp.get_tree().paused = true
	cp.live = true

	var local_passive_map: Dictionary = cp.PASSIVE_MAP.duplicate(true)
	local_passive_map["sword"] = ["sword_damage", "sword_speed", "sword_range"]

	var data := {"unlocked_passives": []}
	if Gvars and Gvars.profession:
		data = Gvars.profession._profession_effect(data)

	var all_keys: Array = cp.ALL_PASSIVES.keys().duplicate()
	for k in CUSTOM_PASSIVES.keys():
		if not all_keys.has(k):
			all_keys.append(k)

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
				for p in local_passive_map.get(inv_item.item.itemType, []):
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

	var buttons = [cp.button, cp.button_2, cp.button_3]
	for i in range(3):
		var p_key: String = cp.choose_between[i]
		var base_rate: float = 0.05
		if CUSTOM_PASSIVES.has(p_key):
			base_rate = CUSTOM_PASSIVES[p_key]
		elif cp.ALL_PASSIVES.has(p_key):
			base_rate = cp.ALL_PASSIVES[p_key]
		buttons[i].text = "Increase " + p_key.replace("_", " ").capitalize() + " +" + str(cp.multiplier * (base_rate * 100)) + "%"

	var reroll_btn = cp.get_node_or_null("%Reroll")
	if not reroll_btn and "reroll" in cp:
		reroll_btn = cp.reroll
	if reroll_btn and not reroll_btn.pressed.is_connected(cp._on_reroll_pressed):
		reroll_btn.pressed.connect(cp._on_reroll_pressed)

func _on_button_pressed(chain: ModLoaderHookChain) -> void:
	_handle_button_selection(chain, 0)

func _on_button_2_pressed(chain: ModLoaderHookChain) -> void:
	_handle_button_selection(chain, 1)

func _on_button_3_pressed(chain: ModLoaderHookChain) -> void:
	_handle_button_selection(chain, 2)

func _handle_button_selection(chain: ModLoaderHookChain, idx: int) -> void:
	var cp = chain.reference_object as ChoosePassive
	if not cp or not cp.live:
		return

	if idx >= cp.choose_between.size():
		chain.execute_next([])
		return

	var choice: String = cp.choose_between[idx]
	if CUSTOM_PASSIVES.has(choice):
		cp.live = false
		var base_rate: float = CUSTOM_PASSIVES[choice]
		var delta_amount: float = cp.multiplier * base_rate
		_apply_custom_stat(choice, delta_amount)
		cp.get_tree().paused = false
		cp.queue_free()
	else:
		chain.execute_next([])

func _apply_custom_stat(choice: String, delta_amount: float) -> void:
	if not Gvars or not ("passives" in Gvars) or not Gvars.passives:
		return
	var p = Gvars.passives
	var current: float = 0.0
	if p.has_meta(choice):
		current = float(p.get_meta(choice))
	elif choice in p:
		current = float(p.get(choice))

	var updated: float = current + delta_amount
	p.set_meta(choice, updated)
	p.set(choice, updated)
	print("[KnightPassives] Successfully applied ", choice, " +", delta_amount, " (Total: ", updated, ")")