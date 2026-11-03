class_name BouncingBallProjectile
extends CharacterBody2D

const GRAVITY: float = 620.0
const BOUNCE_DAMPING: float = 0.76
const MAX_BLAST_RADIUS_TILES: float = 20.0

var base_damage: float = 95.0
var damage: float:
	get: return base_damage
	set(val): base_damage = val

var radius: float = 3.2
var tilemap: Node = null

var ball_texture: Texture2D = null:
	set(val):
		ball_texture = val
		if _sprite and is_instance_valid(_sprite) and val:
			_sprite.texture = val

var _bounces_left: int = 4
var _fuse_timer: float = 1.4
var _total_bounces_made: int = 0
var _sprite: Sprite2D = null

func _ready() -> void:
	z_index = 35
	collision_layer = 0
	collision_mask = 1

	_sprite = Sprite2D.new()
	_sprite.name = "Sprite2D"
	if ball_texture:
		_sprite.texture = ball_texture
		_sprite.scale = Vector2(0.85, 0.85)
	add_child(_sprite)

	var circle := CircleShape2D.new()
	circle.radius = 7.0
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	shape.shape = circle
	add_child(shape)

func setup(pos: Vector2, initial_vel: Vector2, dmg: float, tex: Texture2D) -> void:
	global_position = pos
	velocity = initial_vel
	base_damage = dmg
	ball_texture = tex
	if _sprite and is_instance_valid(_sprite) and tex:
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
		_total_bounces_made += 1
		_bounces_left -= 1
		velocity = velocity.bounce(collision.get_normal()) * BOUNCE_DAMPING

		var mult_bounce: float = 1.0 + (_total_bounces_made * 0.65)
		var mult_velocity: float = clampf(velocity.length() / 260.0, 0.8, 3.5)
		var mult_passives: float = 1.0
		if Gvars and ("passives" in Gvars) and Gvars.passives:
			var p = Gvars.passives
			var pick_dmg: float = 0.0
			if "player_pickaxe_mining_damage" in p:
				pick_dmg = float(p.player_pickaxe_mining_damage)
			elif "pickaxe_damage" in p:
				pick_dmg = float(p.pickaxe_damage)

			var ball_dmg: float = 0.0
			if "ball_blast_damage" in p:
				ball_dmg = float(p.get("ball_blast_damage"))
			elif p.has_meta("ball_blast_damage"):
				ball_dmg = float(p.get_meta("ball_blast_damage"))

			mult_passives = (1.0 + pick_dmg) * (1.0 + ball_dmg)

		var final_damage: float = base_damage * mult_bounce * mult_velocity * mult_passives
		var hit_pos: Vector2 = collision.get_position() - (collision.get_normal() * 4.0)
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

	# Clamp maximum blast radius to maintain steady framerate under deep stratum scaling
	var eff_radius: float = clampf(radius, 1.5, MAX_BLAST_RADIUS_TILES)

	# Trigger visual shockwave ring scaled to the explosion's exact perimeter
	_spawn_blast_shockwave(pos, eff_radius)

	if tm and tm.has_method("damageTileCoords"):
		var center_cell = tm.local_to_map(pos)
		var r_int: int = int(ceil(eff_radius))
		var r_sq: float = eff_radius * eff_radius

		# Circular scanline loop: avoids outer corner checks and inner-loop Vector allocations
		for dy in range(-r_int, r_int + 1):
			var dy_sq: float = float(dy * dy)
			if dy_sq > r_sq:
				continue
			var max_dx: int = int(sqrt(r_sq - dy_sq))
			for dx in range(-max_dx, max_dx + 1):
				tm.damageTileCoords(center_cell + Vector2i(dx, dy), float(dmg))

func _spawn_blast_shockwave(pos: Vector2, r_tiles: float) -> void:
	var ring := Line2D.new()
	ring.width = 4.0
	ring.default_color = Color(1.0, 0.60, 0.12, 0.95)
	ring.z_index = 50

	var segs: int = 32
	var r_px: float = max(24.0, r_tiles * 16.0)
	for i in range(segs + 1):
		var ang: float = float(i) * TAU / float(segs)
		ring.add_point(Vector2(cos(ang), sin(ang)) * r_px)

	ring.global_position = pos

	var parent = get_parent()
	if not parent:
		var tree = get_tree()
		if tree and tree.current_scene:
			parent = tree.current_scene
	if parent:
		parent.add_child(ring)
		var tween = parent.create_tween()
		if tween:
			tween.set_parallel(true)
			ring.scale = Vector2(0.15, 0.15)
			tween.tween_property(ring, "scale", Vector2(1.0, 1.0), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(ring, "modulate:a", 0.0, 0.24)
			tween.set_parallel(false)
			tween.tween_callback(ring.queue_free)
