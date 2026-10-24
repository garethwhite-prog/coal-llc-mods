class_name WaterSpiritEquipEffect
extends EquipEffect

@export var orbit_radius: float = 48.0
@export var rotation_speed: float = 12.0
@export var brush_radius: int = 1

func start(_player, _item):
	pass

func end(_player):
	# Mirrors vanilla roundhouse kick: switching hotbar weapons leaves the active companion running
	pass

func physics_process(player, _delta):
	if not player:
		return

	var toggle_pressed: bool = false
	if Input.is_action_just_pressed("useItem") or Input.is_action_just_pressed("toggle_use_item"):
		toggle_pressed = true

	if toggle_pressed:
		var existing = player.get_node_or_null("ActiveWaterSpirit")
		if existing and is_instance_valid(existing):
			existing.queue_free()
		else:
			_spawn_spirit(player)

func _spawn_spirit(player) -> void:
	var spirit_script = load("res://mods-unpacked/gareth-water_spirit_mod/scripts/water_spirit_node.gd")
	var spirit = Node2D.new()
	spirit.name = "ActiveWaterSpirit"
	spirit.set_script(spirit_script)
	spirit.orbit_radius = orbit_radius
	spirit.rotation_speed = rotation_speed
	spirit.brush_radius = brush_radius
	spirit.player = player
	if "tilemap" in player:
		spirit.tilemap = player.tilemap

	player.call_deferred("add_child", spirit)
