func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-lost_expedition_mod/helpers/LostExpeditionHelper.gd")
	if helper_script:
		var helper = helper_script.new()
		helper.ensure_level_registered()
		if not LEVEL_ORDER.has(helper.EXPEDITION_LEVEL_ID):
			LEVEL_ORDER.append(helper.EXPEDITION_LEVEL_ID)
	chain.execute_next()
