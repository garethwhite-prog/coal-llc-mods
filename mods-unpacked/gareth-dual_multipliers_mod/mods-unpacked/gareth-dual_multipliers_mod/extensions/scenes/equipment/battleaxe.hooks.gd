extends Object

func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	var baxe = chain.reference_object
	if baxe and Gvars and ("passives" in Gvars) and Gvars.passives:
		var p = Gvars.passives
		if "axe_speed" in p:
			var spd_mult: float = 1.0 + float(p.axe_speed)
			if "rotation_speed" in baxe and baxe.on:
				baxe.rotation_speed = min(baxe.rotation_speed * spd_mult, 7.0 * spd_mult)
	chain.execute_next([delta])