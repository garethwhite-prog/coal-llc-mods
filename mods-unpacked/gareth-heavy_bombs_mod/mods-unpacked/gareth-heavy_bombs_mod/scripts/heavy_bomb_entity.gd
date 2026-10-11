class_name HeavyBombEntity
extends RigidBody2D

@export var blast_radius: float = 20.0
@export var blast_damage: float = 1200.0
@export var fuse_time: float = 3.0
@export var texture_path: String = "res://assets/Equipment/bombs/big_bomb_sheet.png"

var _timer: float = 0.0
var sprite: Sprite2D
var audio_explode: AudioStreamPlayer2D

func _ready() -> void:
	gravity_scale = 1.2
	sprite = Sprite2D.new()
	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
		sprite.hframes = 4
	add_child(sprite)

	audio_explode = AudioStreamPlayer2D.new()
	if ResourceLoader.exists("res://assets/sound/sound effects/bombExplode.wav"):
		audio_explode.stream = load("res://assets/sound/sound effects/bombExplode.wav")
	add_child(audio_explode)

func _physics_process(delta: float) -> void:
	_timer += delta
	if sprite.hframes > 1:
		sprite.frame = int((_timer / fuse_time) * (sprite.hframes - 1)) % sprite.hframes

	if _timer >= fuse_time:
		_detonate()

func _detonate() -> void:
	set_physics_process(false)
	visible = false
	audio_explode.play()
	var dmg: float = blast_damage * (1.0 + (Gvars.passives.bomb_damage if Gvars and "passives" in Gvars else 0.0))
	Bus.BombExplode.emit(global_position, blast_radius, dmg)
	await audio_explode.finished
	queue_free()