extends Object

func change_stage(chain: ModLoaderHookChain, target: int, targetPosition: Vector2) -> void:
	var game = chain.reference_object
	var helper_script = load("res://mods-unpacked/gareth-lost_expedition_mod/helpers/LostExpeditionHelper.gd")
	if helper_script:
		var helper = helper_script.new()
		helper.ensure_level_registered()

	if target == 2 and Gvars.level == 101:
		if game and "MINE_REGION" in game:
			game.target_stage = game.MINE_REGION

	await chain.execute_next([target, targetPosition])

	if game:
		if game.has_node("ColorRect"):
			game.get_node("ColorRect").mouse_filter = Control.MOUSE_FILTER_IGNORE
		game.visible = false
		# Supply player & profession reference so nanobotz reads Gvars.profession
		if Gvars.profession:
			if not ("player" in game) or game.player == null:
				var player_node = game.get_tree().get_first_node_in_group("player")
				if player_node:
					game.player = player_node
			if "player" in game and game.player:
				game.player.set("profession", Gvars.profession)

