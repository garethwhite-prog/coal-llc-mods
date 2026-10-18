class_name HydrothermalVent
extends Node2D

var steam_particles: CPUParticles2D
var launch_cooldown: float = 0.0

func _ready() -> void:
	z_index = 5
	
	# Basalt Chimney
	var chimney = ColorRect.new()
	chimney.color = Color(0.10, 0.12, 0.16)
	chimney.size = Vector2(16, 24)
	chimney.position = Vector2(-8, -24)
	add_child(chimney)

	var vent_rim = ColorRect.new()
	vent_rim.color = Color(0.18, 0.22, 0.30)
	vent_rim.size = Vector2(22, 6)
	vent_rim.position = Vector2(-11, -26)
	add_child(vent_rim)

	# Upward Hydrothermal Steam Column
	steam_particles = CPUParticles2D.new()
	steam_particles.position = Vector2(0, -26)
	steam_particles.amount = 32
	steam_particles.lifetime = 1.8
	steam_particles.direction = Vector2(0, -1)
	steam_particles.spread = 10.0
	steam_particles.gravity = Vector2(0, -160)
	steam_particles.initial_velocity_min = 80.0
	steam_particles.initial_velocity_max = 150.0
	steam_particles.scale_amount_min = 3.0
	steam_particles.scale_amount_max = 6.0
	steam_particles.color = Color(0.70, 0.90, 1.0, 0.65)
	add_child(steam_particles)

func _physics_process(delta: float) -> void:
	if launch_cooldown > 0.0:
		launch_cooldown -= delta

	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return

	var p = players[0]
	if not is_instance_valid(p):
		return

	# Launch zone: 28px wide, extends 120px vertically above chimney
	var diff = p.global_position - global_position
	if abs(diff.x) < 18.0 and diff.y < -5.0 and diff.y > -120.0:
		if launch_cooldown <= 0.0 and "velocity" in p:
			p.velocity.y = -720.0
			launch_cooldown = 0.30
