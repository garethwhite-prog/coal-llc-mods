extends Object

func save_game(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var ssm = Gvars.get_node_or_null("/root/SaveSlotManager")
	if ssm:
		ssm.sync_active_slot_from_vanilla()

func load_game(chain: ModLoaderHookChain) -> void:
	var ssm = Gvars.get_node_or_null("/root/SaveSlotManager")
	if ssm:
		ssm.prepare_vanilla_from_active_slot()
	chain.execute_next([])