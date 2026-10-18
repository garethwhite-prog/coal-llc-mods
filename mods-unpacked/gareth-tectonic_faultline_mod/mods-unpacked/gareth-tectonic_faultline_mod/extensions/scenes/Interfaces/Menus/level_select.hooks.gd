class_name TectonicFaultlineLevelSelectHook
extends RefCounted

const FAULTLINE_LEVEL_ID: int = 102

func _ready(level_select: LevelSelect, chain: ModLoaderHookChain) -> void:
	var Helper = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
	if Helper and Helper.has_method("register_level_select_ui"):
		Helper.register_level_select_ui(level_select)
	
	if "LEVEL_ORDER" in level_select:
		if not level_select.LEVEL_ORDER.has(FAULTLINE_LEVEL_ID):
			level_select.LEVEL_ORDER.append(FAULTLINE_LEVEL_ID)
	
	chain.execute_next()
