class_name BouncingBallProjectile
extends CharacterBody2D

const GRAVITY: float = 620.0
const BOUNCE_DAMPING: float = 0.76
var base_damage: float = 95.0

var damage: float:
	get: return base_damage
	set(val): base_damage = val

var radius: float = 16.0
var tilemap: Node = null
var ball_texture: Texture2D = null

var _bounces_left: int = 4
var _total_bounces_made: int = 0
var _sprite: Sprite2D = null
var _fuse_timer: float = 1.4

func _ready() -> void:
	z_index = 35
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite2D"
	if ball_texture:
		_sprite.texture = ball_texture
	add_child(_sprite)
	
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	var shape := CollisionShape2D.new()
	shape.shape = circle
	
	# Explicitly set Godot 2D collision masks to interact with the TileMap
	collision_layer = 0
	collision_mask = 1 
	
	add_child(shape)

func setup(pos: Vector2, initial_vel: Vector2, dmg: float, tex: Texture2D) -> void:
	global_position = pos
	velocity = initial_vel
	base_damage = dmg
	ball_texture = tex
	if _sprite and tex:
		_sprite.texture = tex

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	if _sprite:
		_sprite.rotation += velocity.x * delta * 0.08
		
	_fuse_timer -= delta
	if _fuse_timer <= 0.0:
		_detonate_final(global_position, base_damage)
		queue_free()
		return

	var collision := move_and_collide(velocity * delta)
	if collision:
		_bounces_left -= 1
		_total_bounces_made += 1
		velocity = velocity.bounce(collision.get_normal()) * BOUNCE_DAMPING

		var mult_bounce: float = 1.0 + (_total_bounces_made * 0.65)
		var mult_velocity: float = clampf(velocity.length() / 260.0, 0.8, 3.5)
		var mult_passives: float = 1.0
		if Gvars and ("passives" in Gvars) and Gvars.passives:
			var p = Gvars.passives
			var pick_dmg = float(p.pickaxe_damage) if ("pickaxe_damage" in p) else 0.0
			var ball_dmg = float(p.get("bouncing_ball_damage")) if ("bouncing_ball_damage" in p) else 0.0
			mult_passives = (1.0 + pick_dmg) * (1.0 + ball_dmg)

		var final_damage: float = base_damage * mult_bounce * mult_velocity * mult_passives
		var hit_pos = collision.get_position() - (collision.get_normal() * 4.0)
		_damage_at_pos(hit_pos, final_damage * 0.45)

		if _bounces_left <= 0 or velocity.length() < 25.0:
			_detonate_final(hit_pos, final_damage)
			queue_free()

func _damage_at_pos(pos: Vector2, dmg: float) -> void:
	var tm = tilemap
	if not is_instance_valid(tm):
		var tree = get_tree()
		if tree and tree.root:
			tm = tree.root.find_child("TileMapManager", true, false)
	if tm and tm.has_method("damageTileCoords"):
		var cell = tm.local_to_map(pos)
		tm.damageTileCoords(cell, float(dmg))

func _detonate_final(pos: Vector2, dmg: float) -> void:
	call_deferred("_spawn_blast_shockwave")
	var tm = tilemap
	if not is_instance_valid(tm):
		var tree = get_tree()
		if tree and tree.root:
			tm = tree.root.find_child("TileMapManager", true, false)
	if tm and tm.has_method("damageTileCoords"):
		var center_cell = tm.local_to_map(pos)
		var r_int: int = int(ceil(radius))
		for dx in range(-r_int, r_int + 1):
			for dy in range(-r_int, r_int + 1):
				if Vector2(dx, dy).length() <= radius:
					tm.damageTileCoords(center_cell + Vector2i(dx, dy), float(dmg))

func _spawn_blast_shockwave() -> void:
	var ring := Line2D.new()
	ring.width = 3.0
	ring.default_color = Color(1.0, 0.65, 0.15, 0.95)
	var segs: int = 16
	for i in range(segs + 1):
		var ang: float = float(i) * TAU / float(segs)
		ring.add_point(global_position + Vector2(cos(ang), sin(ang)) * 5.0)
	
	var parent = get_parent()
	if parent:
		parent.add_child(ring)
		var tween = parent.create_tween()
		if tween:
			tween.set_parallel(true)
			tween.tween_property(ring, "scale", Vector2(3.5, 3.5), 0.16)
			tween.tween_property(ring, "modulate:a", 0.0, 0.16)
			tween.set_parallel(false)
			tween.tween_callback(ring.queue_free)


