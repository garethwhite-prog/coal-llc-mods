class_name VoidCoreEquipEffect
extends EquipEffect

@export var pulse_damage: float = 120.0
@export var pulse_radius: int = 4

func physics_process(player, _delta):
	if Input.is_action_just_pressed("useItem"):
		var tilemap = player.tilemap
		if not tilemap:
			return
		var center := tilemap.local_to_map(player.global_position)
		for dx in range(-pulse_radius, pulse_radius + 1):
			for dy in range(-pulse_radius, pulse_radius + 1):
				var pos := center + Vector2i(dx, dy)
				if tilemap.is_tile_collision(pos):
					tilemap.damageTileCoords(pos, pulse_damage)