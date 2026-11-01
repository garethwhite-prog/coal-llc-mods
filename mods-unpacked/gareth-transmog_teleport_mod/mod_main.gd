extends Node

func _init() -> void:
	ModLoaderLog.info("Transmog Teleport Mod initialized", "gareth-transmog_teleport_mod")

func _ready() -> void:
	ModLoaderMod.install_script_extension("res://mods-unpacked/gareth-transmog_teleport_mod/extensions/scenes/Interfaces/InventoryWindow.gd")
