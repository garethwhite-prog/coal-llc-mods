extends Control

var container: GridContainer

func _ready() -> void:
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(vbox)

	var header = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(header)
	
	var search = LineEdit.new()
	search.placeholder_text = "Search active mods..."
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.text_changed.connect(Callable(self, "_on_search_filter"))
	header.add_child(search)

	var close_btn = Button.new()
	close_btn.text = "Save & Close"
	close_btn.custom_minimum_size = Vector2(120, 40)
	close_btn.pressed.connect(Callable(self, "_on_close_pressed"))
	header.add_child(close_btn)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	container = GridContainer.new()
	container.columns = 3
	container.add_theme_constant_override("h_separation", 20)
	container.add_theme_constant_override("v_separation", 20)
	scroll.add_child(container)
	
	_render_cards()

func _render_cards() -> void:
	if not container: return
	for c in container.get_children(): c.queue_free()
	
	for mod_id in ModLoader.mod_data:
		var manifest = ModLoader.mod_data[mod_id].manifest
		var card = PanelContainer.new()
		card.name = mod_id
		card.custom_minimum_size = Vector2(280, 150)
		var vb = VBoxContainer.new()
		card.add_child(vb)
		
		var title = Label.new()
		title.text = manifest.name
		vb.add_child(title)
		
		var auth = Label.new()
		auth.text = _get_mod_category(manifest)
		vb.add_child(auth)
		
		container.add_child(card)

func _get_mod_category(manifest: Dictionary) -> String:
	if manifest and manifest.has("extra") and typeof(manifest["extra"]) == TYPE_DICTIONARY:
		if manifest["extra"].has("godot") and typeof(manifest["extra"]["godot"]) == TYPE_DICTIONARY:
			if manifest["extra"]["godot"].has("authors") and typeof(manifest["extra"]["godot"]["authors"]) == TYPE_ARRAY:
				var authors = manifest["extra"]["godot"]["authors"]
				if authors.size() > 0 and typeof(authors[0]) == TYPE_STRING and "Gareth White" in authors[0]:
					return "Gareth White (Official Suite)"
	return "Community Add-Ons"

func _on_search_filter(query: String) -> void:
	var q = query.to_lower()
	if is_instance_valid(container):
		for card in container.get_children():
			if q.is_empty():
				card.visible = true
			else:
				card.visible = q in card.name.to_lower()

func _on_close_pressed() -> void:
	queue_free()
