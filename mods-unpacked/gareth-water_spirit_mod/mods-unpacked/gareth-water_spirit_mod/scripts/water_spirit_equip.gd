class_name WaterSpiritEquipEffect
extends EquipEffect

@export var orbit_radius: float = 48.0
@export var rotation_speed: float = 12.0
@export var brush_radius: int = 1

var _active_spirit: Node2D = null

func start(player, _item):
	end(player)
	var spirit_script = load("res://mods-unpacked/gareth-water_spirit_mod/scripts/water_spirit_node.gd")
	_active_spirit = Node2D.new()
	_active_spirit.name = "ActiveWaterSpirit"
	_active_spirit.set_script(spirit_script)
	_active_spirit.orbit_radius = orbit_radius
	_active_spirit.rotation_speed = rotation_speed
	_active_spirit.brush_radius = brush_radius
	_active_spirit.player = player
	if "tilemap" in player:
		_active_spirit.tilemap = player.tilemap

	player.call_deferred("add_child", _active_spirit)

func end(player):
	if _active_spirit and is_instance_valid(_active_spirit):
		_active_spirit.queue_free()
		_active_spirit = null
	if player:
		var existing = player.get_node_or_null("ActiveWaterSpirit")
		if existing:
			existing.queue_free()

func physics_process(player, _delta):
	if player and (not _active_spirit or not is_instance_valid(_active_spirit)):
		if not player.get_node_or_null("ActiveWaterSpirit"):
			start(player, null)