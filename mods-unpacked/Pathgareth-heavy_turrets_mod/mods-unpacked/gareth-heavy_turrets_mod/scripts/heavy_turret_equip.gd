class_name HeavyTurretEquipEffect
extends EquipEffect

func physics_process(player, _delta):
	if Input.is_action_just_pressed("useItem") or Input.is_action_just_pressed("fire"):
		var script_res = load("res://mods-unpacked/gareth-heavy_turrets_mod/scripts/heavy_turret_entity.gd")
		var turret = Node2D.new()
		turret.set_script(script_res)
		turret.global_position = player.global_position
		player.get_parent().add_child(turret)