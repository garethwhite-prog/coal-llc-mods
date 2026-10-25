extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var helper = load("res://mods-unpacked/gareth-diagonal_map_mod/helpers/DiagonalMapHelper.gd")
	if helper and helper.has_method("ensure_level_registered"):
		helper.ensure_level_registered()

	var ls = chain.reference_object
	if ls and ("LEVEL_ORDER" in ls):
		if not ls.LEVEL_ORDER.has(105):
			ls.LEVEL_ORDER.append(105)

	chain.execute_next([])
