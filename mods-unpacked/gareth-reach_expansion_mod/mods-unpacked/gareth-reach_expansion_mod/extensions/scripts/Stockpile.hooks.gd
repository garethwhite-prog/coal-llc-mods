extends Object

func _process(chain: ModLoaderHookChain, delta: float) -> void:
	var sp = chain.reference_object
	if is_instance_valid(sp):
		var tree = sp.get_tree()
		if tree and tree.root:
			var player = tree.root.find_child("Player", true, false)
			if is_instance_valid(player):
				var extra_reach = 0.0
				if Gvars and ("passives" in Gvars) and Gvars.passives and ("player_reach_bonus" in Gvars.passives):
					extra_reach = float(Gvars.passives.player_reach_bonus) * 24.0
				if player.global_position.distance_to(sp.global_position) <= (64.0 + extra_reach):
					sp.interactable = true
	chain.execute_next([delta])
