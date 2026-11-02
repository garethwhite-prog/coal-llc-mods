extends Object

const BALL_PASSIVES: Dictionary[String, float] = {
	"ball_blast_damage": 0.05,
	"ball_blast_radius": 0.05,
	"ball_fire_rate": 0.05,
	"employee_miner_range": 0.05,
	"employee_miner_pickup_speed": 0.05,
	"collector_range": 0.05
}

func set_up_buttons(chain: ModLoaderHookChain) -> void:
	var screen = chain.reference_object
	if not is_instance_valid(screen) or not ("choose_between" in screen):
		chain.execute_next([])
		return

	# Inject ball passives into PASSIVE_MAP if missing
	if not screen.PASSIVE_MAP.has("bouncing_ball"):
		screen.PASSIVE_MAP["bouncing_ball"] = ["ball_blast_damage", "ball_blast_radius", "ball_fire_rate"]

	# Inject into ALL_PASSIVES so card formatting and percentage text calculate correctly
	for k in BALL_PASSIVES.keys():
		if not screen.ALL_PASSIVES.has(k):
			screen.ALL_PASSIVES[k] = BALL_PASSIVES[k]

	chain.execute_next([])

func _on_button_pressed(chain: ModLoaderHookChain) -> void:
	_handle_click(chain, 0)

func _on_button_2_pressed(chain: ModLoaderHookChain) -> void:
	_handle_click(chain, 1)

func _on_button_3_pressed(chain: ModLoaderHookChain) -> void:
	_handle_click(chain, 2)

func _handle_click(chain: ModLoaderHookChain, idx: int) -> void:
	var screen = chain.reference_object
	if not is_instance_valid(screen) or not screen.live or not ("choose_between" in screen):
		chain.execute_next([])
		return

	if idx < screen.choose_between.size():
		var stat: String = str(screen.choose_between[idx])
		if BALL_PASSIVES.has(stat):
			var amount = screen.multiplier * BALL_PASSIVES[stat]
			if Gvars and ("passives" in Gvars) and Gvars.passives:
				var p = Gvars.passives
				p.set(stat, (p.get(stat) if (stat in p) else 0.0) + amount)
				p.set_meta(stat, (p.get_meta(stat) if p.has_meta(stat) else 0.0) + amount)
				# Mirror to adjusted field for HUD display
				var adj_stat = "adjusted_" + stat
				p.set(adj_stat, (p.get(adj_stat) if (adj_stat in p) else 0.0) + amount)
				p.set_meta(adj_stat, (p.get_meta(adj_stat) if p.has_meta(adj_stat) else 0.0) + amount)

	chain.execute_next([])
