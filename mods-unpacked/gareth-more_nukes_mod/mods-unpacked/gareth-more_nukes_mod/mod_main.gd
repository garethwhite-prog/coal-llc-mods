extends Node

const MOD_DIR := "gareth-more_nukes_mod"

func _ready() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks:
		return
	var dir_path := "res://mods-unpacked/gareth-more_nukes_mod/items"
	var dir := DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var item = load(dir_path.path_join(file_name))
				if item and not item in item_unlocks.all_equipment_items:
					item_unlocks.all_equipment_items.append(item)
			file_name = dir.get_next()
	ModLoaderLog.info("15 Tactical Nukes registered into equipment shop.", MOD_DIR)