extends Node

const MOD_DIR := "gareth-buyable_vacuums_mod"

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

	# Unlock vanilla Vacuums 1 to 4 in shop
	for i in range(1, 5):
		var v = load("res://resources/Items/BonusEffects/bonus_equipment/vacuum_cleaner_%d.tres" % i)
		if v:
			v.itemUnlocked = true
			if not v in item_unlocks.all_bonus_items:
				item_unlocks.all_bonus_items.append(v)
			if not v in item_unlocks.all_items:
				item_unlocks.all_items.append(v)

	# Insert Vacuums 5 to 8 immediately after Vacuum 4
	var target_idx = -1
	for i in range(item_unlocks.all_bonus_items.size()):
		if item_unlocks.all_bonus_items[i] and item_unlocks.all_bonus_items[i].itemID == "vacuum_cleaner_4":
			target_idx = i
			break

	var ext_items: Array[Item] = []
	for lvl in range(5, 9):
		var item = load("res://mods-unpacked/gareth-buyable_vacuums_mod/items/vacuum_cleaner_%d.tres" % lvl)
		if item:
			ext_items.append(item)
			if not item in item_unlocks.all_items:
				item_unlocks.all_items.append(item)

	if target_idx != -1:
		for offset in range(ext_items.size()):
			item_unlocks.all_bonus_items.insert(target_idx + 1 + offset, ext_items[offset])
	else:
		for item in ext_items:
			item_unlocks.all_bonus_items.append(item)