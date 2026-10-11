extends Node

func _ready() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if item_unlocks:
		var item = load("res://mods-unpacked/gareth-laser_beam_mod/items/LaserBeamItem.tres")
		if item and not (item in item_unlocks.all_equipment_items):
			item_unlocks.all_equipment_items.append(item)
		if item and not (item in item_unlocks.all_items):
			item_unlocks.all_items.append(item)
	ModLoaderLog.info("High-Energy Laser Beam weapon online and added to equipment shop.", "gareth-laser_beam_mod")