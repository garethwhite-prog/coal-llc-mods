class_name WaterSpiritNode
extends Node2D

var orbit_radius: float = 48.0
var rotation_speed: float = 12.0
var brush_radius: int = 1
var fairy_texture: Texture2D = null

var tilemap = null
var player = null
var current_rotation: float = 0.0

var centre: Node2D
var orb: Sprite2D
var trail: Sprite2D

func _ready() -> void:
	z_index = 50

	centre = Node2D.new()
	centre.name = "Centre"
	add_child(centre)

	var use_texture = fairy_texture
	if not use_texture:
		use_texture = load("res://assets/Equipment/kicks/kick_04_sapphire.png")

	orb = Sprite2D.new()
	orb.name = "Orb"
	orb.texture = use_texture
	orb.scale = Vector2(1.5, 1.5)
	orb.position = Vector2(orbit_radius, 0.0)
	centre.add_child(orb)

	trail = Sprite2D.new()
	trail.name = "Trail"
	trail.texture = use_texture
	trail.modulate = Color(0.1, 0.6, 1.0, 0.4)
	trail.scale = Vector2(1.0, 1.0)
	trail.position = Vector2(orbit_radius * 0.95, -12.0)
	centre.add_child(trail)

	_resolve_tilemap()

func _resolve_tilemap() -> void:
	if player and ("tilemap" in player) and player.tilemap:
		tilemap = player.tilemap

func _physics_process(delta: float) -> void:
	current_rotation += rotation_speed * delta
	if centre:
		centre.rotation = current_rotation

	if not tilemap:
		_resolve_tilemap()
		if not tilemap:
			return

	if orb:
		var tip_pos: Vector2 = orb.global_position
		var map_pos: Vector2i = tilemap.local_to_map(tilemap.to_local(tip_pos))
		for dx in range(-brush_radius, brush_radius + 1):
			for dy in range(-brush_radius, brush_radius + 1):
				var cell = map_pos + Vector2i(dx, dy)
				if tilemap.has_method("damageTileCoords"):
					tilemap.damageTileCoords(cell, 25.0)
