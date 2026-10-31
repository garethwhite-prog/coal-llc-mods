extends Object

func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	var vac = chain.reference_object
	if is_instance_valid(vac):
		if not vac.has_meta("henry_initialized"):
			vac.set_meta("henry_initialized", true)
			vac.set_meta("gobble_cooldown", 0.0)
			
			var lvl: int = 1
			if Gvars and ("bonus_equipment_manager" in Gvars) and Gvars.bonus_equipment_manager:
				if "vacuum_level" in Gvars.bonus_equipment_manager:
					lvl = int(Gvars.bonus_equipment_manager.vacuum_level)
					
			var sprite = vac.get_node_or_null("Sprite2D")
			if sprite:
				var factory = load("res://mods-unpacked/gareth-henry_the_hoover_mod/helpers/henry_texture_factory.gd")
				if factory and factory.has_method("apply_henry_skin"):
					factory.apply_henry_skin(sprite, lvl)

		var cd = float(vac.get_meta("gobble_cooldown", 0.0))
		if cd > 0.0:
			vac.set_meta("gobble_cooldown", cd - delta)
			
		var audio = vac.get_node_or_null("AudioStreamPlayer2D")
		if is_instance_valid(audio) and audio.playing:
			if cd > 0.0:
				audio.volume_db = -80.0
			else:
				audio.volume_db = 0.0
				vac.set_meta("gobble_cooldown", 1.0)

	chain.execute_next([delta])
