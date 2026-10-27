extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var menu = chain.reference_object
	if not is_instance_valid(menu):
		return

	# Adjust original title rect to display our custom pixel branded logo
	var title_node = menu.find_child("Title", true, false)
	if is_instance_valid(title_node):
		var b_logo = load("res://mods-unpacked/gareth-mod_manager_mod/assets/branded_logo.png")
		if b_logo:
			title_node.texture = b_logo
			# Seamless center and custom size
			title_node.custom_minimum_size = Vector2(810, 310)
			title_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			# Strip overlapping subtitle overlays since its beautifully rendered on image_26.png
			var m_sub = menu.find_child("SubtitleLabel", true, false)
			if is_instance_valid(m_sub):
				m_sub.queue_free()
