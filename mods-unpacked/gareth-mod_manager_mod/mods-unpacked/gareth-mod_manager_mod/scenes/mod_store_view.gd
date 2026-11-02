extends Control

@onready var container: GridContainer = %ModStoreContainer
@onready var status_lbl: Label = %StatusLabel
var all_packages: Array = []

func _ready() -> void:
	if status_lbl: status_lbl.text = "Loading Mod & Map Catalog..."
	var client_script = load("res://mods-unpacked/gareth-mod_manager_mod/scripts/mod_store_client.gd")
	if client_script:
		var c = client_script.new()
		add_child(c)
		c.repo_fetch_completed.connect(Callable(self, "_on_catalog_loaded"))
		c.fetch_all_available_mods()

func _on_catalog_loaded(repo: String, releases: Array) -> void:
	all_packages.clear()
	for r in releases:
		if typeof(r) != TYPE_DICTIONARY: continue
		var p_name = str(r.get("name", "Unknown Mod"))
		var p_id = str(r.get("id", ""))
		var tag = str(r.get("version", "1.0.0"))
		if not tag.begins_with("v"): tag = "v" + tag
		
		var assets = r.get("assets", [])
		if typeof(assets) == TYPE_ARRAY and assets.size() > 0:
			var asset_map = assets[0]
			if typeof(asset_map) == TYPE_DICTIONARY:
				if p_id == "": p_id = str(asset_map.get("name", "")).replace(".zip", "")
				tag = str(r.get("tag_name", "v1.0"))
				
		if p_id == "": continue

		all_packages.append({
			"id": p_id,
			"name": p_name,
			"tag": tag,
			"desc": str(r.get("description", r.get("body", "No description available."))),
			"cat": "Official Suite",
			"author": str(r.get("author", "Gareth White"))
		})
	if status_lbl:
		status_lbl.text = "Gareth White (Official Suite): %d active packages loaded from catalog." % all_packages.size()
		status_lbl.modulate = Color(0.4, 0.85, 1.0)
	_render_cards()

func _render_cards() -> void:
	if not container: return
	for c in container.get_children():
		c.queue_free()
	
	for pkg in all_packages:
		var pkg_id = str(pkg["id"])
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(280, 200)
		var vb = VBoxContainer.new()
		card.add_child(vb)
		
		var title = Label.new()
		title.text = str(pkg["name"])
		title.autowrap_mode = TextServer.AUTOWRAP_WORD
		vb.add_child(title)
		
		var author = Label.new()
		author.text = str(pkg["author"]) + " | " + str(pkg["tag"])
		author.modulate = Color(0.7, 0.7, 0.7)
		vb.add_child(author)
		
		var spacer = Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vb.add_child(spacer)
		
		var btn_action = Button.new()
		btn_action.custom_minimum_size = Vector2(0, 40)
		var installed = _is_installed(pkg_id)
		if installed:
			btn_action.text = "Uninstall"
			btn_action.modulate = Color(0.9, 0.4, 0.4)
			btn_action.pressed.connect(Callable(self, "_on_uninstall_pressed").bind(pkg_id, btn_action))
		else:
			btn_action.text = "Install"
			btn_action.modulate = Color(0.4, 0.9, 0.4)
			btn_action.pressed.connect(Callable(self, "_on_install_pressed").bind(pkg_id, btn_action))
		vb.add_child(btn_action)
		
		container.add_child(card)

func _is_installed(mod_id: String) -> bool:
	var expected_path = OS.get_executable_path().get_base_dir().path_join("mods").path_join(mod_id + ".zip")
	return FileAccess.file_exists(expected_path)

func _on_install_pressed(mod_id: String, btn: Button) -> void:
	btn.text = "Installing..."
	btn.disabled = true
	if status_lbl: status_lbl.text = "Installing %s..." % mod_id
	var c = find_child("ModStoreClient", true, false)
	if c: c.download_mod(mod_id)

func _on_uninstall_pressed(mod_id: String, btn: Button) -> void:
	_uninstall_mod(mod_id)
	btn.text = "Restart Required"
	btn.disabled = true

func _uninstall_mod(mod_id: String) -> void:
	var path = OS.get_executable_path().get_base_dir().path_join("mods").path_join(mod_id + ".zip")
	var file = FileAccess.open(path + ".pending_delete", FileAccess.WRITE)
	if file:
		file.store_string("DELETE_ON_BOOT")
		file.close()
	if status_lbl: status_lbl.text = "🗑️ Uninstalled %s.zip. Deleted from active mods directory." % mod_id

func _on_close_pressed() -> void:
	queue_free()
