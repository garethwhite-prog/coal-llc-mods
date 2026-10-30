extends Object

var _gobble_timer: float = 0.0

func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	chain.execute_next([delta])
	var vac = chain.reference_object
	if not is_instance_valid(vac):
		return

	if _gobble_timer > 0.0:
		_gobble_timer -= delta

	var factory = load("res://mods-unpacked/gareth-henry_the_hoover_mod/scripts/henry_texture_factory.gd")
	if not factory:
		return

	var vac_end = vac.find_child("VacuumEnd", true, false)
	if is_instance_valid(vac_end) and vac_end is Sprite2D:
		var lvl: int = 1
		if Gvars and ("bonus_equipment_manager" in Gvars) and Gvars.bonus_equipment_manager:
			lvl = int(Gvars.bonus_equipment_manager.vacuum_level) if ("vacuum_level" in Gvars.bonus_equipment_manager) else 1

		if vac.get_meta("henry_applied_lvl", 0) != lvl:
			vac.set_meta("henry_applied_lvl", lvl)
			vac_end.texture = factory.create_henry_texture(lvl)
			vac_end.scale = Vector2(0.9, 0.9)
			vac_end.offset = Vector2(0, -8)

	# 1.0s Rate-Limited Gobble Sound when collection is active
	if ("attached" in vac) and vac.attached and _gobble_timer <= 0.0:
		var vac_audio = vac.find_child("VacuumAudio", true, false)
		if is_instance_valid(vac_audio) and vac_audio is AudioStreamPlayer2D and vac_audio.playing:
			_trigger_gobble(vac)
			_gobble_timer = 1.0

func _trigger_gobble(vac: Node2D) -> void:
	var tw = vac.create_tween()
	var vac_end = vac.find_child("VacuumEnd", true, false)
	if is_instance_valid(vac_end):
		tw.tween_property(vac_end, "scale", Vector2(1.05, 0.75), 0.12)
		tw.tween_property(vac_end, "scale", Vector2(0.9, 0.9), 0.15)
