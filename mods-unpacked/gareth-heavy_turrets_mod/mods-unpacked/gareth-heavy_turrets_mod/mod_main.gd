extends Node

func _ready() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if item_unlocks:
		var item = load("res://mods-unpacked/gareth-heavy_turrets_mod/items/HeavyTurretItem.tres")
		if item and not (item in item_unlocks.all_equipment_items):
			item_unlocks.all_equipment_items.append(item)
		if item and not (item in item_unlocks.all_items):
			item_unlocks.all_items.append(item)
	ModLoaderLog.info("Heavy Automated Turrets mod active and registered into equipment shop.", "gareth-heavy_turrets_mod")