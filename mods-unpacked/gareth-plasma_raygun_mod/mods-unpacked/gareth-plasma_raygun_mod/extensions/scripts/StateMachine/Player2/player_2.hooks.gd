extends Object

var _checked_active: bool = false
var _is_active: bool = true

func _check_mod_status() -> bool:
	if _checked_active:
		return _is_active
	_checked_active = true

	var ssm = Engine.get_main_loop().root.get_node_or_null("/root/SaveSlotManager")
	if ssm and ssm.has_method("is_mod_active_for_run"):
		_is_active = ssm.is_mod_active_for_run("plasma_raygun")
		return _is_active

	var reg_paths = [
		"res://mods-unpacked/gareth-mod_manager_mod/scripts/mod_registry.gd",
		"res://mods-unpacked/gareth-mod_manager_mod/mods-unpacked/gareth-mod_manager_mod/scripts/mod_registry.gd"
	]
	for p in reg_paths:
		if ResourceLoader.exists(p):
			var reg = load(p)
			if reg and reg.has_method("is_mod_active_for_run"):
				_is_active = reg.is_mod_active_for_run("plasma_raygun")
				return _is_active

	_is_active = true
	return _is_active

func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	if not _check_mod_status():
		chain.execute_next([delta])
		return

	chain.execute_next([delta])
