class_name BouncingBallProjectile
extends CharacterBody2D

const GRAVITY: float = 620.0
const BOUNCE_DAMPING: float = 0.76
const MAX_BLAST_RADIUS_TILES: float = 32.0

var base_damage: float = 95.0
var damage: float:
	get: return base_damage
	set(val): base_damage = val

var radius: float = 3.2
var tilemap: Node = null
var ball_texture: Texture2D = null

var _bounces_left: int = 5
var _fuse_timer: float = 3.5
var _total_bounces_made: int = 0
var _sprite: Sprite2D = null

func setup(pos: Vector2, initial_vel: Vector2, dmg: float, rad: float, tex: Texture2D) -> void:
	collision_layer = 0
	collision_mask = 1
	
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	var shape := CollisionShape2D.new()
	shape.shape = circle
	add_child(shape)
	
	_sprite = Sprite2D.new()
	add_child(_sprite)
	
	global_position = pos
	velocity = initial_vel
	base_damage = dmg
	radius = rad
	ball_texture = tex
	if _sprite and tex:
		_sprite.texture = tex
		_sprite.scale = Vector2(0.85, 0.85)

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	
	if _sprite:
		_sprite.rotation += velocity.x * delta * 0.04
	
	_fuse_timer -= delta
	if _fuse_timer <= 0.0:
		_detonate_final(global_position, base_damage)
		queue_free()
		return
		
	var collision = move_and_collide(velocity * delta)
	if collision:
		_total_bounces_made += 1
		_bounces_left -= 1
		velocity = velocity.bounce(collision.get_normal()) * BOUNCE_DAMPING
		
		var mult_bounce: float = 1.0 + (_total_bounces_made * 0.65)
		var mult_velocity: float = clampf(velocity.length() / 260.0, 0.8, 3.5)
		var mult_passives: float = 1.0
		if Gvars and ("passives" in Gvars) and Gvars.passives:
			var p = Gvars.passives
			var pick_dmg = float(p.player_pickaxe_mining_damage) if ("player_pickaxe_mining_damage" in p) else 0.0
			var ball_dmg = float(p.get("ball_blast_damage")) if ("ball_blast_damage" in p) else 0.0
			if ball_dmg == 0.0 and p.has_meta("ball_blast_damage"):
				ball_dmg = float(p.get_meta("ball_blast_damage"))
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
			tilemap = tm
	if tm and tm.has_method("damageTileCoords"):
		var cell = tm.local_to_map(pos)
		tm.damageTileCoords(cell, float(dmg))

func _detonate_final(pos: Vector2, dmg: float) -> void:
	var tm = tilemap
	if not is_instance_valid(tm):
		var tree = get_tree()
		if tree and tree.root:
			tm = tree.root.find_child("TileMapManager", true, false)
			tilemap = tm
			
	# Clamp blast radius to keep performance buttery smooth under extreme scaling
	var eff_radius: float = clampf(radius, 1.5, MAX_BLAST_RADIUS_TILES)
	var r_int: int = int(ceil(eff_radius))
	var r_sq: float = eff_radius * eff_radius

	# Spawn visual explosion boundary
	_spawn_blast_indicator(pos, eff_radius, tm)

	if tm and tm.has_method("damageTileCoords"):
		var center_cell = tm.local_to_map(pos)
		# Fast circular scanline traversal (Zero inner-loop Vector allocations)
		for dy in range(-r_int, r_int + 1):
			var dy_sq: float = float(dy * dy)
			if dy_sq > r_sq:
				continue
			var max_dx: int = int(sqrt(r_sq - dy_sq))
			for dx in range(-max_dx, max_dx + 1):
				var target_cell: Vector2i = center_cell + Vector2i(dx, dy)
				tm.damageTileCoords(target_cell, float(dmg))

func _spawn_blast_indicator(pos: Vector2, r_tiles: float, tm: Node) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return

	var tile_size_px: float = 16.0
	if tm and tm.has_method("map_to_local"):
		var p0: Vector2 = tm.map_to_local(Vector2i(0, 0))
		var p1: Vector2 = tm.map_to_local(Vector2i(1, 0))
		tile_size_px = max(8.0, abs(p1.x - p0.x))

	var blast_px: float = r_tiles * tile_size_px

	var ring := BlastRingVisual.new()
	ring.global_position = pos
	ring.target_radius = blast_px
	ring.z_index = 65
	tree.current_scene.add_child(ring)

class BlastRingVisual extends Node2D:
	var target_radius: float = 32.0
	var current_radius: float = 4.0
	var ring_color: Color = Color(1.0, 0.48, 0.15, 0.95)
	var duration: float = 0.32
	var elapsed: float = 0.0

	func _process(delta: float) -> void:
		elapsed += delta
		var t: float = elapsed / duration
		if t >= 1.0:
			queue_free()
			return
		# Fast outward shockwave explosion expansion
		current_radius = lerpf(6.0, target_radius, ease(t, -2.5))
		ring_color.a = (1.0 - t) * 0.9
		queue_redraw()

	func _draw() -> void:
		# Outer shockwave perimeter
		draw_arc(Vector2.ZERO, current_radius, 0.0, TAU, 48, ring_color, 3.5)
		# Translucent kinetic blast area fill
		var fill_color := ring_color
		fill_color.a *= 0.18
		draw_circle(Vector2.ZERO, current_radius, fill_color)
