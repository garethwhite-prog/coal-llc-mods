class_name WaterSpiritNode
extends Node2D

var orbit_radius: float = 48.0
var rotation_speed: float = 12.0
var brush_radius: int = 1

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

	var orb_texture = load("res://assets/Equipment/kicks/kick_04_sapphire.png")

	orb = Sprite2D.new()
	orb.name = "Orb"
	orb.texture = orb_texture
	orb.modulate = Color(0.2, 0.85, 1.0, 1.0)
	orb.scale = Vector2(1.5, 1.5)
	orb.position = Vector2(orbit_radius, 0.0)
	centre.add_child(orb)

	trail = Sprite2D.new()
	trail.name = "Trail"
	trail.texture = orb_texture
	trail.modulate = Color(0.1, 0.6, 1.0, 0.5)
	trail.scale = Vector2(1.0, 1.0)
	trail.position = Vector2(orbit_radius * 0.95, -12.0)
	centre.add_child(trail)

	_resolve_tilemap()

func _resolve_tilemap() -> void:
	if player and ("tilemap" in player) and player.tilemap:
		tilemap = player.tilemap
		return
	var tree = get_tree()
	if tree:
		var p = tree.get_first_node_in_group("player")
		if p and ("tilemap" in p) and p.tilemap:
			tilemap = p.tilemap
			return
		if Game and ("current_node" in Game) and Game.current_node:
			if "tilemap" in Game.current_node and Game.current_node.tilemap:
				tilemap = Game.current_node.tilemap

func _physics_process(delta: float) -> void:
	current_rotation += rotation_speed * delta
	if centre:
		centre.rotation = current_rotation

	if not tilemap:
		_resolve_tilemap()
		if not tilemap:
			return

	if orb:
		var orb_pos: Vector2 = orb.global_position
		if tilemap.has_method("local_to_map") and tilemap.has_method("wet_tile_coords"):
			var center_tile: Vector2i = tilemap.local_to_map(orb_pos)
			for dx in range(-brush_radius, brush_radius + 1):
				for dy in range(-brush_radius, brush_radius + 1):
					if (dx * dx + dy * dy) <= (brush_radius * brush_radius):
						tilemap.wet_tile_coords(center_tile + Vector2i(dx, dy))
		elif tilemap.has_method("wet_tile"):
			tilemap.wet_tile(orb_pos)