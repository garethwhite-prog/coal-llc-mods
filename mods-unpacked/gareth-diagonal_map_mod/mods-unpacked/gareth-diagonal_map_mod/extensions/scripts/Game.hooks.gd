extends Object

func change_stage(chain: ModLoaderHookChain, target, pos: Vector2) -> void:
	var game = chain.reference_object
	if int(target) == 2 and Gvars and Gvars.get("level") == 105:
		if is_instance_valid(game):
			if "MINE_REGION" in game and game.MINE_REGION:
				game.target_stage = game.MINE_REGION
			else:
				game.target_stage = load("res://scenes/Stages/MineRegion.tscn")
	
	await chain.execute_next([target, pos])
