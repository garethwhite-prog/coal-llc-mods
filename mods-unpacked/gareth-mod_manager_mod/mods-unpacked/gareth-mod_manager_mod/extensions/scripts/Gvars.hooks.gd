extends Object

func reset_resources(chain: ModLoaderHookChain) -> void:
	var gvars = chain.reference_object
	if is_instance_valid(gvars) and ("resources_to_save" in gvars) and (gvars.resources_to_save is Array):
		var clean_res: Array = []
		for r in gvars.resources_to_save:
			if is_instance_valid(r) and ("resource_path" in r) and str(r.resource_path) != "":
				clean_res.append(r)
		gvars.resources_to_save = clean_res
	chain.execute_next([])
