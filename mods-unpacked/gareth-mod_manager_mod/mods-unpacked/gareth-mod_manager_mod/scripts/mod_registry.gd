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

static func get_all_installed_mods() -> Array[Dictionary]:
	return get_all_mods()

static func get_all_mods() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var mod_dict: Dictionary = {}

	var mls = Engine.get_main_loop().root.get_node_or_null("/root/ModLoaderStore")
	if mls and ("mod_data" in mls) and mls.mod_data is Dictionary and mls.mod_data.size() > 0:
		mod_dict = mls.mod_data
	elif ModLoader and ("mod_data" in ModLoader) and ModLoader.mod_data is Dictionary and ModLoader.mod_data.size() > 0:
		mod_dict = ModLoader.mod_data

	if mod_dict.size() > 0:
		for mod_id in mod_dict.keys():
			var data = mod_dict[mod_id]
			if not data or not ("manifest" in data) or not data.manifest:
				continue
			list.append(_dict_from_manifest(mod_id, data.manifest, data.is_active if "is_active" in data else true))
		return list

	var dir := DirAccess.open("res://mods-unpacked")
	if dir:
		dir.list_dir_begin()
		var folder := dir.get_next()
		while folder != "":
			if dir.current_is_dir() and not folder.begins_with("."):
				var mpath := "res://mods-unpacked/%s/manifest.json" % folder
				if FileAccess.file_exists(mpath):
					var f := FileAccess.open(mpath, FileAccess.READ)
					if f:
						var parsed = JSON.parse_string(f.get_as_text())
						if parsed is Dictionary:
							list.append(_dict_from_manifest(folder, parsed, true))
			folder = dir.get_next()

	return list

static func _dict_from_manifest(mod_id: String, m, active: bool) -> Dictionary:
	var display_name: String = _format_display_name(m)
	var desc: String = str(m.description) if "description" in m else ""
	var author: String = "Community"
	if "extra" in m and m.extra:
		if ("godot" in m.extra) and ("authors" in m.extra.godot) and m.extra.godot.authors.size() > 0:
			author = str(m.extra.godot.authors[0])
	var version: String = str(m.version_number) if "version_number" in m else "1.0.0"
	var cat: String = _determine_category(m)

	return {
		"id": mod_id,
		"key": mod_id,
		"name": display_name,
		"description": desc,
		"author": author,
		"version": version,
		"category": cat,
		"is_active": active
	}

static func _determine_category(m) -> String:
	var id: String = str(m.name).to_lower() if "name" in m else ""
	if "class" in id or "profession" in id or "jedi" in id or "knight" in id or "sinclairity" in id:
		return "Classes & Professions"
	if "map" in id or "trench" in id or "faultline" in id or "canvas" in id or "expedition" in id:
		return "Custom Maps & Strata"
	if "weapon" in id or "bomb" in id or "laser" in id or "nuke" in id or "turret" in id or "mortar" in id or "grenade" in id or "arsenal" in id or "tank" in id or "strike" in id:
		return "Weapons & Arsenal"
	if "employee" in id or "collector" in id or "drill" in id or "vacuum" in id:
		return "Employees & Automation"
	if "speed" in id or "inventory" in id or "save" in id or "leaderboard" in id or "multisave" in id or "settings" in id or "scrap" in id or "delivery" in id or "ladder" in id:
		return "Quality of Life"
	if "hardware" in id or "limit" in id or "performance" in id or "booster" in id or "holes" in id:
		return "Performance & System"
	if "spirit" in id or "variance" in id or "upgrade" in id or "passive" in id or "order" in id or "beacon" in id:
		return "Progression & Upgrades"
	return "Community Add-Ons"

static func _format_display_name(m) -> String:
	if "extra" in m and m.extra and ("godot" in m.extra) and ("display_name" in m.extra.godot):
		return str(m.extra.godot.display_name)
	var raw: String = str(m.name).replace("_mod", "").replace("mod_", "").replace("-", " ").replace("_", " ") if "name" in m else "Mod"
	return raw.capitalize()
