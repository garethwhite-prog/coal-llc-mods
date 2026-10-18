extends Node

const MOD_ID := "nanobotz-autopassivechooser"
const MOD_DIR := "nanobotz-autopassivechooser"
const LOG_NAME := "nanobotz-autopassivechooser:Main"

var mod_dir_path: String
var extensions_dir_path: String

var reroll_if_no_matches: bool = true
var passive_order: Array = []


func _init() -> void:
	mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	extensions_dir_path = mod_dir_path.path_join("extensions")
	install_hooks()


func _ready() -> void:
	ModLoaderLog.info("Ready!", LOG_NAME)


static func get_current_profession_or_default() -> String:
	if Game.player and Game.player.profession and Game.player.profession.profession_name:
		var player: Player = Game.player
		return player.profession.profession_name.to_lower()
	else:
		return Gvars.get("profession_manager").INTERNSHIP.profession_name.to_lower()


static func get_or_create_config(player_profession: String = "") -> ModConfig:
	if not player_profession:
		player_profession = get_current_profession_or_default()

	if ModLoaderConfig.has_config(MOD_ID, player_profession):
		return ModLoaderConfig.get_config(MOD_ID, player_profession)
	else:
		return ModLoaderConfig.create_config(MOD_ID, player_profession, ModLoaderConfig.get_default_config(MOD_ID).data)


func install_hooks() -> void:
	var hook_files = [
		["res://scenes/Interfaces/Menus/settings_2.gd", "scenes/Interfaces/Menus/settings_2.hooks.gd"],
		["res://scenes/Interfaces/in_game/choose_passive.gd", "scenes/Interfaces/in_game/choose_passive.hooks.gd"],
		["res://scenes/tilemaps/tile_map_chunk.gd", "scenes/tilemaps/tile_map_chunk.hooks.gd"],
		["res://scripts/StateMachine/Player2/player_2.gd", "scripts/StateMachine/Player2/player_2.hooks.gd"],
		["res://scripts/Chest.gd", "scripts/Chest.hooks.gd"]
	]

	for item in hook_files:
		var target = item[0]
		var hook_path = extensions_dir_path.path_join(item[1])
		var script_res = load(hook_path)
		if script_res == null:
			ModLoaderLog.error("FAILED to load script resource: %s" % hook_path, LOG_NAME)
		elif not (script_res is GDScript):
			ModLoaderLog.error("Loaded resource is NOT GDScript: %s (type: %s)" % [hook_path, script_res.get_class()], LOG_NAME)
		else:
			var method_names = []
			for m in script_res.get_script_method_list():
				method_names.append(m.name)
			ModLoaderLog.info("Loaded hook script %s with methods: %s" % [item[1], str(method_names)], LOG_NAME)

		ModLoaderMod.install_script_hooks(target, hook_path)