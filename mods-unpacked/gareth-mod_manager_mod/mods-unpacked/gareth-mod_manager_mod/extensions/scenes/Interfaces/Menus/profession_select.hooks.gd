extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var ps = chain.reference_object
	if not ps or not ("professions" in ps) or not ps.professions:
		return

	var reg = load("res://mods-unpacked/gareth-mod_manager_mod/scripts/mod_registry.gd")
	if not reg:
		return

	for card in ps.professions.get_children():
		if "profession" in card and card.profession:
			var pname: String = str(card.profession.profession_name).to_lower().replace(" ", "_").replace("-", "_")
			if not reg.is_mod_active_for_run(pname):
				card.visible = false