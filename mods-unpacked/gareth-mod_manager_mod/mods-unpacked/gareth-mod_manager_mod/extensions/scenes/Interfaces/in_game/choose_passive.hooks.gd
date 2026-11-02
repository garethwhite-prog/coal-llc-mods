extends Object

const BALL_PASSIVES: Array[String] = [
	"ball_blast_radius",
	"ball_blast_damage",
	"ball_fire_rate"
]

const CUSTOM_PASSIVE_DEFAULTS: Dictionary = {
	"ball_blast_radius": 0.05,
	"ball_blast_damage": 0.05,
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

	# Check if player has the Bouncing Ball in inventory
	var has_ball := false
	var inv: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
	if inv and inv.items:
		for inv_item in inv.items:
			if inv_item and inv_item.item and inv_item.item.itemType == "bouncing_ball":
				has_ball = true
				break

	# If holding Bouncing Ball, ensure at least one card offers a ball upgrade
	if has_ball and screen.choose_between.size() >= 3:
		var has_ball_choice := false
		for opt in screen.choose_between:
			if opt in BALL_PASSIVES:
				has_ball_choice = true
				break
		if not has_ball_choice:
			var rand_idx: int = randi() % 3
			var rand_ball_stat: String = BALL_PASSIVES[randi() % BALL_PASSIVES.size()]
			screen.choose_between[rand_idx] = rand_ball_stat

	# Format button text cleanly for both vanilla and custom passives
	var buttons = [screen.button, screen.button_2, screen.button_3]
	for i in range(0, min(3, screen.choose_between.size())):
		var stat_name: String = str(screen.choose_between[i])
		var base_val: float = 0.05
		if screen.ALL_PASSIVES.has(stat_name):
			base_val = screen.ALL_PASSIVES[stat_name]
		elif CUSTOM_PASSIVE_DEFAULTS.has(stat_name):
			base_val = CUSTOM_PASSIVE_DEFAULTS[stat_name]

		var pct_str: String = str(screen.multiplier * (base_val * 100.0))
		buttons[i].text = "Increase " + stat_name.replace("_", " ").capitalize() + " +" + pct_str + "%"

func _on_button_pressed(chain: ModLoaderHookChain) -> void:
	_handle_button_click(chain, 0)

func _on_button_2_pressed(chain: ModLoaderHookChain) -> void:
	_handle_button_click(chain, 1)

func _on_button_3_pressed(chain: ModLoaderHookChain) -> void:
	_handle_button_click(chain, 2)

func _handle_button_click(chain: ModLoaderHookChain, button_idx: int) -> void:
	var screen = chain.reference_object
	if not is_instance_valid(screen) or not screen.live or not ("choose_between" in screen):
		chain.execute_next([])
		return

	if button_idx >= screen.choose_between.size():
		chain.execute_next([])
		return

	var stat_name: String = str(screen.choose_between[button_idx])
	if screen.ALL_PASSIVES.has(stat_name):
		chain.execute_next([])
		return

	# Handle custom mod passive
	screen.live = false
	var base_val: float = CUSTOM_PASSIVE_DEFAULTS.get(stat_name, 0.05)
	var add_amount: float = screen.multiplier * base_val

	if Gvars and ("passives" in Gvars) and Gvars.passives:
		var p: Resource = Gvars.passives
		var cur_meta: float = 0.0
		if p.has_meta(stat_name):
			cur_meta = float(p.get_meta(stat_name))
		p.set_meta(stat_name, cur_meta + add_amount)

		var adj_stat = "adjusted_" + stat_name
		var cur_adj: float = 0.0
		if p.has_meta(adj_stat):
			cur_adj = float(p.get_meta(adj_stat))
		p.set_meta(adj_stat, cur_adj + add_amount)

	if Gvars:
		if not ("custom_passives" in Gvars) or Gvars.custom_passives == null:
			Gvars.set("custom_passives", {})
		var cp = Gvars.get("custom_passives")
		if cp is Dictionary:
			cp[stat_name] = cp.get(stat_name, 0.0) + add_amount

	screen.get_tree().paused = false
	screen.queue_free()
