extends Object

func change_stage(chain: ModLoaderHookChain, stage, pos: Vector2) -> void:
	if Gvars and ("level" in Gvars) and Gvars.level == 105:
		var game = chain.reference_object
		if is_instance_valid(game):
			game.load_mine("res://scenes/Stages/MineRegion.tscn")
			return
	chain.execute_next([stage, pos])
