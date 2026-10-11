class_name LaserEquipEffect
extends EquipEffect

var beam_node: LaserBeamWeapon = null

func start(player, _item):
	var script_res = load("res://mods-unpacked/gareth-laser_beam_mod/scripts/laser_beam_weapon.gd")
	beam_node = Node2D.new()
	beam_node.set_script(script_res)
	player.add_child(beam_node)

func end(player):
	if beam_node != null and is_instance_valid(beam_node):
		beam_node.stop_beam()
		beam_node.queue_free()
		beam_node = null

func physics_process(player, _delta):
	if beam_node == null:
		return
	if Input.is_action_pressed("useItem") or Input.is_action_pressed("fire"):
		beam_node.fire_beam(player.global_position, player.pointer_global_pos, player.tilemap)
	else:
		beam_node.stop_beam()