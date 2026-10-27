extends Object

func _physics_process(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var miner = chain.reference_object
	if not is_instance_valid(miner): return

	var spr = miner.find_child("Sprite2D", true, false)
	if is_instance_valid(spr) and spr is Sprite2D:
		var col_idx = int(miner.get_instance_id()) % 4
		match col_idx:
			0: spr.self_modulate = Color(0.50, 0.15, 0.85, 1.0) # Tinky Winky (Purple)
			1: spr.self_modulate = Color(0.15, 0.75, 0.15, 1.0) # Dipsy (Green)
			2: spr.self_modulate = Color(0.95, 0.85, 0.10, 1.0) # Laa-Laa (Yellow)
			_: spr.self_modulate = Color(0.95, 0.10, 0.10, 1.0) # Po (Red)
