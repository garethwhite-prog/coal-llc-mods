extends Node

func _init() -> void:
	ModLoaderMod.install_script_hooks(self)

func _ready() -> void:
	var threads: int = OS.get_processor_count()
	print("INFO gareth-hardware_booster_mod: Hardware Multi-Thread Booster active! Detected %d logical CPU threads." % threads)
