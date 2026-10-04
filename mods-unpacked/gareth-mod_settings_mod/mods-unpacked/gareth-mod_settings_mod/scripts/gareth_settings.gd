extends RefCounted

const CONFIG_PATH := "user://gareth_mods_config.json"

static var config: Dictionary = {
	"mods": {
		"tank_arsenal": true,
		"hydrogen_bomb": true,
		"neutron_bomb": true,
		"more_layer_shifts": true,
		"more_inventory_slots": true,
		"more_inventory_stacks": true,
		"buyable_vacuums": true,
		"more_mortars": true,
		"more_drills": true,
		"infini_platform": true,
		"more_employees": true,
		"more_collectors": true,
		"weapon_stacker": true,
		"elemental_transmutation": true,
		"excavation_frenzy": true,
		"plasma_raygun": true,
		"prospectors_beacon": true,
		"seismic_hazards": true
	},
	"sliders": {
		"hbomb_radius": 80.0,
		"nbomb_damage_mult": 1.0,
		"infini_platform_max": 200.0,
		"minigun_stack_scaling": 1.0
	}
}

static var _loaded: bool = false

static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(CONFIG_PATH):
		save_config()
		return
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file:
		var json_text := file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(json_text)
		if parsed is Dictionary:
			for cat in parsed.keys():
				if config.has(cat) and parsed[cat] is Dictionary:
					for k in parsed[cat].keys():
						config[cat][k] = parsed[cat][k]

static func save_config() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(config, "\t"))
		file.close()

static func is_mod_enabled(mod_name: String) -> bool:
	ensure_loaded()
	return bool(config["mods"].get(mod_name, true))

static func set_mod_enabled(mod_name: String, enabled: bool) -> void:
	ensure_loaded()
	config["mods"][mod_name] = enabled
	save_config()

static func get_slider(key: String, default_val: float) -> float:
	ensure_loaded()
	return float(config["sliders"].get(key, default_val))

static func set_slider(key: String, value: float) -> void:
	ensure_loaded()
	config["sliders"][key] = value
	save_config()