extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var cp = chain.reference_object
	if not cp:
		return

	# Ensure dialog runs while game is paused
	cp.process_mode = Node.PROCESS_MODE_ALWAYS

	# Fallback if unpopulated: inject all vanilla base passives
	if cp.x.size() == 0:
		for k in cp.ALL_PASSIVES.keys():
			cp.x.append(k)

	# Validate choose_between: replace any null or duplicate entries
	var pool: Array = cp.x.duplicate()
	var final_choices: Array = []

	for c in cp.choose_between:
		if c != null and c != "" and pool.has(c) and not final_choices.has(c):
			final_choices.append(c)
			pool.erase(c)

	while final_choices.size() < 3 and pool.size() > 0:
		var picked = pool.pick_random()
		final_choices.append(picked)
		pool.erase(picked)

	cp.choose_between = final_choices
	cp.set_up_buttons()

	# Guarantee Cash / Reroll button responds to clicks
	var reroll_btn = cp.get_node_or_null("%Reroll")
	if not reroll_btn and "reroll" in cp:
		reroll_btn = cp.reroll
	if reroll_btn and not reroll_btn.pressed.is_connected(cp._on_reroll_pressed):
		reroll_btn.pressed.connect(cp._on_reroll_pressed)