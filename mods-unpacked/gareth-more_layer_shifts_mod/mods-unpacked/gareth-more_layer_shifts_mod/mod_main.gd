extends Node

const MOD_DIR := "gareth-more_layer_shifts_mod"

func _init() -> void:
	var mod_dir_path: String = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	ModLoaderMod.install_script_hooks(
		"res://scenes/tilemaps/tile_map_chunk.gd",
		mod_dir_path.path_join("extensions/scenes/tilemaps/tile_map_chunk.hooks.gd")
	)

func _ready() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if item_unlocks:
		for lvl in range(6, 13):
			var path = "res://mods-unpacked/gareth-more_layer_shifts_mod/items/shift_layers_%d.tres" % lvl
			if ResourceLoader.exists(path):
				var item = load(path)
				if item:
					if not item in item_unlocks.all_bonus_items:
						item_unlocks.all_bonus_items.append(item)
					if not item in item_unlocks.all_items:
						item_unlocks.all_items.append(item)
	ModLoaderLog.info("More Layer Shifts 6-12 active with extended stratum progression.", MOD_DIR)