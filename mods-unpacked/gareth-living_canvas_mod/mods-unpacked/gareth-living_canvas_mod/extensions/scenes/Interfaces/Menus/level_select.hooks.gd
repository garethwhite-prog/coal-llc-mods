extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var ls = chain.reference_object
	if ls and ("LEVEL_ORDER" in ls):
		if not ls.LEVEL_ORDER.has(103):
			ls.LEVEL_ORDER.append(103)
	
	await chain.execute_next([])
	
	if is_instance_valid(ls):
		var levels_grid = ls.get_node_or_null("%Levels")
		if levels_grid:
			for card in levels_grid.get_children():
				if "game_level" in card and card.game_level and card.game_level.level == 103:
					var container = card.get_node_or_null("MarginContainer/VBoxContainer")
					if container and not container.has_node("CanvasImagePickerBtn"):
						var btn = Button.new()
						btn.name = "CanvasImagePickerBtn"
						btn.text = "Browse Custom Canvas..."
						var helper = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/canvas_helper.gd")
						if helper:
							btn.pressed.connect(Callable(helper.new(), "_on_browse_pressed"))
						container.add_child(btn)
