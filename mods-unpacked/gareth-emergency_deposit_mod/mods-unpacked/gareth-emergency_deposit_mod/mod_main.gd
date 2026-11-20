extends Node

const MOD_DIR := "gareth-emergency_deposit_mod"

func _ready() -> void:
	var ctrl_script := load("res://mods-unpacked/gareth-emergency_deposit_mod/scripts/emergency_deposit_controller.gd")
	if ctrl_script and (ctrl_script is GDScript):
		var ctrl := Node.new()
		ctrl.name = "EmergencyDepositController"
		ctrl.set_script(ctrl_script)
		add_child(ctrl)
	ModLoaderLog.info("Emergency Deposit Mod initialized.", MOD_DIR)
