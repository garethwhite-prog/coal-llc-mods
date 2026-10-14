class_name BouncingBallProjectile
extends CharacterBody2D

const GRAVITY: float = 620.0
const BOUNCE_DAMPING: float = 0.76

var damage: float = 95.0
var radius: float = 3.0
var ball_texture: Texture2D = null
var tilemap = null

var _fuse_timer: float = 1.5
var _bounces_left: int = 4
var _sprite: Sprite2D = null
var _is_detonated: bool = false

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = ball_texture
	add_child(_sprite)

	var shape := CircleShape2D.new()
	shape.radius = 5.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)

func _physics_process(delta: float) -> void:
	if _is_detonated:
		return

	velocity.y += GRAVITY * delta
	if _sprite:
		_sprite.rotation += velocity.x * delta * 0.06

	_fuse_timer -= delta
	if _fuse_timer <= 0.0:
		_detonate()
		return

	var collision := move_and_collide(velocity * delta)
	if collision:
		_bounces_left -= 1
		velocity = velocity.bounce(collision.get_normal()) * BOUNCE_DAMPING

		if ResourceLoader.exists("res://assets/sound/sound effects/SwordThud.wav"):
			var audio := AudioStreamPlayer2D.new()
			audio.stream = load("res://assets/sound/sound effects/SwordThud.wav")
			audio.pitch_scale = randf_range(1.3, 1.6)
			get_parent().add_child(audio)
			audio.play()
			audio.finished.connect(audio.queue_free)

		# Impact damage on ricochet
		_damage_at_pos(collision.get_position() - (collision.get_normal() * 4.0), damage * 0.4)

		if _bounces_left <= 0 or velocity.length() < 25.0:
			_detonate()

func _damage_at_pos(pos: Vector2, dmg: float) -> void:
	if not tilemap:
		return
	var cell: Vector2i = tilemap.local_to_map(pos)
	if tilemap.is_tile_breakable(cell):
		tilemap.damageTileCoords(cell, dmg)

func _detonate() -> void:
	if _is_detonated:
		return
	_is_detonated = true
	set_physics_process(false)

	if ResourceLoader.exists("res://assets/sound/sound effects/bombExplode.wav"):
		var audio := AudioStreamPlayer2D.new()
		audio.stream = load("res://assets/sound/sound effects/bombExplode.wav")
		audio.pitch_scale = randf_range(0.85, 1.1)
		get_parent().add_child(audio)
		audio.play()
		audio.finished.connect(audio.queue_free)

	_spawn_blast_shockwave()

	if tilemap:
		var cell_center: Vector2i = tilemap.local_to_map(global_position)
		var r_int: int = int(ceil(radius))
		for dx in range(-r_int, r_int + 1):
			for dy in range(-r_int, r_int + 1):
				if Vector2(dx, dy).length() <= radius:
					var cell: Vector2i = cell_center + Vector2i(dx, dy)
					if tilemap.is_tile_breakable(cell):
						tilemap.damageTileCoords(cell, damage)

	queue_free()

func _spawn_blast_shockwave() -> void:
	var ring := Line2D.new()
	ring.width = 3.0
	ring.default_color = Color(1.0, 0.65, 0.15, 0.95)
	var segs: int = 16
	for i in range(segs + 1):
		var ang: float = float(i) * TAU / float(segs)
		ring.add_point(global_position + Vector2(cos(ang), sin(ang)) * 5.0)
	get_parent().add_child(ring)

	var tween = get_parent().create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(3.5, 3.5), 0.16)
	tween.tween_property(ring, "modulate:a", 0.0, 0.16)
	tween.set_parallel(false)
	tween.tween_callback(ring.queue_free)