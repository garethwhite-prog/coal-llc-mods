extends Node

const MOD_DIR := "gareth-emergency_deposit_mod"

var _spawned: bool = false

func _init() -> void:
    ModLoaderLog.info("Emergency Deposit Mod initialized.", MOD_DIR)

func _ready() -> void:
    if _spawned:
        return
    _spawned = true
    var ctrl_script := load("res://mods-unpacked/gareth-emergency_deposit_mod/scripts/emergency_deposit_controller.gd")
    if ctrl_script and (ctrl_script is GDScript):
        var ctrl := Node.new()
        ctrl.name = "EmergencyDepositController"
        ctrl.set_script(ctrl_script)
        add_child(ctrl)
        ModLoaderLog.info("EmergencyDepositController attached.", MOD_DIR)
    else:
        ModLoaderLog.warning("Failed to load emergency_deposit_controller.gd", MOD_DIR)
