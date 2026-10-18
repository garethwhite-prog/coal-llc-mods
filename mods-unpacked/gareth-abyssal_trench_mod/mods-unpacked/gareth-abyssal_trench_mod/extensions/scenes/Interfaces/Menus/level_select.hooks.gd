extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-abyssal_trench_mod/helpers/AbyssalTrenchHelper.gd")
	if helper_script:
		var helper = helper_script.new()
		if helper.has_method("ensure_level_registered"):
			helper.ensure_level_registered()
		var ls = chain.reference_object
		if ls and ("LEVEL_ORDER" in ls):
			if not ls.LEVEL_ORDER.has(104):
				ls.LEVEL_ORDER.append(104)

	chain.execute_next([])
