extends Node

const MOD_DIR := "gareth-leaderboard_mod"

func _init() -> void:
	var mod_dir_path: String = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/Menus/settings_2.gd",
		mod_dir_path.path_join("extensions/scenes/Interfaces/Menus/settings_2.hooks.gd")
	)

func _ready() -> void:
	var tracker_script = load("res://mods-unpacked/gareth-leaderboard_mod/scripts/record_tracker.gd")
	var tracker = Node.new()
	tracker.name = "LeaderboardTracker"
	tracker.set_script(tracker_script)
	get_tree().root.call_deferred("add_child", tracker)
	ModLoaderLog.info("Leaderboard v2 auto-tracker initialized.", MOD_DIR)