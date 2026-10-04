extends Node

const MOD_DIR := "gareth-more_vacuum_quests_mod"

func _init() -> void:
	var mod_dir_path: String = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	ModLoaderMod.install_script_hooks(
		"res://scripts/equipment_manager.gd",
		mod_dir_path.path_join("extensions/scripts/equipment_manager.hooks.gd")
	)

func _ready() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks:
		return
	for lvl in range(5, 9):
		var path = "res://mods-unpacked/gareth-more_vacuum_quests_mod/items/vacuum_cleaner_%d.tres" % lvl
		var item = load(path)
		if item:
			if not item in item_unlocks.all_bonus_items:
				item_unlocks.all_bonus_items.append(item)
			if not item in item_unlocks.all_items:
				item_unlocks.all_items.append(item)
	ModLoaderLog.info("Registered Vacuum Cleaner Levels 5-8 into bonus shop.", MOD_DIR)