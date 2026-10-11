class_name VoidSiphonEquipEffect
extends EquipEffect

func physics_process(player, _delta):
	if Input.is_action_just_pressed("useItem") or Input.is_action_just_pressed("fire"):
		_trigger_implosion(player)

func _trigger_implosion(player) -> void:
	var tilemap = player.tilemap
	if not tilemap:
		return
	var center := tilemap.local_to_map(player.global_position)
	for dx in range(-3, 4):
		for dy in range(-3, 4):
			var pos := center + Vector2i(dx, dy)
			if tilemap.is_tile_collision(pos):
				tilemap.damage_tile(pos, 85.0)