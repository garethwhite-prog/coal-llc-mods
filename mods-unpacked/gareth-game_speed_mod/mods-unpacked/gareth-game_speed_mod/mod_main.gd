extends Node

const MOD_DIR := "gareth-game_speed_mod"

func _ready() -> void:
	var controller_script = load("res://mods-unpacked/gareth-game_speed_mod/scripts/speed_controller.gd")
	var controller = Node.new()
	controller.name = "GameSpeedController"
	controller.set_script(controller_script)
	get_tree().root.call_deferred("add_child", controller)
	ModLoaderLog.info("Game Speed & Shift Finisher mod active!", MOD_DIR)
