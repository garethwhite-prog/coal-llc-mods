extends Object

func _process(chain: ModLoaderHookChain, delta: float) -> void:
	var sp = chain.reference_object
	if is_instance_valid(sp):
		var tree = sp.get_tree()
		if tree and tree.root:
			var player = tree.root.find_child("Player", true, false)
			if is_instance_valid(player) and ("global_position" in player) and ("global_position" in sp):
				var extra_reach = 0.0
				
				if Gvars and ("passives" in Gvars) and Gvars.passives:
					if Gvars.passives.has_meta("player_reach_bonus"):
						extra_reach = float(Gvars.passives.get_meta("player_reach_bonus")) * 24.0
						
				if player.global_position.distance_to(sp.global_position) <= (64.0 + extra_reach):
					if "interactable" in sp:
						sp.interactable = true
						
	chain.execute_next([delta])
