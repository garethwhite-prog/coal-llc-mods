extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var miner = chain.reference_object
	if not is_instance_valid(miner): return

	var factory = load("res://mods-unpacked/gareth-drone_workforce_mod/scripts/drone_texture_factory.gd")
	if not factory: return

	for part in ["Head", "Torso", "Legs", "Tool"]:
		var node = miner.find_child(part, true, false)
		if is_instance_valid(node) and node is CanvasItem:
			node.visible = false

	var drone_spr = miner.get_node_or_null("MinerDroneSprite")
	if not drone_spr:
		drone_spr = Sprite2D.new()
		drone_spr.name = "MinerDroneSprite"
		drone_spr.texture = factory.create_miner_drone_texture()
		drone_spr.scale = Vector2(1.5, 1.5)
		miner.call_deferred("add_child", drone_spr)
