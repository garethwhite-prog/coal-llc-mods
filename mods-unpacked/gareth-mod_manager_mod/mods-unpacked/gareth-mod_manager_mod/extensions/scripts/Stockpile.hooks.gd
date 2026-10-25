extends Object

func drop_off_coal(chain: ModLoaderHookChain) -> void:
	var sp = chain.reference_object
	# If player reference is lost at day transition, return safely without crashing
	if not is_instance_valid(sp) or not ("player" in sp) or not is_instance_valid(sp.player) or not ("inventory" in sp.player) or not sp.player.inventory:
		return
	chain.execute_next([])
