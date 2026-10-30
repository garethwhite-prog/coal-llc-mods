extends Object

func change_stage(chain: ModLoaderHookChain, target: int, targetPosition: Vector2) -> void:
	var game = chain.reference_object
	if target == 2 and Gvars and ("level" in Gvars) and Gvars.level == 103:
		# Map 103: The Living Canvas - Route to MineRegion stage
		var mine_scene = load("res://scenes/Stages/MineRegion.tscn")
		if mine_scene and game:
			game.target_stage = mine_scene

	await chain.execute_next([target, targetPosition])

