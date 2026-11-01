extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	await chain.execute_next([])
	var miner = chain.reference_object
	if not is_instance_valid(miner): return

	var factory = load("res://mods-unpacked/gareth-drone_workforce_mod/scripts/drone_texture_factory.gd")
	if not factory: return

	# Utterly destroy the vanilla graphics node so AnimationPlayer cannot force visibility back on
	var sprites_node = miner.get_node_or_null("Sprites")
	if is_instance_valid(sprites_node):
		sprites_node.call_deferred("queue_free")

	var drone_spr = miner.get_node_or_null("MinerDroneSprite")
	if not drone_spr:
		drone_spr = Sprite2D.new()
		drone_spr.name = "MinerDroneSprite"
		drone_spr.texture = factory.create_miner_drone_texture()
		drone_spr.scale = Vector2(1.5, 1.5)
		miner.call_deferred("add_child", drone_spr)

