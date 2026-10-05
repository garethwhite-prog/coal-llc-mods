extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var settings := chain.reference_object as SettingsMenu
	if not settings or not settings.tab_container:
		return

	var tab_script = load("res://mods-unpacked/gareth-leaderboard_mod/scenes/leaderboard_tab.gd")
	var tab := PanelContainer.new()
	tab.set_script(tab_script)
	tab.name = "Leaderboard"
	settings.tab_container.add_child(tab)
	ModLoaderLog.info("Leaderboard tab injected into Settings menu.", "gareth-leaderboard_mod")