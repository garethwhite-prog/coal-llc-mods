class_name ThomasTrainManager
extends Node2D

var left_stop: float = 64.0
var right_stop: float = 880.0
var speed: float = 140.0
var direction: float = 1.0

# Shop Exposed Configuration Variables
@export var loco_tier: int = 1
@export var wagon_count: int = 2
@export var wagon_capacity: float = 150.0

var current_haul: float = 0.0

var loco_sprite: Sprite2D
var wagons: Array[Sprite2D] = []

func _ready() -> void:
	z_index = 20
	position = Vector2(left_stop, 24.0)

	loco_sprite = Sprite2D.new()
	loco_sprite.scale = Vector2(1.8, 1.8)
	call_deferred("add_child", loco_sprite)
