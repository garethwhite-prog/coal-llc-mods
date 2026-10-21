extends Object

func _process(chain: ModLoaderHookChain, delta: float) -> void:
	chain.execute_next([delta])

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])

func _on_button_pressed(chain: ModLoaderHookChain) -> void:
	_handle_selection(chain, 0)

func _on_button_2_pressed(chain: ModLoaderHookChain) -> void:
	_handle_selection(chain, 1)

func _on_button_3_pressed(chain: ModLoaderHookChain) -> void:
	_handle_selection(chain, 2)

func _handle_selection(chain: ModLoaderHookChain, button_idx: int) -> void:
	var screen = chain.reference_object
	if not is_instance_valid(screen):
		chain.execute_next([])
		return

	if "options" in screen and button_idx < screen.options.size():
		var chosen = screen.options[button_idx]
		if chosen and ("stat_name" in chosen):
			_apply_custom_stat(chosen.stat_name, chosen.get("value", 0.0))

	chain.execute_next([])

func _apply_custom_stat(stat_name: String, val: float) -> void:
	if not Gvars:
		return
	if not ("custom_passives" in Gvars) or Gvars.custom_passives == null:
		Gvars.custom_passives = {}

	var passives = Gvars.custom_passives
	if passives is Dictionary:
		passives[stat_name] = passives.get(stat_name, 0.0) + val
