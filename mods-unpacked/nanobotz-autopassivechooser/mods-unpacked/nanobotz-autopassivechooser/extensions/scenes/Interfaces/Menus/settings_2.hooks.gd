extends Object

const LOG_NAME := "nanobotz-autopassivechooser:SettingsHook"

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next()

	var settings := chain.reference_object as SettingsMenu
	var tab_node := preload("res://mods-unpacked/nanobotz-autopassivechooser/scenes/passive_order.tscn").instantiate()

	settings.tab_container.add_child(tab_node)
	ModLoaderLog.info("Passive Order tab added to settings menu.", LOG_NAME)
