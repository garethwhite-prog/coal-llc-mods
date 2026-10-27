extends Object

var baby_sun: Node2D = null

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var tm = chain.reference_object
	if not is_instance_valid(tm) or is_instance_valid(baby_sun):
		return

	var factory = load("res://mods-unpacked/gareth-teletubbies_mod/scripts/teletubbies_texture_factory.gd")
	if not factory:
		return

	baby_sun = Node2D.new()
	baby_sun.name = "TeletubbiesBabySun"
	baby_sun.position = Vector2(480, -180)
	baby_sun.z_index = -5

	var spr = Sprite2D.new()
	spr.name = "SunSprite"
	spr.texture = factory.create_baby_sun_texture(false)
	spr.scale = Vector2(2.4, 2.4)
	baby_sun.add_child(spr)

	tm.add_child(baby_sun)

	# Gentle sky bobbing
	var tw = baby_sun.create_tween().set_loops()
	tw.tween_property(spr, "rotation", 0.15, 3.0)
	tw.tween_property(spr, "rotation", -0.15, 3.0)
