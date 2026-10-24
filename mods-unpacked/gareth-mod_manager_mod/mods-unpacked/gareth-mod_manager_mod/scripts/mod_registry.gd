class_name ModRegistry
extends RefCounted

static func is_mod_active_for_run(mod_key: String) -> bool:
	var ssm = Engine.get_main_loop().root.get_node_or_null("/root/SaveSlotManager")
	if ssm and ssm.has_method("is_mod_active_for_run"):
		return ssm.is_mod_active_for_run(mod_key)

	var cfg_path := "user://gareth_mods_config.json"
	if FileAccess.file_exists(cfg_path):
		var f := FileAccess.open(cfg_path, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary and parsed.has("mods"):
				return bool(parsed["mods"].get(mod_key, true))
	return true

static func get_all_installed_mods() -> Array:
	return get_all_mods()

static func get_all_mods() -> Array:
	var list: Array = []
	var mod_data = ModLoader.get_mod_data_all()
	for mod_id in mod_data.keys():
		var data = mod_data[mod_id]
		if not data or not ("manifest" in data) or not data.manifest:
			continue
		var m = data.manifest
		var display_name: String = _format_display_name(m)
		var desc: String = m.description if "description" in m else ""
		var author: String = m.extra.godot.authors[0] if (m.has("extra") and m.extra.has("godot") and m.extra.godot.has("authors") and m.extra.godot.authors.size() > 0) else "Community"
		var version: String = m.version_number if "version_number" in m else "1.0.0"
		var cat: String = _determine_category(m)

		list.append({
			"id": mod_id,
			"key": mod_id,
			"name": display_name,
			"description": desc,
			"author": author,
			"version": version,
			"category": cat,
			"is_active": data.is_active
		})
	return list

static func _determine_category(m) -> String:
	var id: String = str(m.name).to_lower()
	var desc: String = str(m.description).to_lower()
	if "class" in id or "profession" in id or "jedi" in id or "knight" in id or "sinclairity" in id:
		return "Classes & Professions"
	if "map" in id or "trench" in id or "faultline" in id or "canvas" in id or "expedition" in id:
		return "Custom Maps & Strata"
	if "weapon" in id or "bomb" in id or "laser" in id or "nuke" in id or "turret" in id or "mortar" in id or "grenade" in id or "arsenal" in id or "tank" in id or "strike" in id:
		return "Weapons & Arsenal"
	if "employee" in id or "collector" in id or "drill" in id or "vacuum" in id:
		return "Employees & Automation"
	if "speed" in id or "inventory" in id or "save" in id or "leaderboard" in id or "multisave" in id or "settings" in id or "scrap" in id or "delivery" in id:
		return "Quality of Life"
	if "hardware" in id or "limit" in id or "performance" in id or "booster" in id or "holes" in id:
		return "Performance & System"
	if "spirit" in id or "variance" in id or "upgrade" in id or "passive" in id or "order" in id or "beacon" in id:
		return "Progression & Upgrades"
	return "Community Add-Ons"

static func _format_display_name(m) -> String:
	if m.has("extra") and m.extra.has("godot") and m.extra.godot.has("display_name"):
		return m.extra.godot.display_name
	var raw: String = m.name.replace("_mod", "").replace("mod_", "").replace("-", " ").replace("_", " ")
	return raw.capitalize()
