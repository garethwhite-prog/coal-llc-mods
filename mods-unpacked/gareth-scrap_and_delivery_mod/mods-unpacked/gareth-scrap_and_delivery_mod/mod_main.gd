extends Node

const MOD_DIR := "gareth-scrap_and_delivery_mod"

func _init() -> void:
	var unpacked_dir = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	var ext_dir = unpacked_dir.path_join("extensions")

	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/InventoryWindow.gd",
		ext_dir.path_join("scenes/Interfaces/InventoryWindow.hooks.gd")
	)

func _ready() -> void:
	var mgr_script = load("res://mods-unpacked/gareth-scrap_and_delivery_mod/scripts/amazon_delivery_manager.gd")
	var mgr = Node.new()
	mgr.name = "AmazonDeliveryManager"
	mgr.set_script(mgr_script)
	get_tree().root.call_deferred("add_child", mgr)
	ModLoaderLog.info("Daytime Scrap & Amazon Delivery Mod active! (Hotkey B for Amazon, 50% Scrap enabled)", MOD_DIR)
