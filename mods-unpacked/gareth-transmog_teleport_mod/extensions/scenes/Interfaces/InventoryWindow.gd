extends "res://scenes/Interfaces/InventoryWindow.gd"

func _ready() -> void:
	super()
	call_deferred("_inject_transmog_button")

func _inject_transmog_button() -> void:
	var btn = Button.new()
	btn.name = "TransmogTeleportBtn"
	btn.text = "Transmog Depot (50% Loss)"
	btn.modulate = Color(0.9, 0.3, 0.9)
	btn.custom_minimum_size = Vector2(220, 40)
	btn.pressed.connect(_on_transmog_teleport)
	
	add_child(btn)
	btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	btn.position = Vector2(size.x - btn.custom_minimum_size.x - 20, size.y - btn.custom_minimum_size.y - 20)

func _on_transmog_teleport() -> void:
	if Gvars != null and "inventory" in Gvars and typeof(Gvars.inventory) == TYPE_DICTIONARY:
		for key in Gvars.inventory.keys():
			if typeof(Gvars.inventory[key]) == TYPE_INT or typeof(Gvars.inventory[key]) == TYPE_FLOAT:
				Gvars.inventory[key] = int(Gvars.inventory[key] / 2.0)
				
	var stockpile = get_tree().get_first_node_in_group("Stockpile")
	if not stockpile:
		var root = get_tree().current_scene
		if root: stockpile = root.find_child("Stockpile", true, false)
		
	if stockpile and stockpile.has_method("drop_off_coal"):
		stockpile.drop_off_coal()
		
	if has_method("load_inventory"):
		load_inventory()
