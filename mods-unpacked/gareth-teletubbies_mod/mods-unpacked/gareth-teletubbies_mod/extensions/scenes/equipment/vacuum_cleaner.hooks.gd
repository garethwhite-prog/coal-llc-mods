extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var vac = chain.reference_object
	if not is_instance_valid(vac):
		return

	var factory = load("res://mods-unpacked/gareth-teletubbies_mod/scripts/teletubbies_texture_factory.gd")
	if not factory:
		return

	var vac_end = vac.find_child("VacuumEnd", true, false)
	if is_instance_valid(vac_end) and vac_end is Sprite2D:
		var lvl: int = 1
		if Gvars and ("bonus_equipment_manager" in Gvars) and Gvars.bonus_equipment_manager:
			lvl = int(Gvars.bonus_equipment_manager.vacuum_level) if ("vacuum_level" in Gvars.bonus_equipment_manager) else 1
		vac_end.texture = factory.create_noo_noo_texture(lvl)
		vac_end.scale = Vector2(1.5, 1.5)

