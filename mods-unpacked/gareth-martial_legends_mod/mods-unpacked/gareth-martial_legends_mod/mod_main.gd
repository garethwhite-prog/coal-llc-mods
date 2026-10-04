extends Node

const MOD_DIR := "gareth-martial_legends_mod"

func _init() -> void:
	var mod_dir_path: String = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	ModLoaderMod.install_script_hooks(
		"res://scenes/equipment/boxing_gloves.gd",
		mod_dir_path.path_join("extensions/scenes/equipment/boxing_gloves.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/equipment/kick.gd",
		mod_dir_path.path_join("extensions/scenes/equipment/kick.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://resources/professions/scripts/martial_artist.gd",
		mod_dir_path.path_join("extensions/resources/professions/scripts/martial_artist.hooks.gd")
	)

func _ready() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks:
		return
	var dir_path := "res://mods-unpacked/gareth-martial_legends_mod/items"
	var dir := DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var item = load(dir_path.path_join(file_name))
				if item:
					if not item in item_unlocks.all_equipment_items:
						item_unlocks.all_equipment_items.append(item)
					if not item in item_unlocks.all_items:
						item_unlocks.all_items.append(item)
			file_name = dir.get_next()
	ModLoaderLog.info("Martial Artist Legends expansion loaded cleanly.", MOD_DIR)