class_name ModRegistry
extends RefCounted

static func get_all_installed_mods() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var root = Engine.get_main_loop().root
	var store = root.get_node_or_null("ModLoaderStore")
	if not store or not ("mod_data" in store):
		return result

	for mod_id in store.mod_data.keys():
		var data = store.mod_data[mod_id]
		if not data or not ("manifest" in data) or not data.manifest:
			continue
		var m = data.manifest

		var clean_name: String = _format_display_name(m)
		var author: String = _format_author(m)
		var cat: String = _determine_category(m)

		result.append({
			"id": mod_id,
			"key": m.name.trim_suffix("_mod"),
			"name": clean_name,
			"author": author,
			"version": m.version_number,
			"description": m.description if m.description != "" else "Installed community mod package.",
			"category": cat,
			"is_core": (mod_id in ["gareth-mod_manager_mod", "gareth-multisave_mod"])
		})

	return result

static func _format_display_name(manifest) -> String:
	var name_str: String = manifest.name
	name_str = name_str.trim_suffix("_mod")
	var parts := name_str.split("_")
	var capitalized: Array[String] = []
	for p in parts:
		if p.length() > 0:
			capitalized.append(p.capitalize())
	return " ".join(capitalized)

static func _format_author(manifest) -> String:
	if manifest.authors.size() > 0 and manifest.authors[0] != "":
		return manifest.authors[0]
	if manifest.mod_namespace != "":
		return manifest.mod_namespace
	return "Community"

static func _determine_category(manifest) -> String:
	var n: String = manifest.name.to_lower()
	var tags: PackedStringArray = manifest.tags

	for t in tags:
		var low := t.to_lower()
		if low in ["hardcore", "mutator", "hazard"]:
			return "Hardcore Mutators"
		if low in ["weapon", "explosive", "combat", "gun"]:
			return "Weapons & Explosives"
		if low in ["automation", "workforce", "employee", "collector"]:
			return "Workforce & Automation"
		if low in ["progression", "inventory", "strata", "depth"]:
			return "Progression & Upgrades"
		if low in ["performance", "limits", "system"]:
			return "Performance & System"

	if n.contains("hazard") or n.contains("gas") or n.contains("liquefaction") or n.contains("debt"):
		return "Hardcore Mutators"
	if n.contains("bomb") or n.contains("grenade") or n.contains("tank") or n.contains("raygun") or n.contains("spirit") or n.contains("weapon") or n.contains("martial") or n.contains("multiplier"):
		return "Weapons & Explosives"
	if n.contains("employee") or n.contains("collector") or n.contains("drill") or n.contains("mortar") or n.contains("depot") or n.contains("vacuum"):
		return "Workforce & Automation"
	if n.contains("inventory") or n.contains("layer") or n.contains("platform") or n.contains("beacon") or n.contains("quest"):
		return "Progression & Upgrades"
	if n.contains("performance") or n.contains("limit") or n.contains("hole"):
		return "Performance & System"

	return "Community Add-ons"
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