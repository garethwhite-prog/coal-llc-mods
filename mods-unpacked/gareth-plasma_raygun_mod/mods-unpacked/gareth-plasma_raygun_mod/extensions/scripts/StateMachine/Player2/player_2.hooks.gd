extends Object

func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	chain.execute_next([delta])
	var player = chain.reference_object
	if not player:
		return

	var reg = load("res://mods-unpacked/gareth-mod_manager_mod/scripts/mod_registry.gd")
	if reg and not reg.is_mod_active_for_run("plasma_raygun"):
		return

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var p_pos: Vector2 = player.global_position
		var pointer_pos: Vector2 = player.pointer_global_pos
		var dir: Vector2 = (pointer_pos - p_pos).normalized()
		var tilemap = player.tilemap
		if tilemap:
			for i in range(1, 16):
				var target_pos: Vector2 = p_pos + dir * (i * 16.0)
				tilemap.damageTile(target_pos, 45.0)