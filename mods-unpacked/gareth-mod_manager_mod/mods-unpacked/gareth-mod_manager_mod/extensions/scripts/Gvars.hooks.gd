extends Object

func reset_resources(chain: ModLoaderHookChain) -> void:
	var gvars = chain.reference_object
	if is_instance_valid(gvars) and ("resources_to_save" in gvars) and (gvars.resources_to_save is Array):
		var clean_res: Array = []
		for r in gvars.resources_to_save:
			if is_instance_valid(r) and ("resource_path" in r) and str(r.resource_path) != "" and ResourceLoader.exists(r.resource_path):
				clean_res.append(r)
		gvars.resources_to_save = clean_res
	chain.execute_next([])

func save_Gvars(chain: ModLoaderHookChain) -> Dictionary:
	var result: Dictionary = chain.execute_next([])
	if not result.has("Gvars"):
		result["Gvars"] = {}

	var g = chain.reference_object
	if g and ("profession" in g) and g.profession and ("profession_manager" in g) and g.profession_manager:
		var pm = g.profession_manager
		for p_id in pm.all_professions.keys():
			if pm.all_professions[p_id]["profession"] == g.profession:
				result["Gvars"]["profession"] = p_id
				break
	return result

func load_Gvars(chain: ModLoaderHookChain, save: Dictionary) -> void:
	chain.execute_next([save])
	var g = chain.reference_object
	if not g or not save.has("Gvars") or not save["Gvars"].has("profession"):
		return

	var saved_id: int = int(save["Gvars"]["profession"])
	if ("profession_manager" in g) and g.profession_manager:
		var pm = g.profession_manager
		if pm.all_professions.has(saved_id):
			g.profession = pm.all_professions[saved_id]["profession"]
