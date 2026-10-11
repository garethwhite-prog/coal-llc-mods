extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var menu = chain.reference_object
	if not menu:
		return

	var btn_grid = menu.get_node_or_null("%MainMenuButtons")
	if btn_grid and not btn_grid.has_node("LeaderboardsButton"):
		var lb_btn := Button.new()
		lb_btn.name = "LeaderboardsButton"
		lb_btn.text = "Leaderboards"
		lb_btn.custom_minimum_size = Vector2(0, 32)
		lb_btn.pressed.connect(func():
			var modal_script = load("res://mods-unpacked/gareth-leaderboard_mod/scenes/leaderboard_modal.gd")
			var modal = modal_script.new()
			menu.add_child(modal)
		)
		btn_grid.add_child(lb_btn)
		btn_grid.move_child(lb_btn, 3)