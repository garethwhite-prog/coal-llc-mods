extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var settings = chain.reference_object
	if not settings or not ("tab_container" in settings) or not settings.tab_container:
		return

	var existing = settings.tab_container.get_node_or_null("LeaderboardTab")
	if existing:
		return

	var tab_script = load("res://mods-unpacked/gareth-leaderboard_mod/scenes/leaderboard_tab.gd")
	var tab := PanelContainer.new()
	tab.set_script(tab_script)
	tab.name = "LeaderboardTab"
	tab.set_name("Leaderboard")
	settings.tab_container.add_child(tab)
	# Position 7 places it directly adjacent to Mod Manager
	settings.tab_container.call_deferred("move_child", tab, 7)