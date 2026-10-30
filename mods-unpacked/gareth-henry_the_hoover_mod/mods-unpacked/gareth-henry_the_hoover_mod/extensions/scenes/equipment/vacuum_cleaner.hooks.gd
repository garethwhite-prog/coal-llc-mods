extends Object

func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	chain.execute_next([delta])
	var vac = chain.reference_object
	if not is_instance_valid(vac):
		return

	var factory = load("res://mods-unpacked/gareth-henry_the_hoover_mod/scripts/henry_texture_factory.gd")
	if not factory:
		return

	var vac_end = vac.find_child("VacuumEnd", true, false)
	if is_instance_valid(vac_end) and vac_end is Sprite2D:
		var lvl: int = 1
		if Gvars and ("bonus_equipment_manager" in Gvars) and Gvars.bonus_equipment_manager:
			lvl = int(Gvars.bonus_equipment_manager.vacuum_level) if ("vacuum_level" in Gvars.bonus_equipment_manager) else 1

		# Apply texture on initialization or tier upgrade
		if vac.get_meta("henry_applied_lvl", 0) != lvl:
			vac.set_meta("henry_applied_lvl", lvl)
			vac_end.texture = factory.create_henry_texture(lvl)
			vac_end.scale = Vector2(1.5, 1.5)
