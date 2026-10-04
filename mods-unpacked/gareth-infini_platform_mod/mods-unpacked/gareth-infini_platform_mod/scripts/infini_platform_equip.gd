class_name InfiniPlatformEquipEffect
extends EquipEffect

const ITEM_PLACER = preload("res://scenes/ItemPlacer.tscn")
var spawned_instance: ItemPlacer = null

func start(_player, item):
	spawned_instance = ITEM_PLACER.instantiate()
	spawned_instance.itemSprite = item.itemTexture
	Game.current_node.add_child(spawned_instance)

func end(_player):
	if spawned_instance != null and is_instance_valid(spawned_instance):
		spawned_instance.queue_free()
		spawned_instance = null

func physics_process(player, _delta):
	if spawned_instance == null or not is_instance_valid(spawned_instance):
		return
	spawned_instance.global_position = player.snap_pos_to_tile(player.pointer_global_pos)

	if Input.is_action_just_released("useItem"):
		var is_colliding = player.tilemap.is_tile_collision_pos(player.global_position)
		if not is_colliding:
			var spawner_script = load("res://mods-unpacked/gareth-infini_platform_mod/scripts/infini_platform_spawner.gd")
			var spawner = Node2D.new()
			spawner.set_script(spawner_script)
			spawner.tilemap = player.tilemap
			spawner.global_position = spawned_instance.global_position
			player.tilemap.add_child(spawner)

			var inventory: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
			inventory.sellFromInventory(player.item_equipped, 1)
			Bus.inventory_changed.emit()