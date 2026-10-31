extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var ufo = chain.reference_object
	if not is_instance_valid(ufo): return

	var factory = load("res://mods-unpacked/gareth-drone_workforce_mod/scripts/drone_texture_factory.gd")
	if not factory: return

	var models = ufo.find_child("Models", true, false)
	if is_instance_valid(models) and models is CanvasItem:
		models.visible = false

	var cargo_spr = ufo.get_node_or_null("CargoDroneSprite")
	if not cargo_spr:
		cargo_spr = Sprite2D.new()
		cargo_spr.name = "CargoDroneSprite"
		cargo_spr.texture = factory.create_cargo_drone_texture()
		cargo_spr.scale = Vector2(1.5, 1.5)
		ufo.call_deferred("add_child", cargo_spr)
