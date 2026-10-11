extends Node

const MOD_DIR := "gareth-multisave_mod"

func _init() -> void:
	var mod_dir_path: String = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	ModLoaderMod.install_script_hooks(
		"res://scripts/MainMenu.gd",
		mod_dir_path.path_join("extensions/scripts/MainMenu.hooks.gd")
	)

func _ready() -> void:
	var ssm_script = load("res://mods-unpacked/gareth-multisave_mod/scripts/save_slot_manager.gd")
	var ssm = Node.new()
	ssm.name = "SaveSlotManager"
	ssm.set_script(ssm_script)
	get_tree().root.call_deferred("add_child", ssm)
	ModLoaderLog.info("Multi-Save Slot Manager v2.2 active without Gvars hooks.", MOD_DIR)