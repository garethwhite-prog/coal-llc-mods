class_name BouncingGrenade
extends CharacterBody2D

const GRAVITY: float = 580.0
const BOUNCE_DAMPING: float = 0.65
const BOMB_EXPLODE = preload("res://assets/sound/sound effects/bombExplode.wav")

var damage: float = 100.0
var radius: float = 4.0
var fuse_time: float = 2.5
var bomb_texture: Texture2D

var _timer: float = 0.0
var _audio: AudioStreamPlayer2D
var _sprite: Sprite2D

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = bomb_texture
	add_child(_sprite)

	_audio = AudioStreamPlayer2D.new()
	_audio.stream = BOMB_EXPLODE
	add_child(_audio)

	# Setup simple 8x8 circle collision
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	_sprite.rotation += velocity.x * delta * 0.05

	var collision := move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal()) * BOUNCE_DAMPING
		if velocity.length() < 15.0:
			velocity = Vector2.ZERO

	_timer += delta
	# Flashing visual near explosion
	if _timer > (fuse_time - 0.75):
		_sprite.modulate = Color.RED if int(_timer * 12) % 2 == 0 else Color.WHITE

	if _timer >= fuse_time:
		explode()

func explode() -> void:
	set_physics_process(false)
	Bus.BombExplode.emit(global_position, radius, damage * (1.0 + Gvars.passives.bomb_damage))
	if Gvars.bonus_equipment_manager.apply_knockback or Gvars.bonus_equipment_manager.apply_bomb_knockback:
		var tree = get_tree()
		if tree:
			var player = tree.get_first_node_in_group("player")
			if player and "apply_knockback" in player:
				player.apply_knockback()
	_audio.play()
	visible = false
	var t = get_tree().create_tween()
	t.tween_interval(0.6)
	t.tween_callback(queue_free)