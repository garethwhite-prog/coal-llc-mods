extends Object

func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	chain.execute_next([delta])
	var vac = chain.reference_object
	if vac and not vac.is_in_group("vacuum_cleaner"):
		vac.add_to_group("vacuum_cleaner")