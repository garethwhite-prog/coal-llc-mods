extends Object

func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	var axe = chain.reference_object
	if axe and Gvars and ("passives" in Gvars) and Gvars.passives:
		var p = Gvars.passives
		if "axe_speed" in p:
			var spd_mult: float = 1.0 + float(p.axe_speed)
			if "rotation_speed" in axe and axe.on:
				axe.rotation_speed = min(axe.rotation_speed * spd_mult, 13.0 * spd_mult)
	chain.execute_next([delta])