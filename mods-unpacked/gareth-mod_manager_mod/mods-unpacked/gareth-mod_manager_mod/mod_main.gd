extends Node

func _init() -> void:
	ModLoaderMod.install_script_hooks(self)

func _ready() -> void:
	print("INFO gareth-mod_manager_mod: Universal Mod Manager active with full Class, Shop & Input gating.")
