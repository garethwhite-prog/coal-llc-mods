extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
	if helper_script:
		var helper = helper_script.new()
		helper.ensure_level_registered()
	chain.execute_next([])
