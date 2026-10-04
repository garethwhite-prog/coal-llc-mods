extends Object

const LOG_NAME := "gareth-mod_settings_mod:Hook"

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var settings := chain.reference_object as SettingsMenu
	if not settings or not settings.tab_container:
		return

	var tab_script = load("res://mods-unpacked/gareth-mod_settings_mod/scenes/gareth_mods_tab.gd")
	var tab := PanelContainer.new()
	tab.set_script(tab_script)
	tab.name = "Gareth Mods"
	settings.tab_container.add_child(tab)
	ModLoaderLog.info("Gareth Mods configuration tab injected into Settings menu.", LOG_NAME)