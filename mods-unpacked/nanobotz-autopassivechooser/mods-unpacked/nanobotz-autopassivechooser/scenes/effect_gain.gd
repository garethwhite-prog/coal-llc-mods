class_name EffectGain
extends Node2D


@onready var effect_text: Label = %EffectText

@export var duration: float = 3
@export var y_movement: float = 40

var time: float = 0
var y_per_second: float = 0
var opacity_per_second: float = 0


func _ready() -> void:
	effect_text.visible = false
	y_per_second = y_movement / duration
	opacity_per_second = 1 / duration

func _process(delta: float) -> void:
	if not effect_text.visible:
		return

	effect_text.position = Vector2(effect_text.position.x, effect_text.position.y - y_per_second * delta)    
	effect_text.self_modulate.a -= opacity_per_second * delta
	time += delta

	if time > duration:
		queue_free()


func set_text(text: String) -> void:
	effect_text.text = text
	effect_text.visible = true
