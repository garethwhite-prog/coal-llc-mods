extends Object

func reset_resources(chain: ModLoaderHookChain) -> void:
	# Clean any null or unpathed items from resources_to_save before running reset
	if Gvars and ("resources_to_save" in Gvars) and Gvars.resources_to_save:
		var cleaned: Array = []
		for res in Gvars.resources_to_save:
			if res != null and ("resource_path" in res) and str(res.resource_path) != "":
				cleaned.append(res)
		Gvars.resources_to_save = cleaned

	chain.execute_next([])
