extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var ps = chain.reference_object
	if not ps or not ("professions" in ps) or not ps.professions:
		return

	var reg = load("res://mods-unpacked/gareth-mod_manager_mod/scripts/mod_registry.gd")
	if not reg:
		return

	var prof_mod_map := {
		"knight": "knight_class",
		"jedi": "jedi_class",
		"bouncing demolitionist": "bouncing_demo",
		"rainbow sinclairity": "sinclairity_class",
		"void siphon": "void_siphon",
		"debt executioner": "debt_executioner",
		"chrono-industrialist": "chrono_industrialist",
		"gravitational dreadnought": "grav_dreadnought",
		"tectonic fracker": "tectonic_fracker"
	}

	for card in ps.professions.get_children():
		if "profession" in card and card.profession:
			var pname: String = str(card.profession.profession_name).to_lower()
			if prof_mod_map.has(pname):
				var mod_key: String = prof_mod_map[pname]
				if not reg.is_mod_active_for_run(mod_key):
					card.visible = false
					card.queue_free()