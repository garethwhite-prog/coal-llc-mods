class_name HydrothermalVent
extends Node2D

var steam_particles: CPUParticles2D
var trigger_area: Area2D
var launch_cooldown: float = 0.0

func _ready() -> void:
	z_index = 5
	
	# Chimney Visuals
	var chimney = ColorRect.new()
	chimney.color = Color(0.12, 0.12, 0.15)
	chimney.size = Vector2(16, 24)
	chimney.position = Vector2(-8, -24)
	add_child(chimney)

	var vent_rim = ColorRect.new()
	vent_rim.color = Color(0.2, 0.22, 0.28)
	vent_rim.size = Vector2(20, 6)
	vent_rim.position = Vector2(-10, -26)
	add_child(vent_rim)

	# Upward Hydrothermal Steam Emitter
	steam_particles = CPUParticles2D.new()
	steam_particles.position = Vector2(0, -26)
	steam_particles.amount = 24
	steam_particles.lifetime = 1.6
	steam_particles.direction = Vector2(0, -1)
	steam_particles.spread = 12.0
	steam_particles.gravity = Vector2(0, -140)
	steam_particles.initial_velocity_min = 70.0
	steam_particles.initial_velocity_max = 130.0
	steam_particles.scale_amount_min = 2.5
	steam_particles.scale_amount_max = 5.0
	steam_particles.color = Color(0.65, 0.85, 1.0, 0.55)
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

	# Launch column: 24px wide, extends 90px vertically upward from chimney
	var diff = p.global_position - global_position
	if abs(diff.x) < 14.0 and diff.y < -10.0 and diff.y > -95.0:
		if launch_cooldown <= 0.0 and "velocity" in p:
			p.velocity.y = -680.0
			launch_cooldown = 0.35
