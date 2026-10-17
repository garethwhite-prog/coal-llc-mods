extends Object

func change_stage(chain: ModLoaderHookChain, target: int, targetPosition: Vector2) -> void:
	var game = chain.reference_object
	if target == 2 and Gvars.level == 101:
		if game and "MINE_REGION" in game:
			game.target_stage = game.MINE_REGION
	chain.execute_next([target, targetPosition])
	if game:
		if game.has_node("ColorRect"):
			game.get_node("ColorRect").mouse_filter = Control.MOUSE_FILTER_IGNORE
		game.visible = false
