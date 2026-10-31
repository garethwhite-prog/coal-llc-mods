extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var ls = chain.reference_object
	if ls and ("LEVEL_ORDER" in ls):
		if not ls.LEVEL_ORDER.has(103):
			ls.LEVEL_ORDER.append(103)
	
	chain.execute_next([])
	
	if is_instance_valid(ls):
		var levels_grid = ls.get_node_or_null("%Levels")
		if levels_grid:
			for card in levels_grid.get_children():
				var is_map_103 := false
				if ("game_level" in card) and card.game_level and ("level" in card.game_level) and card.game_level.level == 103:
					is_map_103 = true
				elif ("level" in card) and card.level and ("level_id" in card.level) and card.level.level_id == 103:
					is_map_103 = true
				else:
					for lbl in card.find_children("*", "Label", true, false):
						if "Living Canvas" in lbl.text:
							is_map_103 = true
							break
							
				if is_map_103:
					var container = card.get_node_or_null("MarginContainer/VBoxContainer")
					if container and not container.has_node("CanvasImagePickerBtn"):
						var btn = Button.new()
						btn.name = "CanvasImagePickerBtn"
						btn.text = "Browse Custom Canvas..."
						btn.custom_minimum_size = Vector2(0, 26)
						btn.modulate = Color(0.4, 0.9, 1.0)
						var helper = load("res://mods-unpacked/gareth-living_canvas_mod/helpers/LivingCanvasHelper.gd")
						if helper:
							btn.pressed.connect(Callable(helper.new(), "_on_browse_pressed"))
						container.call_deferred("add_child", btn)
